function timestamps = find_event(obj, event)

% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector found in the config.ini file

event(event == ' ') = '_';
eventString = strcat('x_', event);
try
    timestamp = obj.timestamps.keys.(eventString);
catch
    mv = MException('BehDat:MissingVar', sprintf('No timestamp pair found for event %s. Please edit config file and recreate object', event));
    throw(mv)
end
timestamps = obj.timestamps.times(obj.timestamps.codes == timestamp);