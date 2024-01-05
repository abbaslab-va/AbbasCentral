function goodTimes = event_within_state(obj, varargin)

validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p = inputParser;
addParameter(p, 'stateName', [], validField);
addParameter(p, 'eventTimes', [], validField);
parse(p, varargin{:})
a = p.Results;
if isempty(a.stateName)
    goodTimes = cellfun(@(x) ones(size(x)), a.eventTimes, 'uni', 0);
    return
end




if ischar(a.stateName) || isstring(a.stateName)
    stateTimes = obj.state_times(a.stateName);
elseif iscell(a.stateName)
    stateTimeCell = cellfun(@(x) obj.state_times(x), a.stateName, 'uni', 0);
    stateTimeCell = cat(1, stateTimeCell{:});
    eventIdx = num2cell(1:numel(a.eventTimes));
    stateTimes = cellfun(@(x) cat(1, stateTimeCell{:,x}),  eventIdx, 'uni', 0);
end

% This double cellfun operates on withinState which contains a cell for each trial,
% with a cell for each state inside of that.
goodTrials = cellfun(@(x) ~isempty(x), a.eventTimes);
goodTimesAll = cellfun(@(x, y) cellfun(@(z)discretize(x, z),y,'uni',0),a.eventTimes(goodTrials), stateTimes(goodTrials), 'uni', 0);
includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
eventCell = cell(size(goodTrials));
[eventCell{goodTrials}] = deal(includeTimes{:});
emptyIdx=cellfun(@(x) isempty(x),includeTimes);
numEvents=cellfun(@(x) numel(x),a.eventTimes,'UniformOutput',false)
fuckShitStack= cellfun(@(x) deal(zeros(1,x)),numEvents(emptyIdx),UniformOutput=false);
count=1;
for f=find(emptyIdx)
    eventCell{f}=fuckShitStack{count};
    count=count+1;
end 

goodTimes = eventCell;
