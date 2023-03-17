function [ppc, spikePhase] = ppc(obj, event, varargin)

disp(obj.info.path)
% INPUT:
%     event - a string of a state named in the config file (required)
%     name-value pairs:
%         > 'edges' - 1x2 vector distance from event on either side in seconds (optional)
%         > 'freqLimits' - a 1x2 vector specifying cwt frequency limits (optional)
%         > 'averaged' - a boolean specifying if the trials should be averaged together (default = false)
%         > 'calculatePhase' - boolean specifying if phase should be calculated (default = true)
%         > 'trialTypes' - a 1xN vector specifying which trial types to calculate for (default = all)

% default input values
defaultEdges = [-2 2];
defaultFreqLimits = [1 120];
defaultAveraged = false;
defaultPhase = true;
defaultOutcome = [];            % all outcomes
defaultTrialType = [];          % all TrialTypes
defaultOffset = 0;              % offset from event in seconds


% input validation scheme
p =  inputParser;
validVectorSize = @(x) all(size(x) == [1, 2]);
validField = @(x) ischar(x) || isempty(x);
addRequired(p, 'event', @ischar);
addParameter(p, 'edges', defaultEdges, validVectorSize);
addParameter(p, 'freqLimits', defaultFreqLimits, validVectorSize);
addParameter(p, 'averaged', defaultAveraged, @islogical);
addParameter(p, 'calculatePhase', defaultPhase, @islogical);
addParameter(p, 'trialType', defaultTrialType, @isvector);
addParameter(p, 'outcome', defaultOutcome, validField);
addParameter(p, 'offset', defaultOffset, @isnumeric);
parse(p, event, varargin{:});
a = p.Results;

baud = obj.info.baud;

% timestamp and trialize event times
eventTimes = obj.find_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset);
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
   ppc=zeros(numChan,numSpikes);
   spikePhase=cell(numChan,numSpikes);
   ppc(:)=NaN;
   [spikePhase{:}]=deal(NaN);
   return
end

for c=1:numChan
    % calculate phase
    chanPhase= cellfun(@(x) angle(hilbert(bandpass(lfp(c, x(1):x(2)-1), a.freqLimits, baud))), edgeCells, 'uni', 0);
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

% find significant ppc 
sigPhase= cellfun(@(x) circ_rtest(x),spikePhase);

% make nonsignificant ppc NaN
ppc=cellfun(@(x) mean(nonzeros(triu(cos(x.'-x),1))),spikePhase);

ppc(sigPhase>0.05)=NaN;