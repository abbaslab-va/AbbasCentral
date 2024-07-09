if ~exist('BehaviorData')
    BehaviorData = struct();
end

FlashData = 'G:\BehaviorData';
AnimalNames ={'VIP-29(1)_Laser','VIP-29(3)_Laser', 'VIP-30(1)_Laser','VIP-30(2)_Laser','VIP-30(3)_Laser', 'VIP-29(1)','VIP-29(3)', 'VIP-30(1)','VIP-30(2)','VIP-30(3)'};
StructNames = {'VIP_29_1_Laser','VIP_29_3_Laser', 'VIP_30_1_Laser','VIP_30_2_Laser','VIP_30_3_Laser', 'VIP_29_1','VIP_29_3', 'VIP_30_1','VIP_30_2','VIP_30_3'};
%Parse through all animals predefined in AnimalNames

for animal = 1:length(AnimalNames)
    subjectval = AnimalNames{animal};
    Structsubjectval = StructNames{animal};
    AnimalRoot = fullfile(FlashData, subjectval);
    cd(AnimalRoot)
    TasksDir = dir;
    
    %Parse through all tasks for each animal
    for task = 3:numel(TasksDir)
        taskval = TasksDir(task).name;
        behaviordirectory = fullfile(FlashData, subjectval, taskval);
        cd(behaviordirectory)
        localfiles = dir('*.mat');
        DateList = arrayfun(@(x) datetime(x.date(1:12)), localfiles);
        try
            existingDates = arrayfun(@(x) datetime(x.Date), BehaviorData.(Structsubjectval).(taskval))';
        catch
            existingDates = [];
        end
        try
            [MissingDates, idxDates] = setdiff(DateList, existingDates);
        catch
            MissingDates = DateList;
            idxDates = 1:numel(MissingDates);
        end

        if size(idxDates, 1) ~= 1
            idxDates = idxDates';
        end

        for filecheck = idxDates
            BehaviorData.(Structsubjectval).(taskval)(filecheck).Results = importdata(localfiles(filecheck).name);
            BehaviorData.(Structsubjectval).(taskval)(filecheck).Date = BehaviorData.(Structsubjectval).(taskval)(filecheck).Results.Info.SessionDate;
        end
    end
end

%%
% save('BehaviorData.mat','BehaviorData')
% save('AnimalNames.mat', "AnimalNames")
