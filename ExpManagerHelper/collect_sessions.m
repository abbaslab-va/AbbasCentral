function newExperiment = collect_sessions(expPath, dirFolders)

% This is the first function to be called when utilizing the ExpManager
% class. It creates an object that can manage all behavioral sessions and
% the associated metadata.
% 
% INPUT:
%     expPath - path to data as specified in README
%     dirFolders - indices of folders in path to use (optional)

if ~exist('dirFolders', 'var')
    [expSessions, expMetadata] = select_experiment(expPath);
else
    [expSessions, expMetadata] = select_experiment(expPath, dirFolders);
end
newExperiment = ExpManager(expSessions, expMetadata);
% arrayfun(@(x) x.find_mono, newExperiment.sessions);