%% Create objects for all sessions in an experiment
[ClaSessions, ClaMetadata] = select_experiment;

%% Select a subset of those objects

mySub = ClaMetadata.subjects{1};
mySubIdx = arrayfun(@(x) strcmp(x.name, mySub), ClaSessions);
mySubSessions = ClaSessions(mySubIdx);

%% Perform functions on many objects

arrayfun(@(x) x.plot_outcome, mySubSessions);
meanZ = arrayfun(@(x) x.z_score('Trial_Start', [0 5], 'Laser_On', [-2 2], 50), ClaSessions, 'uni', 0);