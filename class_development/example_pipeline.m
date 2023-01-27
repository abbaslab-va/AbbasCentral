%% Create objects for all sessions in an experiment
[ClaSessions, ClaMetadata] = select_experiment;

%% Select a subset of those objects

mySub = ClaMetadata.subjects{1};
mySubIdx = arrayfun(@(x) strcmp(x.name, mySub), ClaSessions);
mySubSessions = ClaSessions(mySubIdx);

%% Perform functions on many objects

arrayfun(@(x) x.plot_outcome, mySubSessions)