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

lfp = obj.downsample_lfp(presets, 2000);

% norm = rms(lfp, 2)                % uncomment to RMS normalize lfp
N = 2;
[B, A] = butter(N, presets.freqLimits/(baud/2));

if strcmp(filter, 'butter')
    filteredLFP = cellfun(@(x) filtfilt(B, A, x), lfp, 'uni', 0); 
else
    filteredLFP = cellfun(@(x) bandpass(x, presets.freqLimits, baud), lfp, 'uni', 0);
end