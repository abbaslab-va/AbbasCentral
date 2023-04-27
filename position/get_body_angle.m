function bodyAngles = get_body_angle(coordMat)

% This function needs cleaning up still - it does not select by consensus,
% and instead uses the vector from skull to nose.
% OUTPUT: 
%     bodyAngles - an Nx1 vector of unwrapped angles throughout the video,
%     where N is the number of frames
%     bodyAnglesWrapped - same as bodyAngles but wrapped between -pi:pi
% INPUT:
%     coordMat - a csv from DLC with the most current settings

earLine = coordMat(:, [5 6]) - coordMat(:, [3 4]);
thetaEars = cart2pol(earLine(:, 1), earLine(:, 2));
centerLine = coordMat(:, [7 8]) - coordMat(:, [1 2]);
thetaCenter = cart2pol(centerLine(:, 1), centerLine(:, 2));
angleCenter = unwrap(thetaCenter);
headCrossAngle = thetaCenter - thetaEars;
withinTolerance = headCrossAngle < -1.5*pi + .2 & headCrossAngle > -1.5*pi - .2;
headCrossAngle(withinTolerance) = headCrossAngle(withinTolerance) + 2*pi;
rightAngle = 0.5*pi;
useCenter = headCrossAngle < rightAngle + .2 & headCrossAngle > rightAngle - 2;
% mid back compared to skull seems to work best for now
bodyLine1 = coordMat(:, [11 12]) - coordMat(:, [7 8]);
thetaBody1 = cart2pol(bodyLine1(:, 1), bodyLine1(:, 2));
% bodyAngles = unwrap(thetaBody1);
bodyLine2 = coordMat(:, [11 12]) - coordMat(:, [9 10]);
thetaBody2 = cart2pol(bodyLine2(:, 1), bodyLine2(:, 2));
% bodyAngles = unwrap(thetaBody2);
bodyLine3 = coordMat(:, [9 10]) - coordMat(:, [7 8]);
bodyAnglesWrapped = cart2pol(bodyLine3(:, 1), bodyLine3(:, 2));
bodyAngles = unwrap(bodyAnglesWrapped);

% consensusAngles = [bodyAngles1, bodyAngles2, bodyAngles3];
% bodyAngles = unwrap(thetaCenter);
% thetaBody(useCenter) = thetaCenter(useCenter);
% bodyAngles(useCenter) = angleCenter(useCenter);
