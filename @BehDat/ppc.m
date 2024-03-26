function [ppcAll, spikePhase, ppcSig] = ppc(obj,varargin)

% INPUT:
%     event - a string of a state named in the config file (required)
%     name-value pairs:
%         > 'edges' - 1x2 vector distance from event on either side in seconds (optional)
%         > 'freqLimits' - a 1x2 vector specifying cwt frequency limits (optional)
%         > 'averaged' - a boolean specifying if the trials should be averaged together (default = false)
%         > 'calculatePhase' - boolean specifying if phase should be calculated (default = true)
%         > 'trialTypes' - a 1xN vector specifying which trial types to calculate for (default = all)

disp(obj.info.path);
% default input values
defaultFilter = 'butter';
defaultScramble = 0; 
defaultBuffer = 1; 
obj.info.numChannels=32;

% input validation scheme
presets=PresetManager(varargin{:});
p=inputParser();
p.KeepUnmatched=true;

% input validation scheme
addParameter(p, 'filter', defaultFilter, @ischar);
addParameter(p, 'scramble', defaultScramble, @isnumeric);
addParameter(p, 'buffer', defaultBuffer, @isnumeric);
parse(p, varargin{:});


filter = p.Results.filter;
scramble = p.Results.scramble;
buffer = p.Results.buffer;
useBpod = presets.bpod;
baud = obj.info.baud;

% timestamp and trialize event times
if useBpod
    eventTimes = obj.find_bpod_event('preset',presets);
else
    eventTimes = obj.find_event('preset',presets);
end
presets.edges = (presets.edges * baud) + eventTimes';
edgeCells = num2cell(presets.edges, 2);
numEvents = numel(edgeCells);
numNeurons = length(obj.spikes);
numChan = obj.info.numChannels;
[parentDir, sub] = fileparts(obj.info.path);

%check is num event is less than three, if true populate with nans 
if numel(edgeCells) < 3
   ppcAll = zeros(numChan, numNeurons);
   spikePhase = cell(numChan, numNeurons);
   ppcAll(:) = NaN;
   ppcSig = ppcAll;
   [spikePhase{:}] = deal(NaN);
   return
end

% FIR filter and butter
nyquist = baud/2;
N = 2;
[B, A] = butter(N, presets.freqLimits/(nyquist));


% if 64GB ram or less. you will run out of memory with more than 200
% events. subsampling events below 
if numEvents > 200
    edgeCells = randsample(edgeCells,200);
    numEvents = 200;
end 

if scramble
    offsetScram = zeros(1, numEvents);
    for e = 1:numEvents
        offsetScram(e) = randsample(1:0.1:scramble, 1) * baud;
    end
    offsetScram=num2cell(offsetScram)';
    edgeCellsS=cellfun(@(x,y) x + y, offsetScram, edgeCells,'uni',0);


edgeCellsLfp = cellfun(@(x) [x(1) - (buffer*baud) x(2) + (buffer*baud)], edgeCellsS, 'uni', 0);
timeStrings = cellfun(@(x) strcat('t:', num2str(x(1)), ':', num2str(x(2) - 1)), edgeCellsLfp, 'uni', 0);
NS6 = cellfun(@(x) openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')), x), timeStrings, 'uni', 0);
lfp = cellfun(@(x) double(x.Data)', NS6, 'uni', 0);

numChan = NS6{1}.MetaTags.ChannelCount;
spikePhase=cell(numChan,numNeurons);
clear NS6

else 
edgeCellsLfp = cellfun(@(x) [x(1) - (buffer*baud) x(2) + (buffer*baud)], edgeCells, 'uni', 0);
timeStrings = cellfun(@(x) strcat('t:', num2str(x(1)), ':', num2str(x(2) - 1)), edgeCellsLfp, 'uni', 0);
NS6 = cellfun(@(x) openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')), x), timeStrings, 'uni', 0);
lfp = cellfun(@(x) double(x.Data)', NS6, 'uni', 0);

numChan = NS6{1}.MetaTags.ChannelCount;
spikePhase=cell(numChan,numNeurons);
clear NS6
end 

% calculate phase
if strcmp(filter, 'butter')
    chanSig = cellfun(@(x) filtfilt(B, A, x), lfp, 'uni', 0);
else
    chanSig = cellfun(@(x) bandpass(x, presets.freqLimits, baud), lfp, 'uni', 0);
end
chanPhase = cellfun(@(x) angle(hilbert(x)), chanSig, 'uni', 0);
chanPhase = cellfun(@(x) x(buffer*baud:(end-buffer*baud)-1, :), chanPhase, 'uni', 0)';

for n=1:length(obj.spikes)
    % find spike times around event and zero to start of event
    spikes = cellfun(@(x) obj.spikes(n).times(find(obj.spikes(n).times>x(1) & obj.spikes(n).times<x(2))), edgeCells,'uni',0');
    spikesZeroed = cellfun(@(x,y) (x-y(1))', spikes, edgeCells,'uni',0)';
    % index spike times to LFP
    spikePhaseTemp = cellfun(@(x,y) x(y, :), chanPhase, spikesZeroed,'uni' ,0) ;
    spikePhaseTemp = cat(1,spikePhaseTemp{:});
    spikePhaseChan = num2cell(spikePhaseTemp, 1);
    for c = 1:numChan
        if isempty(spikePhaseChan{c})
            spikePhase{c,n}=NaN;
        else
            spikePhase{c,n}= spikePhaseChan{c};
        end 
    end
end 

%nan cells with less than 100 spikes
for row=1:size(spikePhase,1)
    for col=1:size(spikePhase,2)
        if numel(spikePhase{row,col})<100
            spikePhase{row,col}=NaN;
        else 
        end 
    end 
end 

% find significant phase distributions 
sigPhase= cellfun(@(x) circ_rtest(x),spikePhase);

%calculate ppc
 ppcAll=cellfun(@(x) mean(nonzeros(triu(cos(x.'-x),1))),spikePhase);

% make nonsignificant ppc NaN
ppcSig=ppcAll;
ppcSig(sigPhase>0.05)=NaN;

%%  
% %plot spike phase 
% for n=1:size(spikePhase,2)
%     if any(isnan(spikePhase{1,n}))
%     else
%     for ch=1:32
%         figure()
%         polarhistogram(spikePhase{ch,n},72)
%     end 
%     end
%     pause() 
%     close all
% end 
%% Check if this is working 

% for n=1:length(obj.spikes)
%     % find spike times around event and zero to start of event
%     spikes = cellfun(@(x) obj.spikes(n).times(find(obj.spikes(n).times>x(1) & obj.spikes(n).times<x(2))), edgeCells,'uni',0');
%     spikesZeroed = cellfun(@(x,y) (x-y(1))', spikes, edgeCells,'uni',0)';
%     % index spike times to LFP
%     spikePhaseTemp = cellfun(@(x,y) x(y, :), chanPhase, spikesZeroed,'uni' ,0) ;
%     spikePhaseTemp = cat(1,spikePhaseTemp{:});
%     spikePhaseChan = num2cell(spikePhaseTemp, 1);
% 
%     ch=1;
%     for event=1:length(spikesZeroed)
%         if ~isempty(spikesZeroed{event})
%         figure()
%         hold on
%         subplot(211)
%         plot(chanSig{event}(:,ch))
%         xline(spikesZeroed{event})
%         subplot(212)
%         else 
%         end 
%     end 
% 
% 
%     for c = 1:numChan
%         if isempty(spikePhaseChan{c})
%             spikePhase{c,n}=NaN;
%         else
%             spikePhase{c,n}= spikePhaseChan{c};
%         end 
%     end
% end 
