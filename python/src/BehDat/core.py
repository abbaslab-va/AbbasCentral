from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from .util import find_closest_match
import numpy as np



@dataclass
class BehDat:
    info: BehDatInfo
    spikes: dict[BehDatSpikes]
    timestamps: dict
    bpod: dict
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

        if presets.trialized:
            eventTrial = np.digitize(ts, trialStart)
            trializedTimes = []
            uniqueTrials = np.unique(eventTrial)
            for trial in uniqueTrials:
                tsInTrial = eventTrial == trial
                eventTS = ts[tsInTrial]
                trializedTimes.append(eventTS)
            return trializedTimes

        return ts

        
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
        pass


    def trial_intersection(self, **kwargs) -> np.array[bool]:
        presets = PresetManager(**kwargs)
        intersections = np.array([True for trial in range(0, self.trial_count())])
        trialTypes = presets.trialType
        outcomes = presets.outcome
        trials = presets.trials
        isDesiredTT = self.check_conditional_intersection('TrialTypes', trialTypes)
        isDesiredOutcome = self.check_conditional_intersection('SessionPerformance', outcomes)
        return np.logical_and.reduce((intersections, isDesiredTT, isDesiredOutcome))

    def check_conditional_intersection(self, 
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


@dataclass(kw_only=True)
class PresetManager:
    event: str = 'trial start'
    bpod: bool = False
    offset: float = 0.0
    edges: np.ndarray[tuple[float], np.float32] = field(default_factory=lambda: np.array([-2, 2]))
    unit: int | list = 0
    trialized: bool = False
    trialType: str | list[str] = None
    outcome: str | list[str] = None
    stimType: str | list[str] = None
    trials: int | list[str] = None
    presets: PresetManager = None
    