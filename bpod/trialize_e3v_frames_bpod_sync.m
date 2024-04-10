function alignedTrials = trialize_e3v_frames_bpod_sync(sessionData, vidPath)


eventCells = sessionData.RawEvents.Trial;
numTrials = numel(eventCells);
alignedTrials = cell(2, numTrials);
frameNo = 1;
trialInVideo = false;
extraTime = 0;
bncPrev = 0;
eventsLost = 0;
frameLength = 1/30;
for trialNo = 1:numTrials
    trialEvents = eventCells{trialNo}.Events;
    if isfield(trialEvents, 'BNC1High') && isfield(trialEvents, 'BNC1Low')
        bncDiff = numel(trialEvents.BNC1High) - numel(trialEvents.BNC1Low);
        firstHigh = trialEvents.BNC1High(1);
        lastHigh = trialEvents.BNC1High(end);
        trialEndDist = sessionData.TrialEndTimestamp(trialNo) - sessionData.TrialStartTimestamp(trialNo) - lastHigh;
        switch bncDiff
            case 1      %More high timestamps
                BNCwidth = trialEvents.BNC1Low - trialEvents.BNC1High(1:end-1);
            case 0      %Equal number
                BNCwidth = abs(trialEvents.BNC1Low - trialEvents.BNC1High);
            case -1     %More low timestamps
                BNCwidth = trialEvents.BNC1Low(2:end) - trialEvents.BNC1High;
        end
        if any(BNCwidth > 0.0165) & ~trialInVideo % 50% duty cycle width indicates start of video recording, .0166 seconds at 30 fps
            trialInVideo = true;
            firstFrame = find(BNCwidth > .0165, 1);
            firstFrameTime = trialEvents.BNC1High(firstFrame);
            firstFrameTrial = trialNo;
            pulseWidth = mean(BNCwidth(firstFrame:end));
            if firstFrameTrial == 1 && firstFrameTime < .1
                warning(sprintf("Video %s was saved early", vidPath))
                % framesEarly = delay_from_video_DMTS_Tri(vidPath);
            end
        elseif any(BNCwidth > 0.0165) & trialInVideo
            firstFrame = find(BNCwidth > .0165, 1);
            pulseWidth = mean(BNCwidth(firstFrame:end));
        end
    end
    if exist('firstFrameTrial', 'var')
        try
            timeLost = sessionData.TrialStartTimestamp(trialNo) - sessionData.TrialEndTimestamp(trialNo-1);
            eventsLost = floor((timeLost + trialEndDist)/(pulseWidth*2)) - bncDiff;
            bpodOffset = (frameLength - 2*pulseWidth)./(2*pulseWidth);                
            timeLost = timeLost + timeLost*bpodOffset;
        catch
            timeLost = 0;
        end
        framesLost = timeLost*30 + extraTime;
        % frameNo = frameNo + ceil(framesLost);    %could be responsible for drift
        frameNo = frameNo + floor(framesLost);
        % frameNo = frameNo + eventsLost;
        extraTime = mod(framesLost, 1);
    end
    if trialInVideo
        trialFrames = find(BNCwidth > .0165);
        frameTimes = trialEvents.BNC1High(trialFrames);
        if bncDiff == 1
            frameTimes(end+1) = trialEvents.BNC1High(end);
        end
        alignedTrials{1, trialNo} = frameTimes;
        alignedTrials{2, trialNo} = frameNo:frameNo + numel(frameTimes) - 1;
        frameNo = frameNo + numel(frameTimes);
    end
    bncPrev = bncDiff;
end


