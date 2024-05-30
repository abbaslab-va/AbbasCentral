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
    if isscalar(fInfo) && strcmp(fInfo.name, "SessionData")
        load(fName, 'SessionData')
    end
end
coords = [];
if ~exist('SessionData', 'var')
    warning('No Bpod session named SessionData.mat found in %s', sessPath)
end
[~,FolderName] = fileparts(sessPath);   


NEV_dir = dir(fullfile(sessPath,'*.nev'));
NEV_names = extractfield(NEV_dir, 'name');
if numel(NEV_names)~=1
    CE = MException('BehDat:config', 'Need to have exactly 1 NEV file in the current directory');
    throw(CE)
else
    NEV=openNEV(fullfile(sessPath, NEV_names{1}));
end

sf = double(NEV.MetaTags.SampleRes);
numSamples = double(NEV.MetaTags.DataDuration);
if ~isempty(ini.conditions)
    allConditions = fields(ini.conditions);
    matchingCondition = structfun(@(x) contains(FolderName, x), ini.conditions);
    sessionCondition = allConditions(matchingCondition);
end

info = struct('path', sessPath, 'name', n, 'baud', sf, 'samples', numSamples, ...
    'trialTypes', ini.trialTypes, 'outcomes', ini.outcomes, 'stimTypes', ini.stimTypes, ...
    'condition', sessionCondition, 'startState', ini.info.StartState, 'channels', ini.regions);

timestamps = adjust_timestamps(NEV, SessionData.nTrials);
timestamps.keys = ini.timestamps;
if ~isempty(dir('*.npy'))
    spikeStruct = get_spike_info(sessPath, ini.regions);
else
    spikeStruct = struct();
end
configs.trialTypes = ini.trialTypes;
configs.outcomes = ini.outcomes;
configs.startState = ini.info.StartState;
bpodObj = BpodParser('session',SessionData,'config', configs);
sessObj = BehDat(info, spikeStruct, timestamps, bpodObj, coords);

try
    ts = sessObj.timestamps.keys.Trial_Start;
    timestamps = sessObj.timestamps.times(sessObj.timestamps.codes == ts);
    sessObj.timestamps.trialStart = timestamps;
catch
    CE = MException('BehDat:config', 'Please ensure one of the timestamps in your config file is assigned to Trial Start');
    warning('BehDat:config', 'Please ensure one of the timestamps in your config file is assigned to Trial Start')
end