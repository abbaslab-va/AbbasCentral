function corrScore = xcorr(obj, event, edges)

% INPUT:
%     event - a string of an event named in config.ini
%     edges - 1x2 vector specifying distance from the event in seconds

    timestamps = obj.find_event(event);
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