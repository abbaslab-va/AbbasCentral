function weightsEx = trialize_mono_excitatory(obj, event, varargin)

% OUTPUT:
%     weightsEx - an N x 1 cell array with excitatory connection weights 
%     for neuron pairs identified from find_mono, in the event window 
%     given by event and edges.
% INPUT:
%     trialType - a trial type char array that is in config.ini
%     event - an event char array that is in config.ini
%     edges - a 1x2 vector that defines the edges from an event 
%     within which spikes will be correlated
% optional name/value pairs:
%     'offset' - a number that defines the offset from the event you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'bpod' - a boolean that determines whether to use bpod or native timestamps
%     'includeNeg' - a boolean that determines whether to include negative weights in the output (false to plot graph)

p = parse_BehDat('event', 'trialType', 'outcome', 'edges', 'offset', 'bpod');
addParameter(p, 'includeNeg', false, @islogical);
parse(p, event, varargin{:});
a = p.Results;

trialType = a.trialType;
event = a.event;
edges = a.edges;
outcome = a.outcome;
offset = a.offset;
useBpod = a.bpod;
includeNeg = a.includeNeg;

if useBpod
    eventTimes = obj.find_bpod_event(event, 'trialType', trialType, 'outcome', outcome, 'offset', offset);
else
    eventTimes = obj.find_event(event, 'trialType', trialType, 'outcome', outcome, 'offset', offset);
end

edges = (edges * obj.info.baud) + eventTimes';
edgeCells = num2cell(edges, 2);
exciteID = arrayfun(@(x) ~isempty(x.exciteOutput), obj.spikes);
numSpikes = numel(obj.spikes);
weightsEx = cell(numSpikes, 1);
hasExcitatoryConn = find(exciteID);
numEvents = numel(edgeCells);

for r = 1:numel(hasExcitatoryConn)
    ref = hasExcitatoryConn(r);
    eTargets = obj.spikes(ref).exciteOutput;
    for target = eTargets
        corrMat = zeros(numEvents, 101);
        indEx = obj.spikes(ref).exciteOutput == target;
        sessCorr = obj.spikes(ref).exciteXcorr(indEx, :);
        latMax = find(sessCorr == max(sessCorr));
        if numel(latMax) ~= 1
            latMax = latMax(latMax > 47 & latMax < 51);
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
        peakWeight = (basecorr(latMax) - basemean)/basestd;
        if isnan(peakWeight) || peakWeight < 0 || isinf(peakWeight) || ~includeNeg
            peakWeight = 0.001;
        end
        weightsEx{ref}(end+1) = peakWeight;
    end
end
