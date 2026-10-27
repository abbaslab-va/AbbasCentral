import json
import tkinter as tk
from tkinter import filedialog, Tk, messagebox
from pathlib import Path
import numpy as np
import pandas as pd
import pickle
from kilosort.io import save_probe
from spikeinterface.extractors import read_openephys
from spikeinterface.core import write_binary_recording
from open_ephys.analysis import Session
from open_ephys.analysis.formats.OpenEphysRecording import OpenEphysContinuous
from configparser import ConfigParser
from scipy.io import loadmat
from .core import BehDat, BehDatInfo, BpodParser, Acquisition, BehDatSpikes, PresetManager


def convert_cnt_probe():
    root = tk.Tk()
    root.withdraw()
    fileSelection = filedialog.askopenfilename()
    if not fileSelection:
        print('no probe selected')
        return
    filePath = Path(fileSelection)
    with open(filePath, 'r') as file:
        probeData = json.load(file)
        channelCoords = probeData['probes'][0]['contact_positions']
        contactID = probeData['probes'][0]['contact_ids']
        if 'shank_ids' in probeData['probes'][0]:
            shankID = probeData['probes'][0]['shank_ids']
        else:
            shankID = [0 for contact in contactID]
    contactID = [int(contact) - 1 for contact in contactID]
    xc = [coords[0] for coords in channelCoords]
    yc = [coords[1] for coords in channelCoords]
    shankID = [int(site) for site in shankID]
    kilosortProbe = {'chanMap': np.array(contactID), 
                     'xc': np.array(xc), 
                     'yc': np.array(yc), 
                     'kcoords': np.array(shankID),
                     'n_chan': len(contactID)}
    save_probe(kilosortProbe, filePath)


def remap_mini_amp_binary():
    # These channels are manually transcribed from the mini-amp-64 user guide from CNT
    ch32Order = [56, 54, 55, 53, 52, 51, 50, 49, 48, 16, 14, 13, 12, 10, 11, 9, 
                64, 63, 62, 61, 60, 59, 58, 57, 8, 7, 6, 5, 4, 3, 2, 1]
    ch64Order = [42, 40, 39, 38, 36, 35, 34, 33, 30, 31, 29, 27, 26, 25, 23, 21, 
                47, 46, 45, 44, 43, 41, 37, 32, 28, 24, 22, 19, 20, 18, 17, 15] + ch32Order
    root = Tk()
    root.withdraw()
    response = messagebox.askyesnocancel("64 ch probe", "Are you using a 64 channel probe?")
    if response is True:
        channels = ch64Order
    elif response is False:
        channels = ch32Order
    else:
        channels = None
    if channels is not None:
        expPath = Path(filedialog.askdirectory())
        binFile = read_openephys(expPath, stream_id='0')

        binSubset = ['CH' + str(ch) for ch in channels]
        datSubset = binFile.select_channels(binSubset)
        write_binary_recording(datSubset, expPath)


def create_OpenEphys_BehDat(sessionPath: str) -> BehDat:
    if sessionPath is None:
        root = tk.Tk()
        root.withdraw()
        sessionPath = filedialog.askdirectory()
    sessionPath = Path(sessionPath)
    ephysSession = Session(sessionPath)
    configs = parse_ini(sessionPath)
    bdInfo : BehDatInfo = create_BehDatInfo(configs, sessionPath, ephysSession)
    spikes : dict[BehDatSpikes] = create_BehDatSpikes(sessionPath, bdInfo)
    timestamps : dict = create_BehDat_timestamps(ephysSession, configs)
    bpodSession : BpodParser = create_BpodParser(sessionPath, bdInfo)
    return BehDat(info=bdInfo, spikes=spikes, timestamps=timestamps, bpod=bpodSession, coordinates=[])


def parse_ini(iniPath: Path) -> ConfigParser:
    iniFiles = list(iniPath.glob("*.ini"))
    iniFile = iniFiles[0]
    I = ConfigParser()
    I.read(iniFile)
    return I


def create_BehDatInfo(I: ConfigParser, sessPath: Path, sess: Session) -> BehDatInfo:
    recordStruct: OpenEphysContinuous = get_continuous(sess)
    baud = recordStruct.metadata.sample_rate
    numSamples = recordStruct.samples.shape[0]

    regions = dict(I['regions'])
    for region in regions.keys():
        vals = regions[region]
        cleanStr = vals.strip("[] ")
        if not cleanStr:
            regions[region] = np.array([], dtype=int)
            continue

        parts = cleanStr.split(",")
        result = []

        for part in parts:
            part = part.strip()
            if ":" in part:
                start, end = map(int, part.split(":"))
                result.extend(range(start, end+1))
            else:
                result.append(int(part))
        regions[region] = result

    testInfo = BehDatInfo(acquisition=Acquisition.OPEN_EPHYS,
                          path=sessPath,
                          name="test",
                          baud=baud,
                          samples=numSamples,
                          trialTypes=dict(I['trialTypes']),
                          outcomes=dict(I['outcomes']),
                          stimTypes=dict(I['stimTypes']),
                          condition='test',
                          startState=I['info']['startstate'],
                          channels=regions)
    return testInfo


def create_BehDatSpikes(sessPath: Path, info: BehDatInfo) -> dict[BehDatSpikes]:
    unsortedSpikeTimes = np.load(sessPath / 'spike_times.npy')
    unsortedSpikeClusters = np.load(sessPath / 'spike_clusters.npy')
    clusterInfo = pd.read_csv(sessPath / 'cluster_info.tsv', sep='\t')
    goodClusters = clusterInfo.loc[clusterInfo['KSLabel'] == 'good']
    goodClusterID = goodClusters['cluster_id']
    goodChannels = goodClusters['ch']
    unitNo = 0
    spikeInfo = {}
    regions = info.channels

    for clust in goodClusterID:
        clustRegion = ''
        for region in regions.keys():
            if np.any(np.array(regions[region]) == goodChannels[clust]):
                clustRegion = region
                break
        spikeInds = np.argwhere(unsortedSpikeClusters == clust)
        spikeTimes = unsortedSpikeTimes[spikeInds]
        spikeInfo[unitNo] = BehDatSpikes(times=spikeTimes, region=clustRegion, cluster=clust)
        unitNo += 1

    return spikeInfo


def create_BehDat_timestamps(sess: Session, configs: ConfigParser) -> dict:

    continuousRec: OpenEphysContinuous = get_continuous(sess)
    channelNames = continuousRec.metadata.channel_names
    adcIdx = np.strings.find(channelNames, 'ADC') != -1
    adcChannels = continuousRec.samples[:, adcIdx]

    digitalTS = get_bpod_analog_timestamps(adcChannels)

    timestampDict = {}
    ts = configs['timestamps']
    for key in list(ts.keys()):
        tsIdx = int(ts[key])
        timestampDict[key] = digitalTS[tsIdx][0]

    return timestampDict
    

def get_bpod_analog_timestamps(adcChannels) -> list:
    if adcChannels.size == 0:
        print('no bpod')
        digitalTS = []

    else:
        tsTolerance = 30 # how far apart signals can be to be considered from the same call
        timestamps = []
        for i in range(0, 3):
            dataStream = np.array(adcChannels[:, i])
            threshold = 1000
            aboveThreshold = dataStream >= threshold
            edgeDiff = np.diff(aboveThreshold.astype(int))
            timestamps.append(np.where(edgeDiff == 1)[0] + 1)
            #timestamps.append(np.intersect1d(np.where(frameDiff > 1000), np.where(dataStream[:-1] < 1200)))
        digitalTS = [[] for i in range(0, 7)]
        for i in [7, 6, 5, 3]:  # reverse ordered binary values that share channels
            binByte = np.unpackbits(np.array([i], dtype=np.uint8))
            binIdx = np.flip(binByte[-3:])
            streamIdxs = [idx for idx, keep in enumerate(binIdx) if keep]
            currentTS = [timestamps[idx] for idx in streamIdxs]
            firstTS = currentTS[0]
            removeMasks = [np.zeros(len(ts), dtype=bool) for ts in timestamps]
            for ts in firstTS:
                withinTol = [np.abs(times - ts) < tsTolerance for times in currentTS]
                if all(w.any() for w in withinTol):
                    for streamPos, w in zip(streamIdxs, withinTol):
                        removeMasks[streamPos] |= w
            digitalTS[i - 1].append(firstTS[removeMasks[streamIdxs[0]]])
            timestamps = [a[~m] for a, m in zip(timestamps, removeMasks)]
        for idx, i in enumerate([4, 2, 1]):
            digitalTS[i - 1].append(timestamps[idx])
    return digitalTS


def create_BpodParser(sessPath: Path, sessInfo: BehDatInfo) -> BpodParser:
    matFiles = list(sessPath.glob("*.mat"))
    if len(matFiles) == 0:
        return None
    bpodFile = loadmat(matFiles[0], simplify_cells=True)
    sessionData = bpodFile['SessionData']
    return BpodParser(sessInfo, sessionData)


def get_continuous(sess: Session) -> OpenEphysContinuous:
    return sess.recordnodes[0].recordings[0].continuous[0]


def save_BehDat(obj: BehDat):
    fileName = obj.info.name + '.pkl'
    saveDir = obj.info.path / fileName
    with open(saveDir, "wb") as file:
        pickle.dump(obj, file)


def load_BehDat(filePath: str = None) -> BehDat:
    if filePath is None:
        root = tk.Tk()
        root.withdraw()
        filePath = Path(filedialog.askopenfilename())

    savedBehDat: BehDat = None

    with open(filePath, "rb") as file:
        savedBehDat = pickle.load(file)

    return savedBehDat