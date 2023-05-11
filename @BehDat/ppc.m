function [ppc_all, spikePhase, ppc_sig] = ppc(obj, event, varargin)

% INPUT:
%     event - a string of a state named in the config file (required)
%     name-value pairs:
%         > 'edges' - 1x2 vector distance from event on either side in seconds (optional)
%         > 'freqLimits' - a 1x2 vector specifying cwt frequency limits (optional)
%         > 'averaged' - a boolean specifying if the trials should be averaged together (default = false)
%         > 'calculatePhase' - boolean specifying if phase should be calculated (default = true)
%         > 'trialTypes' - a 1xN vector specifying which trial types to calculate for (default = all)
tic
disp(obj.info.path)
% default input values
defaultFilter = 'bandpass';


% input validation scheme
p = parse_BehDat('event', 'edges', 'freqLimits', 'trialType', 'outcome', 'trials', 'offset', 'bpod');
addParameter(p, 'filter', defaultFilter, @ischar);
parse(p, event, varargin{:});
a = p.Results;

baud = obj.info.baud;

% timestamp and trialize event times
if a.bpod
    eventTimes = obj.find_bpod_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset, 'trials', a.trials);
else
    eventTimes = obj.find_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset, 'trials', a.trials);
end
a.edges = (a.edges * baud) + eventTimes';
edgeCells = num2cell(a.edges, 2);

% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);
NS6 = openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')));
lfp = double(NS6.Data);
% norm = rms(lfp, 2)                % uncomment to RMS normalize lfp
clear NS6

numChan = size(lfp, 1);
numNeurons=length(obj.spikes);
spikePhase=cell(numChan,numNeurons);

%check is num event is less than three, if true populate with nans 
if numel(edgeCells)<3
   ppc_all=zeros(numChan,numNeurons);
   spikePhase=cell(numChan,numNeurons);
   ppc_all(:)=NaN;
   ppc_sig=ppc_all;
   [spikePhase{:}]=deal(NaN);
   return
end

% for fir filter
nyquist=baud/2;


% for butter
N = 2;
[B, A] = butter(N, a.freqLimits/(nyquist));

for c=1:numChan
    % calculate phase
    if strcmp(a.filter, 'butter')
        chanPhase= cellfun(@(x) angle(hilbert(filtfilt(B, A, lfp(c, x(1):x(2)-1)))), edgeCells, 'uni', 0);
   
    else
        chanPhase= cellfun(@(x) angle(hilbert(bandpass(lfp(c, x(1):x(2)-1), a.freqLimits, baud))), edgeCells, 'uni', 0);
    end


    chanPhase = cat(3, chanPhase{:});
    phase = num2cell(squeeze(chanPhase),1);
    for n=1:length(obj.spikes)
        % find spike times around event and zero to start of event
        spikes= cellfun(@(x) obj.spikes(n).times(find(obj.spikes(n).times>x(1) & obj.spikes(n).times<x(2))), edgeCells,'uni',0');
        spikesZeroed =cellfun(@(x,y) x-y(1),spikes,edgeCells,'uni',0)';
        % index spike times to LFP
        spikePhaseTemp=cellfun(@(x,y) x(y), phase, spikesZeroed,'uni' ,0) ;
        spikePhaseTemp=cat(1,spikePhaseTemp{:});
        if isempty(spikePhaseTemp)
            spikePhase{c,n}=NaN;
        else
            spikePhase{c,n}= spikePhaseTemp;
        end 
    end 
end 

% nan cells with less than 100 spikes
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
ppc_all=cellfun(@(x) mean(nonzeros(triu(cos(x.'-x),1))),spikePhase);

% make nonsignificant ppc NaN
ppc_sig=ppc_all;
ppc_sig(sigPhase>0.05)=NaN;


toc