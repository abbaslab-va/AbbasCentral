function plot_cwt(pwr, channel, panel)

% Plots a heatmap of the power spectra obtained from a cwt centered around
% trialized alignments.

% INPUT:
%     power - a 1xC cell array obtained as the pwr output from cwt_power
%     channel - an integer value equal to the channel to plot, <= C
%     panel - an optional argument enabling plotting within the app

if exist('panel', 'var')
    h = figure('Visible', 'off');
    surf(mean(pwr{channel}, 3), 'EdgeColor', 'none');
    view(2)
    copyobj(h.Children, panel)
    close(h)
    return
end

figure
surf(mean(pwr{channel}, 3), 'EdgeColor', 'none')
view(2)
set(gcf, 'Position', get(0, 'ScreenSize'))