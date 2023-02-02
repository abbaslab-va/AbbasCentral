function [expSessions, metadata] = select_experiment(parentFolder)
%Loads data into a class array from the main experimental directory.
%Metadata is stored in a separate variable not yet written
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
%concatenate session behavioral and neural data into an array of BehDat
%objects
ctr = 1;
% for sub = 1:numel(subFolders)
for sub = 1:3           %Temporary solution while lacking write access
    subFolder = subFolders(sub).folder;
    subName = subFolders(sub).name;
    sessionFolders=dir(fullfile(parentFolder,subName));
    sDirs = {sessionFolders.name}';
    sessionFolders(~[sessionFolders.isdir]' | startsWith(sDirs, '.')) = []; 
    for sess=1:numel(sessionFolders)
        Fullpath = fullfile(parentFolder, subName, sessionFolders(sess).name);
        expSessions(ctr) = populate_BehDat(Fullpath, subName, I.timestamps);
        ctr = ctr + 1;
    end 
end

metadata.subjects = subNames;
metadata.path = parentFolder;
try
    metadata.experimenter = I.experimenter.x_Experimenter;
catch
    metadata.experimenter = "";
end
