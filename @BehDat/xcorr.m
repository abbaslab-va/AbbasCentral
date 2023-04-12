function [corrScore, trialTypes] = xcorr(obj, event, edges)

% Computes the cross-correlogram of the spike trains of all neurons centered 
% around the specified event. 
%
% OUTPUT:
%     corrScore - a 1xE cell array where E is the number of events. Each cell
%     contains an NxN matrix of cross-correlograms for that trial.
%     trialTypes - a 1xE vector of trial types for each trial
%
% INPUT:
%     event - a string of an event named in config.ini
%     edges - 1x2 vector specifying distance from the event in seconds

    trialStart = obj.find_event('Trial_Start');
    timestamps = obj.find_event(event);
    trialNo = discretize(timestamps, [trialStart obj.info.samples]);
    trialTypes = obj.bpod.TrialTypes(trialNo);
    edges = num2cell(edges * obj.info.baud + timestamps', 2);
    binnedSpikes = cellfun(@(x) obj.bin_spikes(x, 1), edges, 'uni', 0);
    corrScore = cellfun(@corrfun, binnedSpikes, 'uni', 0);
end

function corrCells = corrfun(spikeMat)
    numNeurons = size(spikeMat, 1);
    corrCells = cell(numNeurons);
    for ref = 1:numNeurons
        if ref == numNeurons
            continue
        end
        refTrain = spikeMat(ref, :);
        for target = ref + 1:numNeurons
            targetTrain = spikeMat(target, :);
            corrCells{ref, target} = round(xcorr(refTrain, targetTrain, 10));
        end
    end
end