function load_LabGym_positions(obj, varargin)
% Extracts positional data from xlsx files output by LabGym
    pathContents = dir(obj.info.path);
    contentsIsDir = [pathContents.isdir];
    contentsName = extractfield(pathContents, 'name');
    validName = cellfun(@(x) ~contains(x, '.'), contentsName);
    dirIdx = contentsIsDir & validName;
    dirNames = contentsName(dirIdx);
    % unholy regex to get time string from filename as output by e3vision.
    % ask an ai how it works
    vidTimes = cellfun(@(x) regexp(x, '-(?<match>[^-_\n]+)_[^_]*$', 'names'), dirNames, 'uni', 0);
    vidTimes = cellfun(@(x) str2num(x.match), vidTimes);
    [~, vidIdx] = sort(vidTimes);
    numVids = numel(vidIdx);
    positions = [];
    for i = 1:numVids
        currentIdx = vidIdx(i);
        vidName = fullfile(obj.info.path, dirNames{currentIdx}, 'animal_centers.xlsx');
        vidData = readtable(vidName);
        centers = vidData.Var2(2:end);   % this is how LabGym names it
        % more unholy regex to parse LabGym's weird spreadsheet
        centers = cellfun(@(x) regexp(x, '\d*\.\d*|\d+', 'match'), centers, 'uni', 0);
        centers = cellfun(@(x) cellfun(@(y) str2num(y), x, 'uni', 0), centers, 'uni', 0);
        centers = cellfun(@(x) cat(2, x{:}), centers, 'uni', 0);
        centers(cellfun(@(x) isempty(x), centers)) = deal({[0, 0]});
        positions = [positions; cat(1, centers{:})];
    end
    obj.coordinates = positions(1:numel(obj.video.frameTimes), :);
end