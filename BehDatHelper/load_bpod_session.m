function SessionData = load_bpod_session(fPath)

cd(fPath)
SessionData = []
matdir = dir('*.mat');
for m = 1:length(matdir)
    fName = matdir(m).name;
    fInfo = whos('-file', fName);
    if isscalar(fInfo) && strcmp(fInfo.name, "SessionData")
        load(fName, 'SessionData');
        break
    end
end
if ~exist('SessionData', 'var')
    warning('No Bpod session named SessionData.mat found in %s', fPath)
end
