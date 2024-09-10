function trainingSessions = make_BpodParser_training_array(BehaviorData, taskName, ini)

% Works with a structure made from a call to the script CompileLocalData

subNames = fields(BehaviorData);
trainingSessions = cell(numel(subNames), 1);
for sub = 1:numel(subNames)
    subName = subNames{sub};
    subStruct = BehaviorData.(subName).(taskName);
    subSessions = extractfield(subStruct, 'Results');
    configs = struct('name', subName, 'trialTypes', ini.trialTypes, 'outcomes', ini.outcomes);
    parserArray = cellfun(@(x) BpodParser('session', x, 'config', configs), subSessions);
    trainingSessions{sub} = parserArray;
end
emptySessions = cellfun(@(x) isempty(x), trainingSessions);
trainingSessions = trainingSessions(~emptySessions);