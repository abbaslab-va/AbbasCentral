function stateEdges = find_bpod_state(obj, stateName, varargin)
 
% OUTPUT:
%     stateEdges - a 1xN cell array of state edges where N is the number of trials.
% 
% INPUTS:
%     stateName - a name of a bpod state to find edges for in the acquisition system's sampling rate
% optional name/value pairs:
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers to include

presets = PresetManager(varargin{:});



p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'returnFirst', false, @islogical)     % returns next unmatched event type (input in  gives next out)


parse(p, varargin{:});
returnFirst= p.Results.returnFirst;



stateEdgesBpod = obj.bpod.state_times(stateName, 'preset', presets);

if returnFirst
    stateEdgesBpod=cellfun(@(x) x(1),stateEdgesBpod,'uni',false)';
end 

stateEdges = obj.bpod_to_blackrock(stateEdgesBpod, presets);