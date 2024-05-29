function sessionIdx = subset(obj, varargin)
    
    validInput = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
    p = inputParser;
    addParameter(p, 'animal', [], validInput)
    addParameter(p, 'condition', [], validInput)
    parse(p, varargin{:});
    animals = p.Results.animal;
    conditions = p.Results.condition;

    if isempty(animals)
        animalIdx = true(1, numel(obj.sessions));
    elseif ischar(animals)
        animalIdx = arrayfun(@(x) contains(x.info.path, animals), obj.sessions);
    elseif iscell(animals)
        animalIdx = cellfun(@(x) arrayfun(@(y) contains(y.info.path, x), obj.sessions), animals, 'uni', 0);
        animalIdx = cat(1, animalIdx{:});
        animalIdx = any(animalIdx, 1);
    end

    if isempty(conditions)
        conditionIdx = true(1, numel(obj.sessions));
    elseif ischar(conditions)
        conditionIdx = arrayfun(@(x) contains(x.info.condition, conditions), obj.sessions);
    elseif iscell(conditions)
        conditionIdx = cellfun(@(x) arrayfun(@(y) contains(y.info.condition, x), obj.sessions), conditions, 'uni', 0);
        conditionIdx = cat(1, conditionIdx{:});
        conditionIdx = any(conditionIdx, 1);
    end

    sessionIdx = animalIdx & conditionIdx;
end
