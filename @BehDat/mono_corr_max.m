function maxVals = mono_corr_max(obj, corrCells, region1, region2)

% INPUT:
%     corrCells - the output from calling obj.xcorr
%     region1 - a string of a region named in config.ini
%     region2 - a string of a region named in config.ini (optional)

if ~exist('region2', 'var')
    region2 = region1;
end

refCells = cellfun(@(x) strcmp(x, region1), extractfield(obj.spikes, 'region'));
targetCells = cellfun(@(x) strcmp(x, region2), extractfield(obj.spikes, 'region'));
corrSubset = cellfun(@(x) x(refCells, targetCells), corrCells, 'uni', 0);
nonEmptyCells = cellfun(@(x) ~cellfun(@isempty, x), corrSubset, 'uni', 0);
corrMat = cellfun(@(x, y) x(y), corrSubset, nonEmptyCells, 'uni', 0);
corrMat = cellfun(@(x) cat(1, x{:}), corrMat, 'uni', 0);

peakVals = cellfun(@(x) x(:, 8:10), corrMat, 'uni', 0);
maxVals = cat(3, peakVals{:});
