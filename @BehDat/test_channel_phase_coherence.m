function test_channel_phase_coherence(obj, varargin)

% tests lfp phase coherence across channels for a given frequency band.
% Useful for spa_ppc methods where phase vectors required for inverse
% temperature and harmonic structure analyses

    presets = PresetManager(varargin{:});
    filteredSignal = obj.filter_signal('preset', presets);
    phase = cellfun(@(x) angle(hilbert(x)), filteredSignal, 'uni', 0);
    numSignals = size(phase{1}, 2);
    cosSimilarity = pdist(filteredSignal{1}', 'cosine');
    cosMat = squareform(cosSimilarity);
    correlationMat = zeros(numSignals);
    for i = 1:numSignals
        for j = i+1:numSignals
            corrScore = xcorr(phase{1}(:, i), phase{1}(:, j), 10);
            correlationMat(i, j) = corrScore(11);     
        end
    end
    figure
    heatmap(correlationMat)
    figure
    heatmap(cosMat)
    figure
    plot(phase{1})
    figure
    plot(filteredSignal{1})