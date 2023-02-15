function weightsIn = trialize_mono_inhibitory(obj, trialType, outcome)

if exist('outcome', 'var')
    outcome = append("x_", outcome);
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
tic
inhibitID = arrayfun(@(x) ~isempty(x.inhibitOutput), obj.spikes);
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
weightsIn = cell(numSpikes, 1);



hasInhibConn = find(inhibitID);
for r = 1:numel(hasInhibConn)
    ref = hasInhibConn(r);
    refSpikes = spikes(ref, :);
    iTargets = obj.spikes(ref).inhibitOutput;
    for target = iTargets
        targetSpikes = spikes(target, :);
        corrMat = zeros(numTrials, 101);
        indInhib = obj.spikes(ref).inhibitOutput == target;
        latMin = find(obj.spikes(ref).inhibitXcorr(indInhib, :) == min(obj.spikes(ref).inhibitXcorr(indInhib, :)));
        if numel(latMin) ~= 1
            latMin = latMin(latMin > 47 & latMin < 51);
        end

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
     % Inhibitory conditionals

        peakWeight = (basecorr(latMin) - basemean)/basestd;
        weightsIn{ref}(end+1) = peakWeight;
    end
end
