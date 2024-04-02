function filteredLFP = filter_signal(obj, varargin)

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
defaultFilter = 'butter';
presets = PresetManager(varargin{:});
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'filter', defaultFilter, @ischar)
parse(p, varargin{:});
filter = p.Results.filter;
baud = obj.info.baud;

% timestamp and trialize event times
eventTimes = obj.find_event('preset', presets, 'trialized', false);
eventEdges = (presets.edges * baud) + eventTimes';
edgeCells = num2cell(eventEdges, 2);
timeStrings = cellfun(@(x) strcat('t:', num2str(x(1)), ':', num2str(x(2) - 1)), edgeCells, 'uni', 0);
% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);
ns6_dir = dir(fullfile(parentDir, sub,'*.ns6'));
NS6 = cellfun(@(x) openNSx(fullfile(parentDir, sub, ns6_dir.name), x), timeStrings, 'uni', 0);
lfp = cellfun(@(x) double(x.Data)', NS6, 'uni', 0);
clear NS6
% norm = rms(lfp, 2)                % uncomment to RMS normalize lfp
N = 2;
[B, A] = butter(N, presets.freqLimits/(baud/2));

if strcmp(filter, 'butter')
    filteredLFP = cellfun(@(x) filtfilt(B, A, x), lfp, 'uni', 0); 
else
    filteredLFP = cellfun(@(x) bandpass(x, presets.freqLimits, baud), lfp, 'uni', 0);
end