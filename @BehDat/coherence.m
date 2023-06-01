function cohere = coherence(obj, event, regions, varargin)

% Calculates the coherence of two LFP signals using a mscohere
% and returns the power and phase of the signal at the specified frequencies.
% OUTPUT:
%     cohere - a CxCxE matrix of magnitude-squared coherence estimate
%     freqs - a array of frequencies used in the mscohere
% INPUT:
%     event - a string of a state named in the config file (required)
%     regions - a 1x2 cell array of strings of regions named in the config file (required)
% optional name-value pairs:
%     > 'edges' - 1x2 vector distance from event on either side in seconds
%     > 'freqLimits' - a 1x2 vector specifying frequency limits
%     > 'trialType' - a trial type found in config.ini
%     > 'outcome' - an outcome character array found in config.ini
%     > 'offset' - a number that defines the offset from the alignment you wish to center around.
%     > 'window' - Window, specified as an integer or as a row or column vector. Use window to divide the signal into segments

% default input values
defaultWindow= 2000;
defaultOverlap = 1000;


% input validation scheme
p = parse_BehDat('event', 'edges', 'freqLimits', 'trialType', 'outcome', 'offset', 'bpod');
addParameter(p, 'window', defaultWindow, @isnumeric);
addParameter(p, 'overlap', defaultOverlap, @isnumeric);
addRequired(p, 'regions', @iscell);
parse(p, event, regions, varargin{:});
a = p.Results;

useBpod = a.bpod;
regions=a.regions;
% set up filterbank and downsample signal
baud = obj.info.baud;
sf = 2000;
downsampleRatio = baud/sf;
sigLength = (a.edges(2) - a.edges(1)) * baud/downsampleRatio;
%filterbank= cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency',sf, 'TimeBandwidth',60, 'FrequencyLimits',a.freqLimits, 'VoicesPerOctave', 10);

% timestamp and trialize event times
if useBpod
    eventTimes = obj.find_bpod_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset);
else
    eventTimes = obj.find_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset);
end

try
    a.edges = (a.edges * baud) + eventTimes';
    edgeCells = num2cell(a.edges, 2);
catch
    %pwr = [];
    %phase = [];
    %freqs = [];
    return
end
% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);
NS6 = openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')));
lfp = double(NS6.Data);
% norm = rms(lfp, 2)                % uncomment to RMS normalize lfp
clear NS6
numChan = size(lfp, 1);
%pwr = cell(1, numChan);
%phase = cell(1, numChan);

% calculate power and phase
for c = 1:numChan-1
    lfp_all{c}=cellfun(@(x) downsample(lfp(c, x(1):x(2)-1), downsampleRatio), edgeCells, 'uni', 0);
    disp(num2str(c))
end 
%freqs = flip(f{1});

if a.averaged
   % pwr = cellfun(@(x) mean(x, 3), pwr, 'uni', 0);
    %phase = cellfun(@(x) mean(x, 3), phase, 'uni', 0);
    lfp_all = cellfun(@(x) mean(cell2num(x)), lfp_all, 'uni', 0);
end



disp(obj.info)