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
%     'trialized' - a logical that determines whether to return a cell array of timestamps for each trial or a vector of all timestamps
%     'excludeState' - a character vector of a state to exclude trials from
%     'withinState' - a character vector, string, or cell array of a state(s) to find the event within
%     'priorToState' - a character vector, string, or cell array of a state(s) to find the event prior to
%     'priorToEvent' - a character vector of an event to find the time prior to

presets = PresetManager(varargin{:});

offset = round(presets.offset * obj.info.baud);

eventTimes = obj.bpod.event_times('preset', presets);


% Find trial start times in acquisition system timestamps
trialStartTimes = num2cell(obj.find_event('event', 'Trial Start'), 1);
numTrialStart = numel(trialStartTimes);
eventTrials = 1:numTrialStart;
% Intersect all logical matrices to index bpod trial cells with
goodTrials = obj.trial_intersection(eventTrials, presets);
rawEvents = obj.bpod.session.RawEvents.Trial;
rawEvents2Check = rawEvents(goodTrials);

% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, eventTimes, bpodStartTimes, 'uni', 0);
% subtract the factor by which bpod outpaces the blackrock system
averageOffset = num2cell(obj.sampling_diff(presets));
eventOffsetCorrected = cellfun(@(x, y) round(x - x.*y), eventOffset, averageOffset, 'uni', 0);
eventTimesCorrected = cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrected, 'uni', 0);

if presets.trialized 
    timestamps = cellfun(@(x) x + offset, eventTimesCorrected, 'uni', 0);
else
    timestamps = cat(2, eventTimesCorrected{:}) + offset;
end 
