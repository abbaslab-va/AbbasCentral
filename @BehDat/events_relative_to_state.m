function [eventTimes, eventNames, stateNames] = events_relative_to_state(obj, stateName, varargin)

[bpodEventTimes, eventNames, stateNames] = obj.bpod.events_relative_to_state(stateName, varargin{:});
presets = PresetManager(varargin{:});
eventTimes = obj.bpod_to_blackrock(bpodEventTimes, presets);