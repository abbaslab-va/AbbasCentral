function [lfpChan, chanPhaseMat]= lfp_align(obj, event, varargin)

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
goodEvent = @(x) isempty(x) || ischar(x);
defaultAveraged = false;
defaultPhase = false;

% input validation scheme
p = parse_BehDat('event', 'edges', 'freqLimits', 'trialType', 'outcome', 'offset', 'bpod');
addParameter(p, 'averaged', defaultAveraged, @islogical);
addParameter(p, 'phase', defaultPhase, @islogical);
addParameter(p, 'excludeEventsByState', [], goodEvent);
parse(p, event, varargin{:});
a = p.Results;

useBpod = a.bpod;

% set up filterbank and downsample signal
baud = obj.info.baud;
sf = 2000;
downsampleRatio = baud/sf;
%sigLength = (a.edges(2) - a.edges(1)) * baud/downsampleRatio;
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
    return
end
% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);
NS6 = openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')));
lfp = double(NS6.Data);
% norm = rms(lfp, 2)                % uncomment to RMS normalize lfp
clear NS6
numChan = size(lfp, 1);



% for butter
nyquist=sf/2;
N = 2;
[B, A] = butter(N, a.freqLimits/(nyquist));

%pwr = cell(1, numChan);
%chanPhase = cell(1, numChan);

% calculate power and phase
if a.phase 
    for c = 1:numChan
        lfpChan=cellfun(@(x) downsample(lfp(c, x(1):x(2)-1), downsampleRatio), edgeCells, 'uni', 0);
        chanPhase= cellfun(@(x) angle(hilbert(filtfilt(B, A, x))), lfpChan, 'uni', 0);
        chanPhaseMat(:,c,:)=cell2mat(chanPhase);
        %lfp_allmat(:,c,:)=lfpChan;
        %disp(num2str(c));
        lfp_all=NaN;
    end 
 
else
    lfpChan= cell(1, numChan);
    for c = 1:numChan
        lfpChan{c}=cellfun(@(x) downsample(lfp(c, x(1):x(2)-1), downsampleRatio), edgeCells, 'uni', 0);
        lfpChan{c}= cellfun(@(x) filtfilt(B, A, x), lfpChan{c}, 'uni', 0);
        %disp(num2str(c));
    end
end 
%freqs = flip(f{1});

if a.averaged
   % pwr = cellfun(@(x) mean(x, 3), pwr, 'uni', 0);
    %phase = cellfun(@(x) mean(x, 3), phase, 'uni', 0);
    lfp_all = cellfun(@(x) mean(cell2num(x)), lfpChan, 'uni', 0);
end



disp(obj.info.path)