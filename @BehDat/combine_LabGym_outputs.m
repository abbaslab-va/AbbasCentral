function combinedOutput = combine_LabGym_outputs(obj, metric)

% OUTPUT:
    % combinedOutput - a 1xN vector of values corresponding to the variable
    % specified by metric, where N is the number of video frames.
% INPUT:
    % metric - a string to specify the parameter to combine csv files for

metric = lower(metric);
validMetrics = {"acceleration", "intensity_area", "magnitude_area", ...
    "probability", "speed", "velocity", "vigor"};
metricFileNames = {"animal_}
metricMap = containers.Map(validMetrics, metricFileNames)
combinedOutput = 0;