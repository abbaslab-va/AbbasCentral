function sessObj = populate_BehDat(sessPath, n, ini)

% This function will create a behavioral object that contains all neural and 
% behavioral data for the recorded behavioral sesison.
% 
% INPUT:
%     sessPath - path to the behavioral session folder
%     n - session name
%     ini - config.ini file for the experiment read in using the INI package

cd(sessPath)
matdir = dir('*.mat');
for m = 1:length(matdir)
    fName = matdir(m).name;
    fInfo = whos('-file', fName);
    if numel(fInfo) == 1 && strcmp(fInfo.name, "SessionData")
        load(fName, 'SessionData')
    end
end
coords = [];
if ~exist('SessionData', 'var')
    warning('No Bpod session named SessionData.mat found in %s', sessPath)
end
[~,FolderName] = fileparts(sessPath);   

NEV_file = strcat(sessPath,'\',FolderName, '.nev');
if ~isempty(dir(fullfile(sessPath , '*.nev')))
    NEV=openNEV(NEV_file);
end

sf = double(NEV.MetaTags.SampleRes);
numSamples = double(NEV.MetaTags.DataDuration);

info = struct('path', sessPath, 'name', n, 'baud', sf, 'samples', numSamples, 'trialTypes', ini.trialTypes, 'outcomes', ini.outcomes);

timestamps = adjust_timestamps(NEV, SessionData.nTrials);
timestamps.keys = ini.timestamps;
spikeStruct = get_spike_info(sessPath, ini.regions);

sessObj = BehDat(info, spikeStruct, [], [], timestamps, SessionData, coords);

try
    sessObj.timestamps.trialStart = sessObj.find_event('Trial_Start');
catch
    CE = MException('BehDat:config', 'Please ensure one of the timestamps in your config file is assigned to Trial Start');
    throw(CE)
end
