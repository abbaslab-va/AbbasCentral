function rotatedCoords = rotate_coordinate_data(cData, rotCenter, rotAmount)

% This function accepts a cell array of coordinate data, output from the
% BehDat method plot_centroid, and returns the points in the same format
% but rotated around rotCenter by rotAmount.

xS = cellfun(@(x) x(:, 1) - rotCenter(1), cData, 'uni', 0);
yS = cellfun(@(y) y(:, 2) - rotCenter(2), cData, 'uni', 0);
xSr = cellfun(@(x, y) x*cos(rotAmount) + y*sin(rotAmount), xS, yS, 'uni', 0);
ySr = cellfun(@(x, y) -x*sin(rotAmount) + y*cos(rotAmount), xS, yS, 'uni', 0);
xR = cellfun(@(x) x + rotCenter(1), xSr, 'uni', 0);
yR = cellfun(@(y) y + rotCenter(2), ySr, 'uni', 0);
rotatedCoords = cellfun(@(x, y) [x y], xR, yR, 'uni', 0);