function weightsIn = trialize_mono_inhibitory(obj, trialType, alignment, edges, varargin)

% OUTPUT:
%     weightsEx - an N x 1 cell array with inhibitory connection weights 
%     for neuron pairs identified from find_mono, in the event window 
%     given by alignment and edges.
% INPUT:
%     trialType - a trial type char array that is in config.ini
%     alignment - an alignment char array that is in config.ini
%     edges - a 1x2 vector that defines the edges from an event 
%     within which spikes will be correlated
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini

validVectorSize = @(x) all(size(x) == [1, 2]);
p = inputParser;
addRequired(p, 'trialType', @ischar);
addRequired(p, 'alignment', @ischar);
addRequired(p, 'edges', validVectorSize);
addParameter(p, 'offset', 0, @isnumeric)
addParameter(p, 'outcome', [], @ischar);
parse(p, trialType, alignment, edges, varargin{:});
a = p.Results;

trialType = a.trialType;
alignment = a.alignment;
edges = a.edges;
outcome = a.outcome;
offset = a.offset;

eventTimes = obj.find_event(alignment, 'trialType', trialType, 'outcome', outcome, 'offset', offset);
edges = (edges * obj.info.baud) + eventTimes';
edgeCells = num2cell(edges, 2);
inhibitID = arrayfun(@(x) ~isempty(x.inhibitOutput), obj.spikes);
numSpikes = numel(obj.spikes);
weightsIn = cell(numSpikes, 1);
hasInhibitoryConn = find(inhibitID);
numEvents = numel(edgeCells);

for r = 1:numel(hasInhibitoryConn)
    ref = hasInhibitoryConn(r);
    iTargets = obj.spikes(ref).inhibitOutput;
    for target = iTargets
        corrMat = zeros(numEvents, 101);
        indIn = obj.spikes(ref).inhibitOutput == target;
        sessCorr = obj.spikes(ref).inhibitXcorr(indIn, :);
        latMin = find(sessCorr == min(sessCorr));
        if numel(latMin) ~= 1
            latMin = latMin(latMin > 47 & latMin < 51);
        end

        for e = 1:numEvents
            eventEdges = edgeCells{e};
            binEdges = eventEdges(1):obj.info.baud/1000:eventEdges(2);
            refSpikes = histcounts(obj.spikes(ref).times, 'BinEdges', binEdges);
            targetSpikes = histcounts(obj.spikes(target).times, 'BinEdges', binEdges);
            corrMat(e, :) = xcorr(refSpikes, targetSpikes, 50);
        end

        basecorr = sum(corrMat, 1);
        basewidevals = [basecorr(1:40), basecorr(end-39:end)];
        basemean = mean(basewidevals);
        basestd = std(basewidevals);        
        peakWeight = (basemean - basecorr(latMin))/basestd;
        if isnan(peakWeight)
            peakWeight = 0.001;
        end
        weightsIn{ref}(end+1) = peakWeight;
    end
end