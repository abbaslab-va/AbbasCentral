function sig_ppc_delta(obj, presetPre, presetPost)
firingRates = extractfield(obj.spikes, 'fr');
presetCells = find(obj.spike_subset(presetPre));
presetFiringRates = firingRates(presetCells);
[ppcPre, sigCellsPre] = obj.spa_ppc('preset', presetPre);
[ppcPost, sigCellsPost] = obj.spa_ppc('preset', presetPost);
preAndPost = cellfun(@(y, z) y & z, sigCellsPre, sigCellsPost, 'uni', 0);
idxPre = cellfun(@(x) find(x), sigCellsPre, 'uni', 0);
idxPost = cellfun(@(x) find(x), sigCellsPost, 'uni', 0);
commonCells = cellfun(@(y, z) intersect(y, z), idxPre, idxPost, 'uni', 0);
commonIdxPre = cellfun(@(y, z) ismember(y, z), idxPre, commonCells, 'uni', 0);
commonIdxPost = cellfun(@(y, z) ismember(y, z), idxPost, commonCells, 'uni', 0);
ppcSigPre = cellfun(@(y, z) y(z), ppcPre, commonIdxPre, 'uni', 0);
ppcSigPost = cellfun(@(y, z) y(z), ppcPost, commonIdxPost, 'uni', 0);
uniqueCells = unique(cat(2, commonCells{:}));
numCells = numel(uniqueCells);
numBins = numel(ppcSigPre);
freqRad = linspace(-pi, pi, numBins + 1);
xCoords = zeros(1, numBins);
yCoords = zeros(1, numBins);
for f = 1:numBins
    currentAngle = freqRad(f);
    xCoords(f) = cos(currentAngle)/100;
    yCoords(f) = sin(currentAngle)/100;
end
for n = 1:numCells
    cellIdx = uniqueCells(n);
    xCoordsPre = zeros(1, numBins);
    yCoordsPre = zeros(1, numBins);
    xCoordsPost = zeros(1, numBins);
    yCoordsPost = zeros(1, numBins);
    for f = 1:numBins
        currentAngle = freqRad(f);
        cellPreIdx = find(idxPre{f} == cellIdx);
        if isempty(cellPreIdx)
            preScale = 0;
        else
            preScale = ppcPre{f}(cellPreIdx);
        end
        cellPostIdx = find(idxPost{f} == cellIdx);
        if isempty(cellPostIdx)
            postScale = 0;
        else
            postScale = ppcPost{f}(cellPostIdx);
        end
        xCoordsPre(f) = cos(currentAngle) * preScale;
        xCoordsPost(f) = cos(currentAngle) * postScale;
        yCoordsPre(f) = sin(currentAngle) * preScale;
        yCoordsPost(f) = sin(currentAngle) * postScale;
    end
    figure
    hold on
    mapshow(xCoords, yCoords, 'DisplayType', 'polygon', 'FaceColor', 'black')
    mapshow(xCoordsPre, yCoordsPre, 'DisplayType', 'polygon', 'FaceColor', 'r', 'FaceAlpha', .6);
    mapshow(xCoordsPost, yCoordsPost, 'DisplayType', 'polygon', 'FaceColor', 'b', 'FaceAlpha', .6);
    title(sprintf("Firing rate: %f Hz", presetFiringRates(cellIdx)))
    maxVal = max(abs([xCoordsPre, xCoordsPost, yCoordsPre, yCoordsPost, xCoords, yCoords]));
    xlim([-maxVal maxVal])
    ylim([-maxVal maxVal])
    axis square
end
disp('poop')

