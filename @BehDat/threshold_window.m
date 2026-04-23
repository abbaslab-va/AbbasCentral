function responsiveIdx = threshold_window(obj, presets, window, threshold)

% Helper function to identify neurons above or below a threshold within a
% window. Outputs index as ints
% Parse inputs
eWindow = presets.eWindow;
binWidth = presets.binWidth;
leftEdge = window(1);     % ms from event
rightEdge = window(2);    % ms 

% This code finds the reward window in which to identify outcome neurons, which
% will vary depending on the bin size.
eSteps = eWindow(1)*1000:binWidth:eWindow(2)*1000;
relativeEvent = find(eSteps == min(abs(eSteps)));
if numel(relativeEvent) > 1
    relativeEvent = relativeEvent(2);
end
stepsForwardLeftEdge = floor(leftEdge/binWidth) - 1;
stepsForwardRightEdge = floor(rightEdge/binWidth) - 1;
rewardWindow = relativeEvent + stepsForwardLeftEdge: ...
    relativeEvent + stepsForwardRightEdge;

    
% Calculate baselineMean and baselineSTD
smoothedRewardPSTH = obj.z_score('preset', presets);
% Identify rpNeurons
if threshold < 0
    responseDur = sum(smoothedRewardPSTH(:, rewardWindow) < threshold, 2);
else
    responseDur = sum(smoothedRewardPSTH(:, rewardWindow) > threshold, 2);
end
[~, maxIdx] = max(smoothedRewardPSTH, [], 2);
% maxInWindow = ismember(maxIdx, rewardWindow);
responsiveIdx = responseDur/size(rewardWindow, 2) > .5;