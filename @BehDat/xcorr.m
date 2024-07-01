function corrScore = xcorr(obj, varargin)

% Computes the cross-correlogram of the spike trains of all neurons centered 
% around the specified event. 
%
% OUTPUT:
%     corrScore - a 1xE cell array where E is the number of events. Each cell
%     contains an NxN matrix of cross-correlograms for that trial.
%
% INPUT:
%     variable name/value pairs from PresetManager class
%     event
%     trialType
%     outcome
%     stimType
%     offset

presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'corrWindow', 50, @isinteger);
parse(p, varargin{:});
corrWindow = p.Results.corrWindow;

eventTimes = obj.find_event(varargin{:});
numEvents = numel(eventTimes);
numBins = corrWindow * 2 + 1;
eventCorrTemp = int16(zeros(numEvents, numBins));
binnedSpikes = obj.bin_all_neurons(varargin{:});
numNeurons = numel(binnedSpikes);
corrScore = cell(numNeurons);
for ref = 1:numNeurons
    if ref == numNeurons
        continue
    end
    refSpikes = binnedSpikes{ref};
    for target = ref + 1:numNeurons
        targetSpikes = binnedSpikes{target};
        parfor event = 1:numEvents
            eventCorrTemp(event, :) = int16(xcorr(refSpikes(:, event), targetSpikes(:, event), corrWindow));
        end
        corrScore{ref, target} = sum(eventCorrTemp, 1, 'native');
    end
end