function parser = parse_BehDat(varargin)

% This function in the BehDatHelper will provide a single-stop utility to 
% add the typical parameters into a BehDat method's call to inputParser.
% 
% OUTPUT:
%     parser - the structure output of inputParser, using the below inputs
% INPUT:
%     'event' - an event character vector found in the config.ini file. Defaults to be required input to parser
%     'neuron' - number to index a neuron as organized in the spikes field. Defaults to be required input to parser for now
%     'edges' - 1x2 vector distance from event on either side in seconds
%     'offset' - a number that defines the offset from the alignment you wish to center around
%     'binWidth' - an optional parameter to specify the bin width, in ms. default value is 1
%     'trialType' - a trial type defined in config.ini
%     'outcome' - an outcome defined in config.ini
%     'trials' - a vector of trial numbers to include in the analysis
%     'panel' - a panel number to include in the analysis
%     'bpod' - a boolean to indicate whether to use the TTL (false) or bpod (true) timestamps

defaultEdges = [-2 2];          % seconds
defaultOffset = 0;              % offset from event in seconds
defaultBinWidth = 1;            % ms
defaultTrialType = [];          % all TrialTypes
defaultOutcome = [];            % all outcomes
defaultTrials = [];             % all trials
defaultBpod = false;            % Dictates which find_event script is used
defaultFreqLimits = [1 120];
defaultPanel = [];
parser = inputParser;

validVectorSize = @(x) all(size(x) == [1, 2]);
validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validTrials = @(x) isempty(x) || isvector(x);
validNumber = @(x) isnumeric(x) && x > 0;
for i = 1:numel(varargin)
    switch varargin{i}
        case 'event'
            addRequired(parser, 'event', @ischar);
        case 'neuron'
            addRequired(parser, 'neuron', validNumber);
        case 'edges'
            addParameter(parser, 'edges', defaultEdges, validVectorSize);
        case 'offset'
            addParameter(parser, 'offset', defaultOffset, @isnumeric);
        case 'binWidth'
            addParameter(parser, 'binWidth', defaultBinWidth, validNumber);
        case 'trialType'
            addParameter(parser, 'trialType', defaultTrialType, validField);
        case 'outcome'
            addParameter(parser, 'outcome', defaultOutcome, validField);
        case 'trials'
            addParameter(parser, 'trials', defaultTrials, validTrials);
        case 'panel'
            addParameter(parser, 'panel', defaultPanel);
        case 'bpod'
            addParameter(parser, 'bpod', defaultBpod, @islogical);
        case 'freqLimits'
            addParameter(parser, 'freqLimits', defaultFreqLimits, validVectorSize);
    end
end