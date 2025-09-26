function downsampledData = downsample_lfp(obj, presets, sampleRate)


baud = obj.info.baud;
if ~exist('sampleRate', 'var')
    sampleRate = 2000;
end
skipFactor = obj.info.baud / sampleRate;

eventTimes = obj.find_event('preset', presets, 'trialized', false);
eventEdges = (presets.edges * baud) + eventTimes';
edgeCells = num2cell(eventEdges, 2);
timeStrings = cellfun(@(x) strcat('t:', num2str(x(1)), ':', num2str(x(2) - 1)), edgeCells, 'uni', 0);
% navigate to subject folder and load LFP
[parentDir, sub] = fileparts(obj.info.path);
ns6Dir = dir(fullfile(parentDir, sub,'*.ns6'));
NS6 = cellfun(@(x) openNSx(fullfile(parentDir, sub, ns6Dir.name), x, strcat('s:', num2str(skipFactor))), timeStrings, 'uni', 0);
downsampledData = cellfun(@(x) double(x.Data)', NS6, 'uni', 0);
if ~isempty(presets.channels)
    downsampledData = cellfun(@(x) x(:, presets.channels), downsampledData, 'uni', 0);
end
