function plot_mono(obj, varargin)

% Plots a figure for each cross-correlation between neurons in the
% BehDat object. If no arguments are given, plots all neurons with a connection 
% identified. If a single argument is given, it should be a vector of 
% reference neuron indices to plot.

numNeurons = numel(obj.spikes);
animalName = obj.info.name;
if nargin == 1
    refNeurons = 1:numNeurons;
elseif nargin == 2    
    refNeurons = varargin{1};
end

for ref = refNeurons
    if isempty(obj.spikes(ref).exciteOutput)
        continue
    end
    for t = 1:numel(obj.spikes(ref).exciteOutput)
        target = obj.spikes(ref).exciteOutput(t);
        leadingRegion = obj.spikes(ref).region;
        targetRegion = obj.spikes(t).region;
        sessCorr = obj.spikes(ref).exciteXcorr(t, :);
        figure
        plot(sessCorr)
        title(sprintf("Animal %s  Ref region: %s (%d)  Target region: %s (%d)",...
            animalName, leadingRegion, ref, targetRegion, target))
    end
end