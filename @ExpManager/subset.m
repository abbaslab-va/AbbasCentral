function sessionIdx = subset(obj, varargin)
% Finds logical intersections of sessions based on variable inputs.
% Operates according to PresetManager fields
% OUTPUT:
%     sessionIdx- a logical vector of session indices
% INPUT:
% optional name/value pairs:
%     'animals' - 1x2 vector distance from event on either side in seconds
%     'condition' - a number that defines the bin size in ms
%     'includeSessions' - a trial type found in config.ini
%     'excludeSessions' - an outcome character array found in config.ini

presets = PresetManager(varargin{:});
animals = presets.animal;
conditions = presets.condition;
includeSessions = presets.includeSessions;
excludeSessions = presets.excludeSessions;
numSessions = numel(obj.sessions);
includeAll = true(1, numSessions);

if isempty(animals)
    animalIdx = includeAll;
elseif ischar(animals)
    animalIdx = arrayfun(@(x) contains(x.info.path, ['\' animals '\']), obj.sessions);
elseif iscell(animals)
    animalIdx = cellfun(@(x) arrayfun(@(y) contains(y.info.path, ['\' x '\']), obj.sessions), animals, 'uni', 0);
    animalIdx = cat(1, animalIdx{:});
    animalIdx = any(animalIdx, 1);
end

if isempty(conditions)
    conditionIdx = includeAll;
elseif ischar(conditions)
    conditionIdx = arrayfun(@(x) contains(x.info.condition, conditions), obj.sessions);
elseif iscell(conditions)
    conditionIdx = cellfun(@(x) arrayfun(@(y) contains(y.info.condition, x), obj.sessions), conditions, 'uni', 0);
    conditionIdx = cat(1, conditionIdx{:});
    conditionIdx = any(conditionIdx, 1);
end

if isempty(includeSessions)
    includeIdx = includeAll;
else
    includeIdx = ismember(1:numSessions, includeSessions);
end

if isempty(excludeSessions)
    excludeIdx = ~includeAll;
else
    excludeIdx = ismember(1:numSessions, excludeSessions);
end

sessionIdx = (animalIdx & conditionIdx & ~excludeIdx) | includeIdx;

