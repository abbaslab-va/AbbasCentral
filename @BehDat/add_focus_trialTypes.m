function add_focus_trialTypes(obj)

% This function finds trials in the FoCuS task where the animal attained a 
% forage reward within .5 seconds of the laser.

trials = obj.bpod.RawEvents.Trial;
fieldNames = cellfun(@(x) fields(x.States), trials, 'uni', 0);

graceStateIdx = cellfun(@(x) contains(fields(x.States), 'DrinkGrace'), trials, 'uni', 0);
graceStateNames = cellfun(@(x, y) x(y), fieldNames, graceStateIdx, 'uni', 0);
graceStateTimes = cellfun(@(x, y) cellfun(@(z) x.States.(z), y, 'uni', 0), trials, graceStateNames, 'uni', 0);

laserIdx = cellfun(@(x) strcmp(fields(x.States), 'Laser'), trials, 'uni', 0);
laserStateName = cellfun(@(x, y) x(y), fieldNames, laserIdx, 'uni', 0);
laserStateTimes = cellfun(@(x, y) cellfun(@(z) x.States.(z)(1), y, 'uni', 0), trials, laserStateName);

rewardedTrial = cellfun(@(x, y) any(cellfun(@(z) any(y - z(:, 1) < .75 & y - z(:, 1) > 0), x)), graceStateTimes, laserStateTimes);
trialTypes = obj.bpod.TrialTypes;
rewardedTrialNums = find(rewardedTrial);
laserOnTrials = trialTypes(rewardedTrialNums) < 7;
laserOffTrials = trialTypes(rewardedTrialNums) > 6 & trialTypes(rewardedTrialNums) < 13;
obj.bpod.TrialTypes(rewardedTrialNums(laserOnTrials)) = 17;
obj.bpod.TrialTypes(rewardedTrialNums(laserOffTrials)) = 18;