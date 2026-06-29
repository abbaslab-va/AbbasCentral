function pokeRate = continuous_poke_rate(obj, varargin)

% Returns the binned port rate within an event window. 
% OUTPUT:
%     pokeRate - a 1xE cell array where E is the number of events.
%     Each cell contains a 1xB vector of poke rates, where B is the number of bins
%     (duration of edges / bin width)
% INPUT:
%     'event' - the event to bin pokes around
%     'edges' - the window surrounding the event
%     'binWidth' - granularity of the poke rate (ms)

presets = PresetManager(varargin{:});
if isempty(presets.ports)
    ports = 1:5;
else
    ports = presets.ports;
end
edges = presets.edges * obj.info.baud;
portsIn = ['Port[', arrayfun(@(x) num2str(x), ports), ']In'];
eventTimes = obj.find_event('preset', presets, 'trialized', true);
hasEvent = cellfun(@(x) ~isempty(x), eventTimes);
windowTimes = cellfun(@(x) edges + x, eventTimes(hasEvent), 'uni', 0);
pokeTimes = obj.find_event('event', portsIn, 'bpod', true, 'trialized', true);
pokesInWindow = cellfun(@(x, y) ~isnan(discretize(x, y)), pokeTimes(hasEvent), windowTimes, 'uni', 0);
validPokes = cellfun(@(x, y) x(y), pokeTimes(hasEvent), pokesInWindow, 'uni', 0);
eventEdges = cellfun(@(x) round(presets.edges * obj.info.baud) + x, eventTimes, 'uni', 0);
binWidth = presets.binWidth / 1000 * obj.info.baud;
eventBins = cellfun(@(x) x(1):binWidth:x(2), eventEdges, 'uni', 0);
pokesPerBin = cellfun(@(x, y) histcounts(x, y), validPokes, eventBins, 'uni', 0);
pokeRate = cellfun(@(x) x * presets.binWidth / 1000, pokesPerBin, 'uni', 0);
