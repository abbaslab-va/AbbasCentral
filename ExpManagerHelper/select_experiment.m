function [expSessions, metadata] = select_experiment(parentFolder, indices)

% Loads data into a class array from the main experimental directory.
% Metadata is stored in a separate variable. The array and the metadata are
% used to power AbbasCentral.mlapp
% 
% INPUT:
%     parentFolder - a directory pointing to the highest organizational level 
%     of your experiment according to the structure dictated in the docs in readme.md
%     indices - an optional variable indicating which folders you would like to collect data from

if ~exist('parentFolder', 'var')
    parentFolder = uigetdir('Choose a Folder');
end
cd(parentFolder)
iniDir = dir('config.ini');
if isempty(iniDir)
    ie = MException('BehDat:config', 'No file in experiment directory called config.ini');
    throw(ie);
end
I = INI;
I.read('config.ini');
%Get a list of content
subFolders = dir(parentFolder);

%Remove content that isn't a subdirectory
subDirs = {subFolders.name}';
subFolders(~[subFolders.isdir]' | startsWith(subDirs, '.')) = [];
subNames = extractfield(subFolders, 'name');
%concatenate session behavioral and neural data into an array of BehDat objects
ctr = 1;
if ~exist('indices', 'var')
    indices = 1:numel(subFolders);
end
subNames = subNames(indices);
for s = 1:numel(indices)
    sub = indices(s);
    subName = subFolders(sub).name;
    sessionFolders=dir(fullfile(parentFolder,subName));
    sDirs = {sessionFolders.name}';
    sessionFolders(~[sessionFolders.isdir]' | startsWith(sDirs, '.')) = []; 
    for sess=1:numel(sessionFolders)
        Fullpath = fullfile(parentFolder, subName, sessionFolders(sess).name);
        expSessions(ctr) = populate_BehDat(Fullpath, subName, I);
        sessNames{ctr} = sessionFolders(sess).name;
        ctr = ctr + 1;
    end 
end
hasSpikes = arrayfun(@(x) ~isempty(x.spikes), expSessions);
expSessions = expSessions(hasSpikes);
sessNames = sessNames(hasSpikes);
metadata.subjects = subNames;
metadata.path = parentFolder;
metadata.sessions = sessNames;
try
    metadata.experimenter = I.info.experimenter;
catch
    metadata.experimenter = "";
end

