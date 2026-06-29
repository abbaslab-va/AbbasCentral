function [filteredLFP, regions] = lfp_rms_filtered(obj, varargin)

% This method returns the full session lfp with rms filtering. 
% OUTPUT:
%     filteredLFP - a 1xS array of lfp datapoints, or a cell array if multiple regions are specified.
%     regions - string or cell array of region strings
% INPUT:
%     region - a string or cell array of region strings
%     channels - a vector containing channels to consider when making rms comparisons
%     baud - the desired sampling rate of the downsampled lfp. Defaults to 2000 Hz

presets = PresetManager(varargin{:});

filepath = obj.info.path;
[~, folder] = fileparts(filepath);
ns6Path = fullfile(filepath, [folder, '.ns6']);
ns6 = openNSx(ns6Path);

if ~isempty(presets.region)
    regionChan = {obj.info.channels.(presets.region)};
    regions = presets.region;
else
    regionChan = cellfun(@(x) obj.info.channels.(x), fields(obj.info.channels), 'uni', 0);
    regions = fields(obj.info.channels);
end

if ~isempty(presets.channels)
    validChannels = cellfun(@(x) intersect(presets.channels, x), regionChan, 'uni', 0);
else
    validChannels = regionChan;
end

rawData = cellfun(@(x) double(ns6.Data(x, :)), validChannels, 'uni', 0);
clear ns6
rmsVals = cellfun(@(x) rms(x, 2), rawData, 'uni', 0);
lowestRMS = cellfun(@(x) find(x == min(x)), rmsVals, 'uni', 0);
rawData = cellfun(@(x, y) x(y, :), rawData, lowestRMS, 'uni', 0);

[B, A] = butter(2, 150/(obj.info.baud/2));
filteredLFP = cellfun(@(x) filtfilt(B, A, x), rawData, 'uni', 0);
skipFactor = obj.info.baud / presets.baud;
filteredLFP = cellfun(@(x) downsample(x, skipFactor), filteredLFP, 'uni', 0);