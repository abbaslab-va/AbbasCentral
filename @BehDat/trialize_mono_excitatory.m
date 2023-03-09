function weightsEx = trialize_mono_excitatory(obj, trialType, outcome)

if exist('outcome', 'var')
    outcome = append("x_", outcome);
    outcome(outcome == ' ') = '_';
    try
        outcome = obj.info.outcomes.(outcome);
    catch
        outcome = [];
    end
else
    outcome = [];
end
trialType(trialType == ' ') = '_';
eventString = strcat('x_', trialType);
trialsOfInterest = obj.info.trialTypes.(eventString);
exciteID = arrayfun(@(x) ~isempty(x.exciteOutput), obj.spikes);
spikes = obj.bin_spikes([0 obj.info.samples], 1);
trialStartTimes = find_event(obj, 'Trial Start');
trialStartTimes = round(trialStartTimes * 1000 / obj.info.baud);
isDesiredTT = ismember(obj.bpod.TrialTypes, trialsOfInterest);
trials2check = find(isDesiredTT);
if ~isempty(outcome)
    trials2check = intersect(trials2check, find(obj.bpod.SessionPerformance == outcome));
end
numTrials = numel(trials2check)-1;
numSpikes = size(spikes, 1);
weightsEx = cell(numSpikes, 1);
%     Excitatory
hasExcitatoryConn = find(exciteID);
for r = 1:numel(hasExcitatoryConn)
    ref = hasExcitatoryConn(r);
    refSpikes = spikes(ref, :);
    eTargets = obj.spikes(ref).exciteOutput;
    for target = eTargets
        targetSpikes = spikes(target, :);
        corrMat = zeros(numTrials, 101);
        indEx = obj.spikes(ref).exciteOutput == target;
        sessCorr = obj.spikes(ref).exciteXcorr(indEx, :);
        latMax = find(sessCorr == max(sessCorr));
        if numel(latMax) ~= 1
            latMax = latMax(latMax > 47 & latMax < 51);
        end
        %         for trial = trials2check
        for t = 1:numTrials
            trial = trials2check(t);
            tStart = trialStartTimes(trial);
            tEnd = trialStartTimes(trial + 1);
            refInterval = refSpikes(tStart:tEnd);
            targetInterval = targetSpikes(tStart:tEnd);
            corrMat(trial, :) = xcorr(refInterval, targetInterval, 50);
        end
        basecorr = sum(corrMat, 1);
        basewidevals = [basecorr(1:40), basecorr(end-39:end)];
        basemean = mean(basewidevals);
        basestd = std(basewidevals);        
%             enoughSpikes = sum(basecorr) > 1000;
%             lowJitter = basemean > 3*basestd;
%             if ~enoughSpikes || ~lowJitter
%                 continue
%             end
        % Excitatory conditionals
        try
            peakWeight = (basecorr(latMax) - basemean)/basestd;
            weightsEx{ref}(end+1) = peakWeight;
        catch
            obj.info.path
            peakWeight
            latMax
            ref
            target
        end

    end
end

