function [f, b, e] = plot_outcome(obj, val, shapeVec)
    if ~exist('val', 'var')
        val = 1;
    end
    [numTT, numCorrect] = bpod_performance(obj.bpod, val);
    if ~exist('shapeVec', 'var')
        shapeVec = numel(numTT);
    end
    [f, b, e] = bar_and_error(numCorrect./numTT, shapeVec);
end