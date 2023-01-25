% function [pairs, counts] = find_mono(corrCells)
function h = find_mono(corrCells)
%This function is a helper function for the NeurDat class method find_mono.
%
%INPUT:
%     corrCells - an NxN cell array, where N is the number of neurons.
%     Generated using the NeurDat method find_mono
% OUTPUT:
%     pairs - a 1xM cell array, where M is the number of monosynaptic pairs
%     counts - 11x1

for ref = 1:size(corrCells, 1)
    for target = 1:size(corrCells, 2)
        if isempty(corrCells{ref, target})
            continue
        end
        tiledlayout(2, 1)
        nexttile
        heatmap(corrCells{ref, target}(:, [41:61]), 'GridVisible', 'off')
        nexttile
        plot(mean(corrCells{ref, target}(:, 41:61), 1))
        pause
    end
end