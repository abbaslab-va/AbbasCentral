function [pwr, freqs, phase] = cwt_power(obj, event, edges, freqLimits, averaged)


% INPUT:
%     event - a string of a state named in the config file
%     edges - 1x2 vector distance from event on either side in seconds
%     freqLimits - a 1x2 vector specifying cwt frequency limits

if ~exist('averaged', 'var')
    averaged = false;
end

calculatePhase = true;
if nargout < 3
    calculatePhase = false;
end

baud = obj.info.baud;
sf = 2000;
downsampleRatio = baud/sf;
sigLength = (edges(2) - edges(1)) * baud/downsampleRatio;
filterbank= cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency',sf, 'TimeBandwidth',60, 'FrequencyLimits',freqLimits, 'VoicesPerOctave', 10);  
eventTimes = round(obj.find_event(event));
% eventTimes = round(obj.find_event(event)/downsampleRatio);
% edges = (edges * baud/downsampleRatio) + eventTimes';
edges = (edges * baud) + eventTimes';
edgeCells = num2cell(edges, 2);
[parentDir, sub] = fileparts(obj.info.path);
NS6 = openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')));
lfp = double(NS6.Data);
% lfp = downsample(lfp', downsampleRatio)';
% norm = rms(lfp, 2)
clear NS6

numChan = size(lfp, 1);
pwr = cell(1, numChan);
phase = cell(1, numChan);
tic
for c = 1:numChan
    [AS,f] = cellfun(@(x) cwt(downsample(lfp(c, x(1):x(2)-1), downsampleRatio), 'FilterBank', filterbank), edgeCells, 'uni', 0);
    
    chanPower = cellfun(@(x) flip(abs(x).^2, 1), AS, 'uni', 0);
    chanPower = cat(3, chanPower{:});
%     pwr{c} = mean(chanPower, 3);
    pwr{c} = chanPower;
    if calculatePhase
        chanPhase = cellfun(@(x) flip(angle(x), 1), AS, 'uni', 0);
        chanPhase = cat(3, chanPhase{:});
%         phase{c} = mean(chanPhase, 3);
        phase{c} = chanPhase;
    end
end
toc
freqs = flip(f{c});

if averaged
    pwr = cellfun(@(x) mean(x, 3), pwr, 'uni', 0);
end