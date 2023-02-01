function [numTT, numCorrect] = outcomes(obj, val)
    if ~exist('val', 'var')
        val = 1;
    end
    [numTT, numCorrect] = bpod_performance(obj.bpod, val);
end