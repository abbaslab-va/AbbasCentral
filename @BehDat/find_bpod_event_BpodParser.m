function timestamps = find_bpod_event_BpodParser(obj, varargin)

% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector from the bpod SessionData
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers to include
%     'trialized' - a boolean controlling the output style
%     'excludeState' - a character vector of a state to exclude trials from
%     'withinState' - a character vector, string, or cell array of a state(s) to find the event within
%     'priorToState' - a character vector, string, or cell array of a state(s) to find the event prior to
%     'priorToEvent' - a character vector of an event to find the time prior to

% Build PresetManager object from name/value pairs
presets = PresetManager(varargin{:});
% Convert seconds offset into sampling rate of acquisition system
offset = round(presets.offset * obj.info.baud);
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
