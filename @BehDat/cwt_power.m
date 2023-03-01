function [pwr, freqs, phase, eventTrialTypes, eventOutcomes] = cwt_power(obj, event, varargin)


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
defaultTrialTypes = 1:max(obj.bpod.TrialTypes);

% input validation scheme
p =  inputParser;
validVectorSize = @(x) all(size(x) == [1, 2]);
addRequired(p, 'event', @ischar);
addParameter(p, 'edges', defaultEdges, validVectorSize);
addParameter(p, 'freqLimits', defaultFreqLimits, validVectorSize);
addParameter(p, 'averaged', defaultAveraged, @islogical);
addParameter(p, 'calculatePhase', defaultPhase, @islogical);
addParameter(p, 'trialTypes', defaultTrialTypes, @isvector);
parse(p, event, varargin{:});
a = p.Results;

% set up filterbank and downsample signal
baud = obj.info.baud;
sf = 2000;
downsampleRatio = baud/sf;
sigLength = (a.edges(2) - a.edges(1)) * baud/downsampleRatio;
filterbank= cwtfilterbank('SignalLength', sigLength, 'SamplingFrequency',sf, 'TimeBandwidth',60, 'FrequencyLimits',a.freqLimits, 'VoicesPerOctave', 10);

% timestamp and trialize event times
eventTimes = round(obj.find_event(a.event));
eventTrials = discretize(eventTimes, [obj.timestamps.trialStart obj.info.samples]);
eventTrialTypes = obj.bpod.TrialTypes(eventTrials);
eventOutcomes = obj.bpod.SessionPerformance(eventTrials);
trials = find(ismember(eventTrialTypes, a.trialTypes));
eventTimes = eventTimes(trials);
eventTrialTypes = eventTrialTypes(trials);
eventOutcomes = eventOutcomes(trials);
a.edges = (a.edges * baud) + eventTimes';
edgeCells = num2cell(a.edges, 2);

% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);
NS6 = openNSx(fullfile(parentDir, sub, strcat(sub, '.ns6')));
lfp = double(NS6.Data);
% norm = rms(lfp, 2)
clear NS6
numChan = size(lfp, 1);
pwr = cell(1, numChan);
phase = cell(1, numChan);

% calculate power and phase
for c = 1:numChan
    [AS,f] = cellfun(@(x) cwt(downsample(lfp(c, x(1):x(2)-1), downsampleRatio), 'FilterBank', filterbank), edgeCells, 'uni', 0);
    chanPower = cellfun(@(x) flip(abs(x).^2, 1), AS, 'uni', 0);
    chanPower = cat(3, chanPower{:});
    pwr{c} = chanPower;
    if a.calculatePhase
        chanPhase = cellfun(@(x) flip(angle(x), 1), AS, 'uni', 0);
        chanPhase = cat(3, chanPhase{:});
        phase{c} = chanPhase;
    end
end
freqs = flip(f{c});

if a.averaged
    pwr = cellfun(@(x) mean(x, 3), pwr, 'uni', 0);
    phase = cellfun(@(x) mean(x, 3), phase, 'uni', 0);
end