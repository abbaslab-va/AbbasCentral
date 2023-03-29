function bodyAngles = get_body_angle(coordMat)

% earLine = obj.coordinates(:, [5 6]) - obj.coordinates(:, [3 4]);
% [thetaEars, rho] = cart2pol(earLine(:, 1), earLine(:, 2));
% angleEars = unwrap(thetaEars);
% 
% centerLine = obj.coordinates(:, [7 8]) - obj.coordinates(:, [1 2]);
% [thetaCenter, rho] = cart2pol(centerLine(:, 1), centerLine(:, 2));
% angleCenter = unwrap(thetaCenter);

% mid back compared to skull seems to work best for now
bodyLine = coordMat(:, [11 12]) - coordMat(:, [7 8]);
[thetaBody, rho] = cart2pol(bodyLine(:, 1), bodyLine(:, 2));
bodyAngles = unwrap(thetaBody);

