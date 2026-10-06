import json
import tkinter as tk
from tkinter import filedialog, Tk, messagebox
from pathlib import Path
import numpy as np
from kilosort.io import save_probe
from spikeinterface.extractors import read_openephys
from spikeinterface.core import write_binary_recording


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


