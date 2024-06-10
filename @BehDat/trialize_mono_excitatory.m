function weightsEx = trialize_mono_excitatory(obj, varargin)

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

presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'includeNeg', false, @islogical);
addParameter(p, 'refRegion', [], @ischar)
addParameter(p, 'targetRegion', [], @ischar)
parse(p, varargin{:});
 
if ~isfield(obj.spikes, 'exciteOutput')
    obj.find_mono
end   
    
includeNeg = p.Results.includeNeg;
refRegion = p.Results.refRegion;
targetRegion = p.Results.targetRegion;
baud = obj.info.baud;

eventTimes = obj.find_event('preset', presets);


edges = (presets.edges * baud) + eventTimes';
edgeCells = num2cell(edges, 2);
exciteID = arrayfun(@(x) ~isempty(x.exciteOutput), obj.spikes);
numSpikes = numel(obj.spikes);
weightsEx = struct('weights', cell(numSpikes, 1), 'fr', cell(numSpikes, 1));
cellRegions = extractfield(obj.spikes, 'region');
if ~isempty(refRegion)
    goodRefCells = cellfun(@(x) strcmp(x, refRegion), cellRegions)';
    hasExcitatoryConn = find(exciteID & goodRefCells);
else
    hasExcitatoryConn = find(exciteID);
end
numEvents = numel(edgeCells);

for r = 1:numel(hasExcitatoryConn)
    ref = hasExcitatoryConn(r);
    eTargets = obj.spikes(ref).exciteOutput;
    if ~isempty(targetRegion)
        goodTargetCells = find(cellfun(@(x) strcmp(x, targetRegion), cellRegions));
        eTargets = eTargets(ismember(eTargets, goodTargetCells));
    end
    refTimes = obj.spikes(ref).times;
    for target = eTargets
        targetTimes = obj.spikes(target).times;
        corrMat = zeros(numEvents, 101);
        indEx = obj.spikes(ref).exciteOutput == target;
        sessCorr = obj.spikes(ref).exciteXcorr(indEx, :);
        latMax = find(sessCorr == max(sessCorr));
        if numel(latMax) ~= 1
            latMax = latMax(latMax > 47 & latMax < 51);
        end
        parfor e = 1:numEvents
            eventEdges = edgeCells{e};
            binEdges = eventEdges(1):baud/1000:eventEdges(2);
            refSpikes = histcounts(refTimes, 'BinEdges', binEdges);
            targetSpikes = histcounts(targetTimes, 'BinEdges', binEdges);
            corrMat(e, :) = xcorr(refSpikes, targetSpikes, 50);
        end

        basecorr = sum(corrMat, 1);
        basewidevals = [basecorr(1:40), basecorr(end-39:end)];
        basemean = mean(basewidevals);
        basestd = std(basewidevals);        
        peakWeight = (basecorr(latMax) - basemean)/basestd;
        if isnan(peakWeight) || (peakWeight < 0 && ~includeNeg) || isinf(peakWeight) || peakWeight>50
            peakWeight = 0.001; 
        end
        weightsEx(ref).weights(end+1) = peakWeight;
    end
end
eventDur = cellfun(@(x) (x(2) - x(1))/obj.info.baud, edgeCells);
totalDur = sum(eventDur);
for ref = 1:numSpikes
    spikeTimes = cellfun(@(x) histcounts(obj.spikes(ref).times, 'BinEdges', x), edgeCells);
    spikeSubset = sum(spikeTimes);
    weightsEx(ref).fr = spikeSubset/totalDur;
end
