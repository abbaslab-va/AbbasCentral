from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from configparser import ConfigParser
from scipy.io import loadmat
import numpy as np


@dataclass
class BehDat:
    info: BehDatInfo
    spikes: BehDatSpikes
    timestamps: dict
    bpod: dict
    coordinates: np.ndarray


    def bin_spikes(self, **kwargs):
        print('bin spikes')
        presets = PresetManager(kwargs)


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


@dataclass
class BpodParser:
    info: BehDatInfo
    session: dict


@dataclass
class PresetManager:
    event: str = 'Trial_Start'
    bpod: bool = False
    offset: float = 0.0
    edges: np.ndarray[tuple[float], np.float32] = field(default_factory=lambda: np.array([-2, 2]))
    unit: int | list = 0


    def __init__(self, varargs: dict):
        for key, value in varargs.iteritems():
            setattr(self, key, value)