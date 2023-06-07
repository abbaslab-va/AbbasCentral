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
addParameter(p, 'excludeEventsByState', [], @ischar);
parse(p, event, regions, varargin{:});
a = p.Results;

useBpod = a.bpod;

% set up filterbank and downsample signal
baud = obj.info.baud;
sf = 2000;
downsampleRatio = baud/sf;
sigLength = (a.edges(2) - a.edges(1)) * baud/downsampleRatio;
%filterbank= cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency',sf, 'TimeBandwidth',60, 'FrequencyLimits',a.freqLimits, 'VoicesPerOctave', 10);

% timestamp and trialize event times
if useBpod
    eventTimes = obj.find_bpod_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset,'excludeEventsByState',a.excludeEventsByState);
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



for c = 1:numChan
    lfp_all{c}=cellfun(@(x) downsample(lfp(c, x(1):x(2)-1), downsampleRatio), edgeCells, 'uni', 0);
end 


[m,n] = ndgrid(obj.info.regions.(a.regions(1)),obj.info.regions.(a.regions(2)));
Z = [m(:),n(:)];
    
for combo=1:size(Z,1)
      cxy=cellfun(@(x,y) mscohere(x,y,a.window,a.overlap,[a.freqLimits(1):a.freqLimits(2)],sf),lfp_all{Z(combo,1)},lfp_all{Z(combo,2)},'uni',0);
      cxy_band(combo)=mean(cellfun(@(x) mean(x),cxy,'uni',1));    
end 

cohere=mean(cxy_band);

disp(obj.info.path)