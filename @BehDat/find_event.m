function [timestamps, bpodTrials] = find_event(obj, varargin)

% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector found in the config.ini file
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector specifying which trials to include
%     'withinTimes' - a 1x2 vector specifying times to select events within (seconds)

presets = PresetManager(varargin{:});

offset = round(presets.offset * obj.info.baud);
% withinTimes = p.Results.withinTimes;

eventField = find_closest_match(presets.event, fields(obj.timestamps.keys));
try
    timestamp = obj.timestamps.keys.(eventField);
catch
    mv = MException('BehDat:MissingVar', sprintf('No timestamp pair found for event %s. Please edit config file and recreate object', presets.event));
    throw(mv)
end
timestamps = obj.timestamps.times(obj.timestamps.codes == timestamp) + offset;

eventTrials = discretize(timestamps, [obj.timestamps.trialStart(obj.timestamps.trialStart < obj.info.samples) obj.info.samples]);
%This logic is here while transitioning to using BpodParser in the BehDat
%class instead of a BpodSession struct.
try
    eventTrials = eventTrials(eventTrials <= obj.bpod.nTrials);
catch
    eventTrials = eventTrials(eventTrials <= obj.bpod.session.nTrials);
end
% trialInBounds = trialIncluded;

bpodTrials = obj.trial_intersection(eventTrials, presets);
% 
% if ~isempty(withinTimes)
%     edgesInSamples = withinTimes * obj.info.baud;
%     trialInBounds = discretize(timestamps, edgesInSamples);
%     trialInBounds = ~isnan(trialInBounds);
% end
% 
% bpodTrials = isDesiredTT & isDesiredOutcome & trialIncluded & trialInBounds;
timestamps = timestamps(bpodTrials);

if presets.trialized  
    eventTrial=discretize(timestamps,[obj.timestamps.trialStart obj.info.samples]);
    temp=timestamps;
    trialNo = unique(eventTrial);
    timestamps=cell(1,numel(trialNo));
    for t = trialNo
        timestamps{t} = temp(eventTrial == t);
    end
end 