function [eventNames, eventInds] = map_bpod_events(eventNumbers)

inputNumbers = 69:84;
eventInds = ismember(eventNumbers, inputNumbers);
eventNumbers = eventNumbers(ismember(eventNumbers, inputNumbers));
eventNumberCells = num2cell(eventNumbers);
inputNumberCell = num2cell(inputNumbers);
outputEvents = {'Port1In', 'Port1Out', 'Port2In', 'Port2Out', 'Port3In', 'Port3Out',...
    'Port4In', 'Port4Out', 'Port5In', 'Port5Out', 'Port6In', 'Port6Out',...
    'Port7In', 'Port7Out', 'Port8In', 'Port8Out'};
eventMap = containers.Map(inputNumberCell, outputEvents);
eventNames = cellfun(@(x) eventMap(x), eventNumberCells, 'uni', 0);
