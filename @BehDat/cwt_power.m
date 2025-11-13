function [pwr, freqs, phase, lfpAll] = cwt_power(obj, varargin)

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
validSF = @(x) isnumeric(x) && x > 0 && x < obj.info.baud;
validOutputOpts = {'quiet', 'verbose', 'q', 'v'};
validOutput = @(x) any(cellfun(@(y) strcmp(x, y), validOutputOpts));

% input validation scheme
presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'averaged', defaultAveraged, @islogical);
addParameter(p, 'calculatePhase', defaultPhase, @islogical);
addParameter(p, 'samplingFreq', defaultSF, validSF);
addParameter(p, 'outputStyle', 'quiet', validOutput)
parse(p, varargin{:});    
averaged = p.Results.averaged;
trialized = presets.trialized;
calculatePhase = p.Results.calculatePhase;
samplingFreq = p.Results.samplingFreq;
outputStyle = p.Results.outputStyle;
% set up filterbank and downsample signal
baud = obj.info.baud;
downsampleRatio = baud/samplingFreq;
sigLength = (presets.edges(2) - presets.edges(1)) * samplingFreq;
filterbank = cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency', samplingFreq, 'TimeBandwidth',60, 'FrequencyLimits',presets.freqLimits, 'VoicesPerOctave', 10);


% lfpDownsampled = obj.downsample_lfp(presets, samplingFreq);

try
    numChan = obj.info.numChannels;
    % numChan = numel(presets.channels);
catch 
    warning('No channel num found (likely due to noPhy - setting to 32 (default value)).')
    numChan = 32;
end
lfpAll = cell(1, numChan);
% timestamp and trialize event times
eventTimes = obj.find_event('preset', presets, 'trialized', false);

try
    edgeVec = round(presets.edges * baud) + eventTimes';
    edgeCells = num2cell(edgeVec, 2);
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
    AS = cellfun(@(x) flip(abs(x).^2, 1), AS, 'uni', 0);
    % clear AS
    pwr{c} = single(cat(3, AS{:}));
    if strcmp(outputStyle, 'verbose')
        disp(num2str(c))
    end
end 
freqs = freqs{1};

if averaged
    pwr = cellfun(@(x) mean(x, 3), pwr, 'uni', 0);
    phase = cellfun(@(x) mean(x, 3), phase, 'uni', 0);
    lfpAll = cellfun(@(x) mean(cell2mat(x)), lfpAll, 'uni', 0);
    trialized = false;
end

if trialized
    pwrMat = cat(4, pwr{:});
    clear pwr
    pwrReshape = num2cell(pwrMat, [1 2 4]);
    clear pwrMat
    pwr = squeeze(cellfun(@(x) squeeze(x), pwrReshape, 'uni', 0));
end

if strcmp(outputStyle, 'verbose')
    disp(obj.info)
end