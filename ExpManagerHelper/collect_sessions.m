function newExperiment = collect_sessions(expPath, dirFolders)

% This is the first function to be called when utilizing the ExpManager
% class. It creates an object that can manage all behavioral sessions and
% the associated metadata.
% 
% INPUT:
%     expPath - path to data as specified in README
%     dirFolders - indices of folders in path to use (optional)


[expSessions, expMetadata] = select_experiment(expPath, dirFolders);
newExperiment = ExpManager(expSessions, expMetadata);