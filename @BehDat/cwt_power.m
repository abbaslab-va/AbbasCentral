function [pwr, phase, freqs] = cwt_power(obj, event, edges, freqLimits)
baud = obj.info.baud;
sf = 2000;
downsampleRatio = baud/sf;
sigLength = (edges(2) - edges(1)) * baud/downsampleRatio;
filterbank= cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency',sf, 'TimeBandwidth',60, 'FrequencyLimits',freqLimits, 'VoicesPerOctave', 10);  
eventTimes = round(obj.find_event(event)/downsampleRatio);
edges = (edges * baud/downsampleRatio) + eventTimes';
edgeCells = num2cell(edges, 2);
[parentDir, sub] = fileparts(obj.info.path);
NS6 = openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')));
lfp = double(NS6.Data);
lfp = downsample(lfp', downsampleRatio)';
% norm = rms(lfp, 2);
clear NS6
numChan = size(lfp, 1);
pwr = cell(1, numChan);
phase = cell(1, numChan);

for c = 1:numChan
    [AS,f] = cellfun(@(x) cwt(lfp(c, x(1):x(2)-1), 'FilterBank', filterbank), edgeCells, 'uni', 0);
    chanPower = cellfun(@(x) flip(abs(x).^2, 1), AS, 'uni', 0);
    chanPower = cat(3, chanPower{:});
    chanPhase = cellfun(@(x) angle(x), AS, 'uni', 0);
    chanPhase = cat(3, chanPhase{:});
    pwr{c} = mean(chanPower, 3);
%     phase{c} = mean(chanPhase, 3);
    phase{c} = chanPhase;
end

freqs = f{c};
