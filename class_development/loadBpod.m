behDir = dir('*.mat');

numSessions = size(behDir, 1);
behSessions = cell(1, numSessions);
for s = 1:numSessions
    sessionName = behDir(s).name;
    session = load(sessionName);
    behSessions{s} = load(sessionName);
end

behObj = BehDat(obj, 30000, 0, behSessions{1}, 0);
