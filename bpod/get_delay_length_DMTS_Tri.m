function delayByTrial = get_delay_length_DMTS_Tri(SessionData)

% Returns a vector of delay lengths corresponding to the bpod trials in
% SessionData for the DMTS_Tri task

if isfield(SessionData, 'GUI')
    delayByTrial = extractfield(SessionData.GUI, 'DelayHoldTime');
else
    delayByTrial = zeros(1, SessionData.nTrials);
    rawData = SessionData.RawData;
    for trial = 1:SessionData.nTrials
        stateNames = rawData.OriginalStateNamesByNumber{trial};
        trialEvents = rawData.OriginalStateData{trial};
        orderedStateNames = stateNames(trialEvents);
        delayStart = cellfun(@(x) strcmp(x, 'DelayTimer'), orderedStateNames);
        delayEnd = cellfun(@(x) strcmp(x, 'DelayOn'), orderedStateNames);
        lastDelayStart = find(delayStart, 1, 'last');
        lastDelayOn = find(delayEnd, 1, 'last');
        delayByTrial(trial) = rawData.OriginalStateTimestamps{trial}(lastDelayOn) - rawData.OriginalStateTimestamps{trial}(lastDelayStart);
    end
end