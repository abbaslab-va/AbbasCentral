function ITPC = itpc(obj, event, varargin)

% Calculates the power of a signal using a continuous wavelet transform
% and returns the power and phase of the signal at the specified frequencies.
% OUTPUT:
%     pwr - a 1xC cell array of power values for each channel
%     freqs - a 1xC cell array of frequencies used in the cwt
%     phase - a 1xC cell array of phase values for each channel
% INPUT:
%     event - a string of a state named in the config file (required)
% optional name-value pairs:
%     > 'edges' - 1x2 vector distance from event on either side in seconds
%     > 'freqLimits' - a 1x2 vector specifying cwt frequency limits
%     > 'averaged' - a boolean specifying if the trials should be averaged together (default = false)
%     > 'calculatePhase' - boolean specifying if phase should be calculated (default = true)
%     > 'trialType' - a trial type found in config.ini
%     > 'outcome' - an outcome character array found in config.ini
%     > 'offset' - a number that defines the offset from the alignment you wish to center around.

% default input values
defaultAveraged = false;
defaultPhase = true;
defaultFilter = 'bandpass';

% input validation scheme
p = parse_BehDat('event', 'edges', 'freqLimits', 'trialType', 'outcome', 'offset', 'bpod');
addParameter(p, 'filter', defaultFilter, @ischar);
parse(p, event, varargin{:});
a = p.Results;

useBpod = a.bpod;

% set up filterbank and downsample signal
baud = obj.info.baud;
sf = 2000;
downsampleRatio = baud/sf;
sigLength = (a.edges(2) - a.edges(1)) * baud/downsampleRatio;
filterbank= cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency',sf, 'TimeBandwidth',60, 'FrequencyLimits',a.freqLimits, 'VoicesPerOctave', 10);

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
    itpc = [];
 
    return
end
% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);
NS6 = openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')));
lfp = double(NS6.Data);
% norm = rms(lfp, 2)                % uncomment to RMS normalize lfp
clear NS6
numChan = size(lfp, 1);
phase = cell(1, numChan);
nyquist=baud/2;


% for butter
N = 2;
[B, A] = butter(N, a.freqLimits/(nyquist));

    % calculate phase


% calculate power and phase
for c = 1:numChan
    if strcmp(a.filter, 'butter')
        chanPhase= cellfun(@(x) angle(hilbert(filtfilt(B, A, lfp(c, x(1):x(2)-1)))), edgeCells, 'uni', 0);
   
    else
        chanPhase= cellfun(@(x) angle(hilbert(bandpass(lfp(c, x(1):x(2)-1), a.freqLimits, baud))), edgeCells, 'uni', 0);
    end
    %itpc=
    disp(num2str(c))
end 

chanPhase



disp(obj.info)