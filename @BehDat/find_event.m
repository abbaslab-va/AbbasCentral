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

p = parse_BehDat('event', 'offset', 'outcome', 'trialType', 'trials');
addParameter(p, 'trialized', false, @islogical);
% Need to implement withinState as param for app - don't necesessarily need
% to flesh it out here
addParameter(p, 'withinState', [], validStates)
addParameter(p, 'excludeEventsByState', [], validStates)
addParameter(p, 'priorToState', [], validStates)
addParameter(p, 'priorToEvent', [], validStates)
addParameter(p, 'withinTimes', [], validTimes)
parse(p, event, varargin{:});
a = p.Results;
event = a.event;
offset = round(a.offset * obj.info.baud);
outcomeField = a.outcome;
trialTypeField = a.trialType;
trials = a.trials;
trialized = a.trialized;
withinTimes = a.withinTimes;

event(event == ' ') = '_';
try
    timestamp = obj.timestamps.keys.(event);
catch
    mv = MException('BehDat:MissingVar', sprintf('No timestamp pair found for event %s. Please edit config file and recreate object', event));
    throw(mv)
end
timestamps = obj.timestamps.times(obj.timestamps.codes == timestamp) + offset;

% trialInBounds = trialIncluded;


bpodTrials = obj.trial_intersection(outcomeField, trialTypeField, trials);
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