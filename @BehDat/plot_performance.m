function plot_performance(obj, outcome, panel)

% Plots bpod performance bar chart by trial type
% INPUT:
%     outcome - the outcome whos percentage is being visualized
%     panel - a panel handle from AbbasCentral (optional)

[trials, correct] = bpod_performance(obj.bpod, outcome);
pctCorrect = correct./trials * 100;

if exist('panel', 'var')
    h = figure('Visible', 'off');
    bar(pctCorrect)
    copyobj(h.Children, panel)
    close(h)
else
    figure
    bar(pctCorrect)
end