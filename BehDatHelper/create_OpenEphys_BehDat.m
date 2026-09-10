function sessObj = create_OpenEphys_BehDat(sessPath, subName, ini)

SessionData = load_bpod_session(sessPath);
coords = [];
% get session samples and sf
ephysSession = Session(sessPath);
recording = ephysSession.recordNodes{1}.recordings{1};
ephysKey = ephysSession.recordNodes{1}.recordings{1}.continuous.keys();
ephysKey = ephysKey{1};
ephysData = recording.continuous(ephysKey);
numSamples = numel(ephysData.timestamps);
sf = ephysData.metadata.sampleRate;

% bpod channels are analog 1-3
channelNames = ephysData.metadata.names;
adcChannels = find(cellfun(@(x) contains(x, 'ADC'), channelNames));
if ~isempty(adcChannels)
    bpodChannels = adcChannels(1:3);
    videoChannel = adcChannels(4);
    bpodData = ephysData.samples(bpodChannels, :);
    videoData = ephysData.samples(videoChannel, :);
    timestamps = get_bpod_analog_timestamps(bpodData);
    timestamps.keys = ini.timestamps;
else
    timestamps = [];
    videoData = [];
end
if ~isempty(ini.conditions)
    [~,FolderName] = fileparts(sessPath);  
    allConditions = fields(ini.conditions);
    matchingCondition = structfun(@(x) contains(FolderName, x), ini.conditions);
    sessionCondition = allConditions{matchingCondition};
else
    sessionCondition = [];
end

info = struct('acquisition', 'OpenEphys', 'path', sessPath, 'name', subName, 'baud', sf, 'samples', numSamples, ...
'trialTypes', ini.trialTypes, 'outcomes', ini.outcomes, 'stimTypes', ini.stimTypes, ...
'condition', sessionCondition, 'startState', ini.info.StartState, 'channels', ini.regions);

if ~isempty(dir('*.npy'))
    spikeStruct = get_spike_info_OpenEphys(sessPath, ini.regions, 0,0, numSamples); % for now including mua with flag, excluding waveforms with flag
else
    spikeStruct = struct();
end
configs.trialTypes = ini.trialTypes;
configs.outcomes = ini.outcomes;
configs.startState = ini.info.StartState;
configs.stimTypes = ini.stimTypes;
bpodObj = BpodParser('session',SessionData,'config', configs);
sessObj = BehDat(info, spikeStruct, timestamps, bpodObj, coords);
sessObj.get_e3v_frame_times(videoData)
try
    ts = sessObj.timestamps.keys.Trial_Start;
    timestamps = sessObj.timestamps.times(sessObj.timestamps.codes == ts);
    sessObj.timestamps.trialStart = timestamps;
catch
    CE = MException('BehDat:config', 'Please ensure one of the timestamps in your config file is assigned to Trial Start');
    warning('BehDat:config', 'Please ensure one of the timestamps in your config file is assigned to Trial Start')
end
% load 