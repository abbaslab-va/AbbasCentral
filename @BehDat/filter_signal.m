function filteredLFP = filter_signal(obj, event, freqLimits, varargin)

% OUTPUT:
%     filteredLFP - a cell array where each cell holds the trialized filtered LFP signal for that channel
% INPUT:
%     event - a string of a state named in the config file
%     freqLimits - a 1x2 vector specifying filter frequency limits
% optional name-value pairs:
%     > 'edges' - 1x2 vector distance from event on either side in seconds (optional)
%     > 'trialType' - a 1xN vector specifying which trial types to calculate for (default = all)
%     > 'outcome' - an outcome character array found in config.ini
%     > 'offset' - a number that defines the offset from the alignment you wish to center around.
%     > 'bpod' - a boolean specifying if the bpod event should be used (default = false)
%     > 'filter' - a string specifying the type of filter to use (default = 'bandpass', alternate = 'butter')

% default input values
tic
defaultEdges = [-2 2];
defaultTrialType = [];          % all TrialTypes
defaultOutcome = [];            % all outcomes
defaultOffset = 0;              % offset from event in seconds
defaultBpod = false;
defaultFilter = 'bandpass';

% input validation scheme
p =  inputParser;
validVectorSize = @(x) all(size(x) == [1, 2]);
validField = @(x) ischar(x) || isempty(x);

addRequired(p, 'event', @ischar);
addRequired(p, 'freqLimits', validVectorSize);
addParameter(p, 'edges', defaultEdges, validVectorSize);
addParameter(p, 'trialType', defaultTrialType, validField);
addParameter(p, 'outcome', defaultOutcome, validField);
addParameter(p, 'offset', defaultOffset, @isnumeric);
addParameter(p, 'bpod', defaultBpod, @islogical)
addParameter(p, 'filter', defaultFilter, @ischar);
parse(p, event, freqLimits, varargin{:});
a = p.Results;
baud = obj.info.baud;

% timestamp and trialize event times
if a.bpod
    eventTimes = obj.find_bpod_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset);
else
    eventTimes = obj.find_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset);
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
filteredLFP = cell(1, numChan);
N = 2;
[B, A] = butter(N, a.freqLimits/(baud/2));
for c=1:numChan
%     calculate phase (minimum order filter)

    if strcmp(a.filter, 'butter')
        filteredSignal = cellfun(@(x) filtfilt(B, A, lfp(c, x(1):x(2)-1)), edgeCells, 'uni', 0);
    else
        filteredSignal = cellfun(@(x) bandpass(lfp(c, x(1):x(2)-1), a.freqLimits, baud), edgeCells, 'uni', 0);
    end
    filteredLFP{c} = cat(1, filteredSignal{:});

    
end
toc