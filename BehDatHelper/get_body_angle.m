function bodyAngles = get_body_angle(coordMat)

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
bodyLine = coordMat(:, [11 12]) - coordMat(:, [7 8]);
thetaBody = cart2pol(bodyLine(:, 1), bodyLine(:, 2));
thetaBody(useCenter) = thetaCenter(useCenter);
bodyAngles = unwrap(thetaBody);
% bodyAngles(useCenter) = angleCenter(useCenter);