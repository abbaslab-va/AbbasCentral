function [pwr, freqs, phase, lfpAll] = cwt_power(obj, event, varargin)

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
defaultPhase = false;
defaultSF = 2000;
validStates = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validSF = @(x) isnumeric(x) && x > 0 && x < obj.info.baud;
% input validation scheme
p = parse_BehDat('event', 'edges', 'freqLimits', 'trialType', 'outcome', 'offset', 'bpod');
addParameter(p, 'averaged', defaultAveraged, @islogical);
addParameter(p, 'calculatePhase', defaultPhase, @islogical);
addParameter(p, 'withinState', [], validStates)
addParameter(p, 'excludeEventsByState', [], @ischar);
addParameter(p, 'samplingFreq', defaultSF, validSF);
parse(p, event, varargin{:});
a = p.Results;
withinState = a.withinState;
useBpod = a.bpod;
calculatePhase = a.calculatePhase;

% set up filterbank and downsample signal
baud = obj.info.baud;
downsampleRatio = baud/a.samplingFreq;
sigLength = (a.edges(2) - a.edges(1)) * a.samplingFreq;
filterbank= cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency',a.samplingFreq, 'TimeBandwidth',60, 'FrequencyLimits',a.freqLimits, 'VoicesPerOctave', 10);
try
    numChan = obj.info.numChannels;
catch 
    warning('No channel num found (likely due to noPhy - setting to 32 (default value)).')
    numChan = 32;
end
lfpAll = cell(1, numChan);
% timestamp and trialize event times
if useBpod
    eventTimes = obj.find_bpod_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset, 'withinState', withinState,'excludeEventsByState',a.excludeEventsByState);
else
    eventTimes = obj.find_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset);
end

try
    a.edges = (a.edges * baud) + eventTimes';
    edgeCells = num2cell(a.edges, 2);
catch
    pwr = [];
    phase = [];
    freqs = [];
    return
end
% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);

timeStrings = cellfun(@(x) strcat('t:', num2str(x(1)), ':', num2str(x(2) - 1)), edgeCells, 'uni', 0);
ns6_dir = dir(fullfile(parentDir, sub,'*.ns6'));
NS6 = cellfun(@(x) openNSx(fullfile(parentDir, sub, ns6_dir.name), x), timeStrings, 'uni', 0);
lfp = cellfun(@(x) double(x.Data)', NS6, 'uni', 0);
clear NS6
pwr = cell(1, numChan);
phase = cell(1, numChan);
freqs = cell(1, numChan);

lfpDownsampled = cellfun(@(x) downsample(x, downsampleRatio), lfp, 'uni', 0);
clear lfp
% calculate power and phase
parfor c = 1:numChan
    [AS, f] = cellfun(@(x) cwt(x(:, c), 'FilterBank', filterbank), lfpDownsampled, 'uni', 0);
    if calculatePhase
        chanPhase = cellfun(@(x) flip(angle(x), 1), AS, 'uni', 0);
        chanPhase = cat(3, chanPhase{:});
        phase{c} = chanPhase;
    end
    freqs{c} = flip(f{1});
    chanPower = cellfun(@(x) flip(abs(x).^2, 1), AS, 'uni', 0);
%     clear AS
    pwr{c} = single(cat(3, chanPower{:}));
    disp(num2str(c))
end 
freqs = freqs{1};
if a.averaged
    pwr = cellfun(@(x) mean(x, 3), pwr, 'uni', 0);
    phase = cellfun(@(x) mean(x, 3), phase, 'uni', 0);
    lfpAll = cellfun(@(x) mean(cell2mat(x)), lfpAll, 'uni', 0);
end



disp(obj.info)