function brTimes = bpod_to_blackrock(obj, bpodTimes, presets)

goodTrials = obj.bpod.trial_intersection_BpodParser('preset', presets);
rawEvents2Check = obj.bpod.session.RawEvents.Trial(goodTrials);
trialStartTimes = num2cell(obj.timestamps.trialStart(goodTrials));
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, bpodTimes, bpodStartTimes, 'uni', 0);
% subtract the factor by which bpod outpaces the blackrock system
averageOffset = num2cell(obj.sampling_diff(presets));
eventOffsetCorrected = cellfun(@(x, y) round(x - x.*y), eventOffset, averageOffset, 'uni', 0);
brTimes = cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrected, 'uni', 0);