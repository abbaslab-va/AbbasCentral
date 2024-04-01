function timestamps = find_event_all(obj, varargin)

% This will ultimately combine the functionality of find_event and
% find_bpod_event.

presets = PresetManager(varargin{:});
% Convert seconds offset into sampling rate of acquisition system
offset = round(presets.offset * obj.info.baud);

if presets.bpod
    % Get event times from BpodParser method in seconds from trial start
    eventTimes = obj.bpod.event_times('preset', presets);
    % Convert Bpod trialized timestamps to absolute Blackrock timestamps
    eventTimesCorrected = obj.bpod_to_blackrock(eventTimes, presets);
    % Return either a cell array of trialized timestamps or a concatenated vector
    if presets.trialized 
        timestamps = cellfun(@(x) x + offset, eventTimesCorrected, 'uni', 0);
    else
        timestamps = cat(2, eventTimesCorrected{:}) + offset;
    end 
else
    % Levenshtein distance to find closest event in timestamps
    [eventField, eventEdited] = find_closest_match(presets.event, fields(obj.timestamps.keys));
    if eventEdited
        fprintf("Closest match found to %s: '%s'\n", presets.event, eventField)
    end
    % Match timestamp wire codes to user input
    try
        ts = obj.timestamps.keys.(eventField);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No timestamp pair found for event %s. Please edit config file and recreate object', presets.event));
        throw(mv)
    end
    matchingTimestamp = obj.timestamps.codes == ts;
    timestamps = obj.timestamps.times(matchingTimestamp) + offset;
    eventTrials = discretize(timestamps, [obj.timestamps.trialStart(obj.timestamps.trialStart < obj.info.samples) obj.info.samples]);
    eventTrials = eventTrials(eventTrials <= obj.bpod.session.nTrials);
    bpodTrials = obj.bpod.trial_intersection_BpodParser('preset', presets);
    if presets.trialized
        eventTrial = discretize(timestamps,[obj.timestamps.trialStart obj.info.samples]);
        temp = timestamps;
        trialNo = unique(eventTrial);
        timestamps = cell(1, numel(trialNo));
        for t = trialNo
            timestamps{t} = temp(eventTrial == t);
        end
        timestamps = timestamps(bpodTrials);
    else
        timestamps = timestamps(bpodTrials(eventTrials));
    end 
end