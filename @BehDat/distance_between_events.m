function eventDist = distance_between_events(obj, event1, event2, varargin)

% This method calculates the time elapsed between the two events inputted,
% which are events named in the config.ini.
% OUTPUT:
%     eventDist - a 1xT cell array of samples elapsed between event1 and event2,
%     or a 1xE vector if trialized is set to false
% INPUT:
%     variable name/value pairs from PresetManager class
%     trialType
%     outcome
%     stimType
%     offset

presets = PresetManager(varargin{:});

event1Times = obj.find_event('event', event1, 'preset', presets, 'trialized', true);
event2Times = obj.find_event('event', event2, 'preset', presets, 'trialized', true);

eventDist = cellfun(@(x, y) x - y, event2Times, event1Times, 'uni', 0);

if ~presets.trialized
    eventDist = cat(2, eventDist{:});
end