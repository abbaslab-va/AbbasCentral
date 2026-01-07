function goodChannels = test_channel_phase_coherence(obj, varargin)

% tests lfp phase coherence across channels for a given frequency band.
% Useful for spa_ppc methods where phase vectors required for inverse
% temperature and harmonic structure analyses

    presets = PresetManager(varargin{:});
    filteredSignal = obj.filter_signal('edges', [0 10], 'region', presets.region);
    numZeroCrossings = cellfun(@(x) sum(abs(x) < 100), filteredSignal, 'uni', 0);
    totalZeroCrossings = sum(cat(1, numZeroCrossings{:}), 1);
    % find similar data 
    cosSimilarity = pdist(filteredSignal{1}', 'cosine');
    linkageData = linkage(cosSimilarity);
    signalClusters = cluster(linkageData, 'maxclust', 2);
    maxCrossings = 0;
    maxClust = 0;
    for clust = 1:2
        numCrossings = mean(totalZeroCrossings(signalClusters == clust));
        if numCrossings > maxCrossings
            maxCrossings = numCrossings;
            maxClust = clust;
        end
    end
    % goodSignal = cellfun(@(x) mean(x(:, signalClusters == maxClust)), filteredSignal, 'uni', 0);
    goodChannels = obj.info.channels.(presets.region)(signalClusters == maxClust');
    % phase = cellfun(@(x) angle(hilbert(x)), goodSignal, 'uni', 0);
    % numSignals = size(phase{1}, 2);
    % 
    % cosMat = squareform(cosSimilarity);
    % 
    % correlationMat = zeros(numSignals);
    % for i = 1:numSignals
    %     for j = i+1:numSignals
    %         corrScore = xcorr(phase{1}(:, i), phase{1}(:, j), 10);
    %         correlationMat(i, j) = corrScore(11);     
    %     end
    % end

    % meanPhase = angle(hilbert(mean(goodSignal{1}, 2)));
    % figure
    % heatmap(correlationMat)
    % figure
    % heatmap(cosMat)
    % figure
    % plot(phase{1})
    % hold on
    % plot(meanPhase, 'LineStyle', '--', 'LineWidth', 2, 'Color', 'k')
    % figure
    % plot(goodSignal{1})