classdef NeurDat < BehDat
    properties
        spikes
        lfp
    end

    methods
        function obj = NeurDat(varargin)
            switch nargin
                case 1
                    obj.spikes = varargin{1};
                case 2
                    obj.spikes = varargin{1};
                    obj.lfp = varargin{2};
            end
        end

        function raster_all(obj, window)
            window = window*baud;
            spikeSubset = cellfun(@(x) x(x >= window(1) & x < window(2)), obj.spikes, 'uni', 0);
            numNeurons = numel(obj.spikes);
            for n = 1:numNeurons
                h = figure;
                rasterplot(spikeSubset{n}, )
        end

        function binnedSpikes = bin_spikes(obj, binEdges, binSize)
            edgeStart = binEdges(1)*obj.baud;
            edgeEnd = binEdges(2)*obj.baud;
            stepSize = floor(obj.baud/1000*binSize);
            binEdges = edgeStart:stepSize:edgeEnd;
            for i = 1:numel(obj.spikes)
                binnedSpikes(i, :) = histcounts(obj.spikes{i}, 'BinEdges', binEdges);
            end
        end

        function stepwiseAll = corn_mono(obj)
            binSize = 1;        %ms
            corrWidth = 50;     %ms
            wideVals = corrWidth - 10;
            numSeconds = floor(obj.frames/obj.baud);
            numNeurons = numel(obj.spikes);
            binnedSpikes = obj.bin_spikes([0 numSeconds], binSize);
            stepwiseAll = cell(numNeurons);
            for ref = 1:numNeurons
                target = ref+1;
                while target <= numNeurons
                    fullCorr = xcorr(binnedSpikes(ref, :), binnedSpikes(target, :), )
                    stepwiseCorr = zeros(numSeconds, corrWidth*2 + 1);
                    for sec = 1:numSeconds
                        window = (1:1000/binSize) + (sec-1)*1000/binSize;
                        stepwiseCorr(sec, :) = round(xcorr(binnedSpikes(ref, window), ...
                            binnedSpikes(target, window), corrWidth));
                    end
                    stepwiseAll{ref, target} = stepwiseCorr;
                    target = target+1;
                end
            end
        end
        
        function corn_inhib
        end
    end
end