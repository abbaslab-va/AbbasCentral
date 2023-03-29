function [sessions, metadata] = select_experiment_videos(behaviorDir, videoDir, expName)

% Similar to select_experiment, this function returns an array of BehDat
% objects and a metadata variable. The sessions will contain just a bpod
% file and coordinate data, for experiments with no neural data.
% 
% INPUT:
%     behaviorDir - the directory containing all bpod sessions
%     videoDir - the directory including all video and csv files

I = INI;
I.read(fullfile(videoDir, 'config.ini'));
videoStruct = dir(fullfile(videoDir, '*.avi'));
csvStruct = dir(fullfile(videoDir, '*.csv'));

% The following 2 lines returns the last index of the subject's name according
% to the e3vision camera naming convention
dashes = arrayfun(@(x) strfind(x.name, '-'), videoStruct, 'uni', 0);
endOfName = cellfun(@(x) x(end - 1) - 1, dashes, 'uni', 0);
% Extract the subject's name from the video file using the dash index
nameList = extractfield(videoStruct, 'name')';
nameList = cellfun(@(x, d) x(1:d), nameList, endOfName, 'uni', 0);
nameList = cellfun(@(x) regexprep(x, "_", "-"), nameList, 'uni', 0);
numVids = numel(nameList);
% sessions(numVids) = BehDat;

for sub = numVids:-1:1
    expDate = videoStruct(sub).date(1:11);
    subName = nameList{sub};
    subFolder = fullfile(behaviorDir, subName, expName);
    subSessions = dir(subFolder);
    subSessions = subSessions(3:end);
    matchingDate = arrayfun(@(x) contains(x.date, expDate), subSessions);
    behIdx = find(matchingDate);
    if numel(behIdx) ~= 1
        continue
    end
    bpodSession = load(fullfile(subSessions(behIdx).folder, subSessions(behIdx).name));
%     Read and remove extraneous confidence columns in csv
    csvData = readmatrix(fullfile(csvStruct(sub).folder, csvStruct(sub).name));
    csvData(:, 1:3:end) = [];
    info = struct('path', fullfile(videoStruct(sub).folder, videoStruct(sub).name), 'name', subName, ...
        'baud', 30, 'samples', size(csvData, 2), 'trialTypes', I.trialTypes, 'outcomes', I.outcomes);
    timestamps = struct('keys', I.timestamps);
    sessionBehDat = BehDat(info, [], timestamps, bpodSession.SessionData, csvData);
    sessions(sub) = sessionBehDat;
end

metadata.subjects = categories(categorical(nameList))';
metadata.path = videoDir;
metadata.experimenter = I.info.Experimenter;
