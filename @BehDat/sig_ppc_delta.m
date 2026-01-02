function ppcStruct = sig_ppc_delta(obj, presetPre, presetPost)
% Will make one plot per neuron in a BehDat session that had any
% significant ppc according to spa_ppc. -pi rep
    colorScheme = brewermap(2, 'RdGy');
    preColor = colorScheme(2, :);
    postColor = colorScheme(1, :);
    firingRates = extractfield(obj.spikes, 'fr');
    presetCells = find(obj.spike_subset(presetPre));
    presetFiringRates = firingRates(presetCells);
    [ppcPre, sigCellsPre, fStepsPre] = obj.spa_ppc('preset', presetPre);
    [ppcPost, sigCellsPost, ~] = obj.spa_ppc('preset', presetPost);
    ppcStruct.vals.pre = ppcPre;
    ppcStruct.vals.post = ppcPost;
    ppcStruct.cells.pre = sigCellsPre;
    ppcStruct.cells.post = sigCellsPost;
    ppcStruct.freqs = fStepsPre;
    idxPre = cellfun(@(x) find(x), sigCellsPre, 'uni', 0);
    idxPost = cellfun(@(x) find(x), sigCellsPost, 'uni', 0);
    commonCells = cellfun(@(y, z) intersect(y, z), idxPre, idxPost, 'uni', 0);
    emptyFreqs = cellfun(@(x) isempty(x), commonCells);
    [commonCells{emptyFreqs}] = deal([]);
    uniqueCells = unique(cat(2, commonCells{:}));
    numBins = numel(commonCells);
    numCells = numel(uniqueCells);
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
        figure
        hold on 
        mapshow(xCoords, yCoords, 'DisplayType', 'polygon', 'FaceColor', 'black')
        textH = cell(1, numBins);
        for f = 1:numBins
            currentAngle = freqRad(f);
            nextAngle = freqRad(f + 1);
            preScale = get_scale(idxPre{f}, cellIdx, ppcPre{f});
            postScale = get_scale(idxPost{f}, cellIdx, ppcPost{f});
            xBase = [0, cos(currentAngle), cos(nextAngle)];
            yBase = [0, sin(currentAngle), sin(nextAngle)];
    
            xPre = xBase * preScale;
            xPost = xBase * postScale;
            yPre = yBase * preScale;
            yPost = yBase * postScale;
            mapshow(xPre, yPre, 'DisplayType', 'polygon', 'FaceColor', preColor, 'FaceAlpha', .6);
            mapshow(xPost, yPost, 'DisplayType', 'polygon', 'FaceColor', postColor, 'FaceAlpha', .6);
            xCoordsPre(f) = cos(currentAngle) * preScale;
            xCoordsPost(f) = cos(currentAngle) * postScale;
            yCoordsPre(f) = sin(currentAngle) * preScale;
            yCoordsPost(f) = sin(currentAngle) * postScale;

            textH{f} = text(xCoords(f) * 1.2, yCoords(f) * 1.2, sprintf("%.2f", fStepsPre(f)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        end
        legend('.01', 'pre', 'post')
        lastH = text(xCoords(1) * 1.4, yCoords(1) * 1.4, sprintf("%.2f", fStepsPre(end)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        title(sprintf("Region: %s, Condition: %s, Firing rate: %f Hz", presetPre.region, obj.info.condition, presetFiringRates(cellIdx)))
        maxVal = max(abs([xCoordsPre, xCoordsPost, yCoordsPre, yCoordsPost, xCoords, yCoords]));
        % fontsize(floor(20 * (1.03 - maxVal * 3)), 'points')
        fontsize(16, 'points')
        for i = 1:numel(textH)
            currentH = textH{i};
            set(currentH, 'Position', currentH.Position * max(maxVal/.01 * ((maxVal - .01)/maxVal), 1))
        end
        set(lastH, 'Position', textH{1}.Position - [.005, 0, 0])
        limits = [-maxVal - .01, maxVal + .01];
        xlim(limits)
        ylim(limits)
        axis square
    end
end

function scale = get_scale(idx, currentIdx, ppc)
    scaleIdx = find(idx == currentIdx);
    if isempty(scaleIdx)
        scale = 0;
    else
        scale = ppc(scaleIdx);
    end
end
     