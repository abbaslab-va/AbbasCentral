function [timestamps, bpodTrials] = find_event(obj, event, varargin)

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

validStates = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validTimes = @(x) all(size(x) == [1, 2]);
validPreset = @(x) isa(x, 'PresetManager');

p = parse_BehDat('event', 'offset', 'outcome', 'trialType', 'trials');
addParameter(p, 'trialized', false, @islogical);
% Need to implement withinState as param for app - don't necesessarily need
% to flesh it out here
addParameter(p, 'withinState', [], validStates)
addParameter(p, 'excludeEventsByState', [], validStates)
addParameter(p, 'priorToState', [], validStates)
addParameter(p, 'priorToEvent', [], validStates)
addParameter(p, 'withinTimes', [], validTimes)
addParameter(p, 'preset', [], validPreset)
parse(p, event, varargin{:});
if isempty(p.Results.preset)
    a = p.Results;
else
    a = p.Results.preset;
end
offset = round(a.offset * obj.info.baud);
trialized = p.Results.trialized;
% withinTimes = p.Results.withinTimes;

a.event(a.event == ' ') = '_';
try
    timestamp = obj.timestamps.keys.(a.event);
catch
    mv = MException('BehDat:MissingVar', sprintf('No timestamp pair found for event %s. Please edit config file and recreate object', a.event));
    throw(mv)
end
timestamps = obj.timestamps.times(obj.timestamps.codes == timestamp) + offset;

eventTrials = discretize(timestamps, [obj.timestamps.trialStart obj.info.samples]);
eventTrials = eventTrials(eventTrials <= obj.bpod.nTrials);
% trialInBounds = trialIncluded;

bpodTrials = obj.trial_intersection(eventTrials, a.outcome, a.trialType, a.trials);
% 
% if ~isempty(withinTimes)
%     edgesInSamples = withinTimes * obj.info.baud;
%     trialInBounds = discretize(timestamps, edgesInSamples);
%     trialInBounds = ~isnan(trialInBounds);
% end
% 
% bpodTrials = isDesiredTT & isDesiredOutcome & trialIncluded & trialInBounds;
timestamps = timestamps(bpodTrials);

if trialized  
    eventTrial=discretize(timestamps,[obj.timestamps.trialStart obj.info.samples]);
    temp=timestamps;
    trialNo = unique(eventTrial);
    timestamps=cell(1,numel(trialNo));
    for t = trialNo
        timestamps{t} = temp(eventTrial == t);
    end
end 