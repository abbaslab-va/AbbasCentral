from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
import numpy as np


@dataclass
class BehDat:
    info: BehDatInfo
    spikes: dict[BehDatSpikes]
    timestamps: dict
    bpod: dict
    coordinates: np.ndarray


    def find_event(self, **kwargs):
        presets = PresetManager(kwargs)
        offset = round(presets.offset * self.info.baud)
        
        if presets.bpod:
            print('BpodParser lol')

        try:
            ts = self.timestamps[presets.event] + offset
        except:
            print(f"No timestamp pair found for event {presets.event}")

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


    def event_times(self, **kwargs):
        pass


    def trial_intersection(self, **kwargs):
        pass


@dataclass
class PresetManager:
    event: str = 'trial start'
    bpod: bool = False
    offset: float = 0.0
    edges: np.ndarray[tuple[float], np.float32] = field(default_factory=lambda: np.array([-2, 2]))
    unit: int | list = 0
    trialized: bool = False

    def __init__(self, varargs: dict):
        for key, value in varargs.items():
            setattr(self, key, value)