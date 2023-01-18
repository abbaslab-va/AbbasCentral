classdef NeurDat < BehDat
    properties
        spikes
        lfp
    end

    methods
        function obj = NeurDat(sp)
            obj.spikes = sp;
        end
%         function obj = NeurDat(sp, lf)
%             obj.spikes = sp;
%             obj.lfp = lf;
%         end
        function binnedSpikes = bin_spikes(obj, binEdges, binSize)
            edgeStart = binEdges(1)*obj.baud;
            edgeEnd = binEdges(2)*obj.baud;
            stepSize = floor(obj.baud/1000*binSize);
            binEdges = edgeStart:stepSize:edgeEnd;
            for i = 1:numel(obj.spikes)
                binnedSpikes(i, :) = histcounts(obj.spikes{i}, 'BinEdges', binEdges);
            end
        end

        function corn_mono
        end
        
        function corn_inhib
        end
    end
end