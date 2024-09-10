function bpodSessions = make_BpodParser_array(parentFolder, taskName, indices)

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
    %concatenate session behavioral and neural data into an array of BehDat objects
    ctr = 1;
    if ~exist('indices', 'var')
        indices = 1:numel(subFolders);
    end
    for s = 1:numel(indices)
        sub = indices(s);
        subName = subFolders(sub).name;
        sessionFolders=dir(fullfile(parentFolder,subName));
        sDirs = {sessionFolders.name}';
        sessionFolders(~[sessionFolders.isdir]' | startsWith(sDirs, '.')) = []; 
        if exist('taskName', 'var')
            taskNames = extractfield(sessionFolders, 'name');
            taskFolder = cellfun(@(x) strcmp(taskName, x), taskNames);
        else
            taskFolder = ones(numel(sessionFolder));
        end
        for task = find(taskFolder)
            taskPath = fullfile(parentFolder, subName, sessionFolders(task).name, '*.mat');
            taskDir = dir(taskPath);
            for sess = 1:numel(taskDir)
                filePath = fullfile(taskDir(sess).folder, taskDir(sess).name);
                bpodSessions(ctr) = make_BpodParser_obj(filePath, subName, I);
                ctr = ctr + 1;
            end
        end 
    end
end

function parser = make_BpodParser_obj(sessPath, n, ini)
    info = struct('path', sessPath, 'name', n, 'trialTypes', ini.trialTypes, 'outcomes', ini.outcomes, 'startState', ini.info.StartState);
    bpodSession = load(sessPath);
    parser = BpodParser('session', bpodSession.SessionData, 'config', info);
end