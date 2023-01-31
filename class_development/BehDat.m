% Base class for objects storing data collected from behavioral experiments
% in the Abbas Lab.

classdef BehDat
    properties
        name
        baud
        frames
        spikes
        lfp
        waveforms
        timestamps
        bpod
    end

    methods
        function obj = BehDat(n, b, f, s, l, w, ts, beh)
            if nargin == 8
                obj.name = n;
                obj.baud = b;
                obj.frames = f;
                obj.spikes = s;
                obj.lfp = l;
                obj.waveforms = w;
                obj.timestamps = ts;
                obj.bpod = beh;
            end
        end

    %% Bpod methods

        function [numTT, numCorrect] = outcomes(obj, val)
            if ~exist('val', 'var')
                val = 1;
            end
            [numTT, numCorrect] = bpod_performance(obj.bpod, val);
        end

        function [f, b, e] = plot_outcome(obj, val, shapeVec)
            if ~exist('val', 'var')
                val = 1;
            end
            [numTT, numCorrect] = bpod_performance(obj.bpod, val);
            if ~exist('shapeVec', 'var')
                shapeVec = numel(numTT);
            end
            [f, b, e] = bar_and_error(numCorrect./numTT, shapeVec);
        end

        function sankey(obj)
            bpod_sankey(obj.bpod)
        end

    %% Spike methods
    
        function timestamps = find_event(obj, event)
            eventString = strcat('x_', event);
            try
                timestamp = obj.timestamps.keys.(eventString);
            catch
                mv = MException('BehDat:MissingVar', sprintf('No timestamp pair found for event %s. Please edit config file and recreate object', event));
                throw(mv)
            end
            timestamps = obj.timestamps.times(obj.timestamps.codes == timestamp);
        end

        function binnedSpikes = bin_spikes(obj, eventEdges, binSize)
            stepSize = floor(obj.baud/1000*binSize);
            binEdges = eventEdges(1):stepSize:eventEdges(2);
            numNeurons = numel(obj.spikes);
            binnedSpikes = zeros(numNeurons, numel(binEdges)-1);
            for i = 1:numNeurons
                binnedSpikes(i, :) = histcounts(obj.spikes(i).times, 'BinEdges', binEdges);
            end
        end

        function [zMean, zCells, trialNum] = z_score(obj, baseline, bWindow, event, eWindow, binWidth)
            baseTimes = obj.find_event(baseline);
            eventTimes = obj.find_event(event);
            numBaseTS = numel(baseTimes);
            numEventTS = numel(eventTimes);
            baseCells = cell(1, numBaseTS);
            zCells = cell(1, numEventTS);
            % Calculate baseline statistics
            for b = 1:numBaseTS
                baseEdges = bWindow .* obj.baud + baseTimes(b);
                baselineTrial = obj.bin_spikes(baseEdges, binWidth);
                baseCells{b}= baselineTrial;
            end
            baseNeurons = cat(2, baseCells{:});
            baseMean = mean(baseNeurons, 2);
            baseSTD = std(baseNeurons, 0, 2);

            for e = 1:numEventTS
                eventEdges = eWindow .* obj.baud + eventTimes(e);
                eventTrial = obj.bin_spikes(eventEdges, binWidth);
                trialZ = (eventTrial - baseMean)./baseSTD;
                zCells{e} = trialZ;
            end

            zAll = cat(3, zCells{:});
            zMean = mean(zAll, 3);
            zMean = smoothdata(zMean, 2, 'gaussian', 5);
        end

        %% LFP Methods
        function calculate_power(obj)
        end
    end
end