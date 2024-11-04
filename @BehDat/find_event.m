function [timestamps, bpodTrial] = find_event(obj, varargin)

% This is one of the most core functions to the functionality of this
% software package. It extracts timestamps according to the input
% parameters, managed by the PresetManager class. At minimum, the user
% should specify an event using the name value pair ('event', 'eventName')

presets = PresetManager(varargin{:});
% Convert seconds offset into sampling rate of acquisition system
offset = round(presets.offset * obj.info.baud);

if presets.bpod
    % Get event times from BpodParser method in seconds from trial start
    eventTimes = obj.bpod.event_times(varargin{:});
    % Convert Bpod trialized timestamps to absolute Blackrock timestamps
    eventTimesCorrected = obj.bpod_to_blackrock(eventTimes, presets);
    % Return either a cell array of trialized timestamps or a concatenated vector
    if presets.trialized 
        timestamps = cellfun(@(x) x + offset, eventTimesCorrected, 'uni', 0);
    else
        timestamps = cat(2, eventTimesCorrected{:}) + offset;
    end 
    return
end

% Levenshtein distance to find closest event in timestamps
[eventField, eventEdited] = find_closest_match(presets.event, fields(obj.timestamps.keys));
if eventEdited
    fprintf("Closest match found to %s: '%s'\n", presets.event, eventField)
end
% Match timestamp wire codes to user input
try
    ts = obj.timestamps.keys.(eventField);
catch
    mv = MException('BehDat:MissingVar', sprintf(['No timestamp pair found for event %s. ' ...
        'Please edit config file and recreate object'], presets.event));
    throw(mv)
end
matchingTimestamp = obj.timestamps.codes == ts;
timestamps = obj.timestamps.times(matchingTimestamp) + offset;
eventTrials = discretize(timestamps, [obj.timestamps.trialStart(obj.timestamps.trialStart < obj.info.samples) obj.info.samples]);
eventTrials = eventTrials(eventTrials <= obj.bpod.session.nTrials);
goodTrials = obj.bpod.trial_intersection_BpodParser('preset', presets);
goodEvents = ismember(eventTrials, find(goodTrials));
bpodTrial = eventTrials(goodEvents);
eventTrial = discretize(timestamps,[obj.timestamps.trialStart obj.info.samples]);
temp = timestamps;
trialNo = unique(eventTrial(~isnan(eventTrial)));
timestamps = cell(1, numel(goodTrials));
for t = trialNo
    timestamps{t} = temp(eventTrial == t);
end
timestamps = timestamps(goodTrials);
emptyTrials = cellfun(@(x) isempty(x), timestamps);
if presets.firstEvent
    firstEvents = cellfun(@(x) ismember(x, x(1)), timestamps(~emptyTrials), 'uni', 0);
else
    firstEvents = cellfun(@(x) true(size(x)), timestamps(~emptyTrials), 'uni', 0);
end
if presets.lastEvent
    lastEvents = cellfun(@(x) ismember(x, x(end)), timestamps(~emptyTrials), 'uni', 0);
else
    lastEvents = cellfun(@(x) true(size(x)), timestamps(~emptyTrials), 'uni', 0);
end
goodTS = cellfun(@(x, y, z) x(y & z), timestamps(~emptyTrials), firstEvents, lastEvents, 'uni', 0);
timestamps(~emptyTrials) = goodTS;
if ~presets.trialized
    timestamps = cat(2, timestamps{:});
end