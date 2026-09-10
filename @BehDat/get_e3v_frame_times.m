function get_e3v_frame_times(obj, bncData)

% This function was written to find the timestamps in the acquisition 
% system's sampling rate for video recorded using the e3vision watchtower.
% Pulses are 10% of a frame when video is streaming but not saving,
% increasing to 50% when saving commences.
% 
% INPUT:
%     bncData - a vector from NS6.Data, typically channel 33 or 34. Not
%     standardized currently, depends on which analog in is used on the
%     cereplex direct, which this method was initially built for.

% Voltage peaks around 20000, but the rise time often exceeds the length of
% a duty cycle at 30000 hz. The cutoff of 2000 is somewhat arbitrary but
% won't provide any false negatives.
if strcmp(obj.info.acquisition, 'blackrock')

    if ~exist("bncData", 'var')
        % assumes microwire 32 channel drives with video on 33
        filepath = obj.info.path;
        [~, folder] = fileparts(filepath);
        ns6Path = fullfile(filepath, [folder, '.ns6']);
        ns6 = openNSx(ns6Path);
        bncData = ns6.Data(33, :);
    end
    bncHi = find(diff(bncData) > 1500);
    hiDiff = diff(bncHi);
    bncLo = find(diff(bncData) < -1500);
    loDiff = diff(bncLo);
    
    % Remove indices that are consecutive
    badHi = find(hiDiff == 1) + 1;
    bncHi(badHi) = [];
    badLo = find(loDiff == 1) + 1;
    bncLo(badLo) = [];
    % Find the distance between hi and lo, keep only those that exceed 400
    % samples (at 30000 hz, this is slightly less than half of a frame at 30
    % hz)
    if numel(bncHi) > numel(bncLo)
        bncHi(end) = [];
    elseif numel(bncLo) > numel(bncHi)
        bncLo(end) = [];
    end
    bncDiff = bncLo - bncHi;
    savedFrames = bncHi(bncDiff > 400);
elseif strcmp(obj.info.acquisition, 'OpenEphys')

    savedFrames = find(diff(bncData) > 1000 & bncData(1:end-1) < 300);
end
obj.video.frameTimes = savedFrames;

