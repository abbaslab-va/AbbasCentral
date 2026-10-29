from dataclasses import dataclass, field, fields
from enum import Enum
from pathlib import Path
from .util import find_closest_match
import numpy as np



@dataclass
class BehDat:
    info: BehDatInfo
    spikes: dict[BehDatSpikes]
    timestamps: dict
    bpod: BpodParser
    coordinates: np.ndarray


    def find_event(self, **kwargs):
        presets = PresetManager(**kwargs)
        offset = round(presets.offset * self.info.baud)
        
        if presets.bpod:
            print('BpodParser lol')

        possibleEvents = list(self.timestamps.keys())
        eventName = find_closest_match(presets.event, possibleEvents)
        try:
            ts = self.timestamps[eventName] + offset
        except:
            print(f"No timestamp pair found for event {eventName}")

        try:
            trialStart = self.timestamps['trial start']
        except:
            print("No trial start event found, trializing failed")
            return ts

        goodTrials = self.bpod.trial_intersection(preset=presets)
        eventTrial = np.digitize(ts, trialStart)
        trializedTimes = []
        trialArray = range(1, self.bpod.trial_count() + 1)
        for trial in trialArray:
            tsInTrial = eventTrial == trial
            eventTS = np.array(ts[tsInTrial])
            trializedTimes.append(eventTS)
        
        trializedTimes = np.array(trializedTimes, dtype=object)
        trializedTimes = trializedTimes[goodTrials]
        if not presets.trialized:
            return np.concatenate(trializedTimes)

        return trializedTimes

        
    def bin_spikes(self, **kwargs):
        times = self.find_event(**kwargs)
        print(times)


class Acquisition(Enum):
    NONE = 0
    BLACKROCK = 1
    OPEN_EPHYS = 2


@dataclass
class BehDatInfo:
    acquisition: Acquisition = Acquisition.NONE
    path: Path = Path()
    name: str = ''
    baud: int = 0
    samples: int = 0
    trialTypes: dict[str, list[int]] = field(default_factory=lambda: {})
    outcomes: dict[str, list[int]] = field(default_factory=lambda: {})
    stimTypes: dict[str, list[int]] = field(default_factory=lambda: {})
    condition: str = ''
    startState: str = ''
    channels: list[int] = field(default_factory=lambda: [])


@dataclass
class BehDatSpikes:
    times: np.ndarray
    region: str
    cluster: int


@dataclass
class BpodParser:
    info: BehDatInfo
    session: dict


    def trial_count(self) -> int:
        return int(self.session['nTrials'])


    def event_times(self, **kwargs):
        presets = PresetManager(**kwargs)



    def trial_intersection(self, **kwargs) -> np.array[bool]:
        presets = PresetManager(**kwargs)
        intersections = np.array([True for trial in range(0, self.trial_count())])
        trialTypes = presets.trialType
        outcomes = presets.outcome
        trials = presets.trials
        isDesiredTT = self._check_conditional_intersection('TrialTypes', trialTypes)
        isDesiredOutcome = self._check_conditional_intersection('SessionPerformance', outcomes)
        isDesiredTrial = np.isin(range(0, self.session['nTrials']), trials)
        return np.logical_and.reduce((intersections, isDesiredTT, isDesiredOutcome))


    def _check_conditional_intersection(self, 
                                    bpodField: str, 
                                    userInput: str | list[str]) -> np.array[bool]:
        bpodParserField = None
        match bpodField:
            case 'TrialTypes':
                bpodParserField = self.info.trialTypes
            case 'SessionPerformance':
                bpodParserField = self.info.outcomes
        bpodStruct = self.session    
        numTrials = self.trial_count()
        sessionField = bpodStruct[bpodField]
        if userInput is None:
            return np.array([True for trial in range(0, numTrials)])

        if isinstance(userInput, str):
            userInput = [userInput]

        trials = []
        for arg in userInput:
            argString = find_closest_match(arg, list(bpodParserField.keys()))
            argKey = int(bpodParserField[argString])
            trials.append(np.isin(sessionField, argKey))
        return np.logical_or.reduce(trials)


class RecordArgs(type):
    def __call__(cls, *args, **kwargs):
        declared = {f.name for f in fields(cls) if f.init}
        regular = {k: v for k, v in kwargs.items() if k in declared}
        extra = {k: v for k, v in kwargs.items() if k != "preset"}

        obj = cls.__new__(cls)
        object.__setattr__(obj, "_extraArgs", extra)
        obj.__init__(*args, **regular)
        return obj


@dataclass(kw_only=True)
class PresetManager(metaclass=RecordArgs):
    event: str = 'trial start'
    bpod: bool = False
    offset: float = 0.0
    edges: np.ndarray[tuple[float], np.float32] = field(default_factory=lambda: np.array([-2, 2]))
    unit: int | list = 0
    trialized: bool = False
    trialType: str | list[str] | None = None
    outcome: str | list[str] | None = None
    stimType: str | list[str] | None = None
    trials: int | list[str] | None = None
    preset: PresetManager | None = None
    _extraArgs: dict | None = field(init=False, default=None)
    

    def __post_init__(self, *args, **kwargs):
        presets : PresetManager | None = getattr(self, "preset")
        if presets is not None:
            self.copy(presets)
        for k, v in (self._extraArgs or {}).items():
            setattr(self, k, v)
        self.preset=None
        self._extraArgs=None
    
    def copy(self, copyObj: PresetManager):
        skip = {"preset", "_extraArgs"}
        for prop in copyObj.__dataclass_fields__:
            if prop not in skip:
                setattr(self, prop, getattr(copyObj, prop))

