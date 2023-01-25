behDir = dir('*.mat');

numSessions = size(behDir, 1);
for s = 1:numSessions
    sessionName = behDir(s).name;
    session = load(sessionName);
    behObj(s) = BehDat(30000, 0, session.SessionData, rand(1, 10));
end

behObj(4).outcomes