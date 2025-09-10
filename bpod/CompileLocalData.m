if ~exist('BehaviorData')
    BehaviorData = struct();
end

% FlashData = 'G:\BehaviorData';
FlashData = 'J:\Russell\Behavior';
% AnimalNames = cellfun(@(x) ['MD_', num2str(x)], num2cell(1:24), 'uni', 0);
% AnimalNames = {'MD_1', 'MD_4', 'MD_5', 'MD_6','MD_11', 'MD_13', 'MD_15', 'MD_19', 'MD_20', 'MD_24'};
% AnimalNames = {'DMTS_11_1', 'DMTS_11_2', 'DMTS_11_3', 'DMTS_12_1', 'DMTS_12_2', 'DMTS_12_3',...
%     'DMTS_13_1', 'DMTS_13_2', 'DMTS_13_3', 'DMTS_14_2', ...
%     'DMTS_15_2', 'DMTS_15_3', 'DMTS_16_1',  'DMTS_16_3',...
%      'DMTS_17_2', 'DMTS_17_3', 'DMTS_18_1',  'DMTS_18_3'}; % remaining after first batch injected
% AnimalNames = {'DMTS_14_1', 'DMTS_14_3', 'DMTS_15_1', 'DMTS_16_2', 'DMTS_17_1', 'DMTS_18_2'}; % first batch injected
% AnimalNames{'DMTS_11_1', 'DMTS_11_2', 'DMTS_11_3', 'DMTS_12_1', 'DMTS_12_2', 'DMTS_12_3',...
%     'DMTS_13_1', 'DMTS_13_2', 'DMTS_13_3', 'DMTS_14_1', 'DMTS_14_2', 'DMTS_14_3',...
%     'DMTS_15_1', 'DMTS_15_2', 'DMTS_15_3', 'DMTS_16_1', 'DMTS_16_2', 'DMTS_16_3',...
%     'DMTS_17_1', 'DMTS_17_2', 'DMTS_17_3', 'DMTS_18_1', 'DMTS_18_2', 'DMTS_18_3'};


% AnimalNames = {'DMTS_12_2', 'DMTS_13_1', 'DMTS_13_2', 'DMTS_15_2', 'DMTS_16_3', 'DMTS_17_2'};% Second batch injected of 25-48 cohort, 12_2 and 15_2 got control virus
% AnimalNames = {'MD_1', 'MD_4', 'MD_5', 'MD_6','MD_11', 'MD_13', 'MD_15', 'MD_19', 'MD_24',...
%     'MD_25','MD_26','MD_27','MD_28', 'MD_29', 'MD_30',...
%     'MD_31', 'MD_32', 'MD_34', 'MD_35', 'MD_36'};
AnimalNames = {'DMTS_11_1', 'DMTS_11_2', 'DMTS_11_3', 'DMTS_12_1',  'DMTS_12_3',...
     'DMTS_13_3', 'DMTS_14_2', ...
     'DMTS_15_3', 'DMTS_16_1',  ...
      'DMTS_17_3', 'DMTS_18_1',  'DMTS_18_3'}; % remaining after second batch injected

% AnimalNames = {'MD_1', 'MD_4', 'MD_5', 'MD_6','MD_11', 'MD_13', 'MD_15', 'MD_19', 'MD_24', 'MD_25','MD_27', 'MD_29', 'MD_30'}; % MD_26 & MD_28 got control virus
StructNames = AnimalNames;
% AnimalNames ={'VIP-29(1)_Laser','VIP-29(3)_Laser', 'VIP-30(1)_Laser','VIP-30(2)_Laser','VIP-30(3)_Laser', 'VIP-29(1)','VIP-29(3)', 'VIP-30(1)','VIP-30(2)','VIP-30(3)'};
% StructNames = {'VIP_29_1_Laser','VIP_29_3_Laser', 'VIP_30_1_Laser','VIP_30_2_Laser','VIP_30_3_Laser', 'VIP_29_1','VIP_29_3', 'VIP_30_1','VIP_30_2','VIP_30_3'};
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
