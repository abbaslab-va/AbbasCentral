function sessObj = populate_BehDat(sessPath, n, tsDict)
%This function will create a behavioral object that contains all neural and 
%behavioral data for the recorded behavioral sesison.

cd(sessPath)
dir = ('*.mat');
for m = 1:length(dir)
    fName = dir(m).name;
    fInfo = whos('-file', 'fname');
    if fInfo.name == 'SessionData'
        load('fName', 'SessionData')
    end
end

try
catch
    warning('No Bpod session named SessionData.mat found in %s', sessPath)
end
[~,FolderName] = fileparts(sessPath);   

NEV_file = strcat(sessPath,'\',FolderName, '.nev');
if ~isempty(dir(fullfile(sessPath , '*.nev')))
    NEV=openNEV(NEV_file);
end

sf = double(NEV.MetaTags.SampleRes);
numSamples = double(NEV.MetaTags.DataDuration);

info = struct('path', sessPath, 'name', n, 'baud', sf, 'samples', numSamples);

timestamps = adjust_timestamps(NEV, SessionData.nTrials);
timestamps.keys = tsDict;
spikeStruct = get_spike_info(sessPath);

%For LFP
% NS_6 = strcat(sessPath,'\',FolderName, '.ns6');
% if ~isempty(dir(fullfile(sessPath, '*.ns6')))
%     openNSx(NS_6)
% end

sessObj = BehDat(info, spikeStruct, [], [], timestamps, SessionData);

try
    sessObj.timestamps.trialStart = sessObj.find_event('Trial_Start');
catch
    CE = MException('BehDat:config', 'Please ensure one of the timestamps in your config file is assigned to Trial Start');
    throw(CE)
end
