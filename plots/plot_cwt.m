function plot_cwt(pwr, channel, freqs, panel)

% Plots a heatmap of the power spectra obtained from a cwt centered around
% trialized alignments.
% 
% INPUT:
%     power - a 1xC cell array obtained as the pwr output from cwt_power
%     channel - an integer value equal to the channel to plot, <= C
%     freqs - a cell array of frequency labels output from cwt_power
%     panel - an optional argument enabling plotting within the app

numFreqs = numel(freqs);
yTick = [1:10:numFreqs, numFreqs];
if exist('panel', 'var')
    h = figure('Visible', 'off');
    if iscell(pwr)
        surf(mean(pwr{channel}, 3), 'EdgeColor', 'none');
    else
        surf(pwr(:, :, channel), 'EdgeColor', 'none')
    end
    yticks(yTick)
    yticklabels(freqs(yTick))
    view(2)
    colorbar
    copyobj(h.Children, panel)
    close(h)
    return
end

figure
if iscell(pwr)
    surf(mean(pwr{channel}, 3), 'EdgeColor', 'none')
else
    surf(pwr(:, :, channel), 'EdgeColor', 'none')
end
view(2)
yticks(yTick)
yticklabels(freqs(yTick))
