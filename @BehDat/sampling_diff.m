function bpodOffset = sampling_diff(obj)

% This function calculates the difference between the elapsed time between trials recorded
% by the Bpod and the elapsed time between trials recorded by the blackrock acquisition system.
% OUTPUT: 
%     bpodOffset - the difference between the two systems expressed as (bpodTime - blackrockTime)/blackrockTime

acqDiff = diff(obj.timestamps.trialStart);
bpodDiff = diff(obj.bpod.TrialStartTimestamp .* obj.info.baud);
if numel(acqDiff) ~= numel(bpodDiff)
    bpodOffset = 1;
    return
end
sampDiff = (bpodDiff - acqDiff)./acqDiff;
bpodOffset = mean(sampDiff);