function event_sankey(obj, varargin)

% This function outputs a sankey plot showing the transitions between bpod
% events. By default, it displays all event transitions from all trial
% types, but users can use name-value pairs to only analyze certain
% combinations of trial types and outcomes, as well as only transitions to
% or from a certain event. This is a wrapper function for the BpodParser
% event_sankey method.
% 
% optional name/value pairs:
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'inputEvents' - a string or cell array of strings of desired input
%     states to visualize
%     'outputEvents' - a string or cell array of strings of desired output
%     states to visualize

obj.bpod.event_sankey(varargin{:});