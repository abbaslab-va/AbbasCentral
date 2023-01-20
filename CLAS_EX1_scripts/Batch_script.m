%This script runs a chosen script (or scripts) on all subfolder of a chosen folder
%Choose your main directory folder where the other subfolders (usually containing data from individual sessions) are located
%% This IS BATCH SCRIPT 1- it will create Z-Scored firing rates for all neurons, One alignment structure for each laser On Laser off, incorrect, correct 
% this script is currently set up only for session of opto and recording
% female and male (there are extra female session that are only recording
% you could add) 



%Once you run this use Plot_cell_heatmaps.m to plot these data 
addpath(genpath('D:\CLAS_EX1'))
mainDir = uigetdir('D:\','Choose a Folder');

%Get a list of content

Subfolders = dir(mainDir);

%Remove content that isn't a subdirectory

subDirs = {Subfolders.name}';
Subfolders(~[Subfolders.isdir]' | startsWith(subDirs, '.')) = [];

%Loop through each subdirectory and runs a script on all of your
%subfolders(aka sessions). Can run as many scripts as you need

   FiringRateArray = cell(1,6);
   FiringRateStruct_Placeholder_ON = cell2struct(FiringRateArray, {'TrialStart', 'Chirp','Reward' ,'Laser','Forage','Region'}, 2);

   FiringRateArray = cell(1,6);
   FiringRateStruct_Placeholder_OFF = cell2struct(FiringRateArray, {'TrialStart', 'Chirp','Reward' ,'Laser','Forage','Region'}, 2);

   FiringRateArray = cell(1,6);
   FiringRateStruct_Placeholder_corr = cell2struct(FiringRateArray, {'TrialStart', 'Chirp','Reward' ,'Laser','Forage','Region'}, 2);

   FiringRateArray = cell(1,6);
   FiringRateStruct_Placeholder_incorr = cell2struct(FiringRateArray, {'TrialStart', 'Chirp','Reward' ,'Laser','Forage','Region'}, 2);

for subfolder = 1:numel(Subfolders)
    if subfolder<6
    sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
    sDirs = {sessionDir.name}';
    sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I')) = [];
    else 
    sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
    sDirs = {sessionDir.name}';
    sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I') | ~contains(sDirs,'opto')) = [];
    end 

    for session=1:numel(sessionDir)
            Fullpath = fullfile(Subfolders(subfolder).folder, Subfolders(subfolder).name,sessionDir(session).name);
            %[FiringRateStruct_ON, FiringRateStruct_OFF,FiringRateStruct_corr, FiringRateStruct_incorr,num_trials]=DF_create_CLA_neurons(Fullpath)
           % FiringRateStruct_Placeholder_ON=vertcat(FiringRateStruct_Placeholder_ON,FiringRateStruct_ON);
           % FiringRateStruct_Placeholder_OFF=vertcat(FiringRateStruct_Placeholder_OFF,FiringRateStruct_OFF);
           % FiringRateStruct_Placeholder_corr=vertcat(FiringRateStruct_Placeholder_corr,FiringRateStruct_corr);
           % FiringRateStruct_Placeholder_incorr=vertcat(FiringRateStruct_Placeholder_incorr,FiringRateStruct_incorr);
         DF_create_CLA_neurons_forDEC(Fullpath); 
        disp(num2str(session))
    end 
end

%% Batch Script LFP
clear all
addpath(genpath('D:\CLAS_EX1'))
mainDir = uigetdir('D:\','Choose a Folder');

%Get a list of content

Subfolders = dir(mainDir);

%Remove content that isn't a subdirectory

subDirs = {Subfolders.name}';
Subfolders(~[Subfolders.isdir]' | startsWith(subDirs, '.')) = [];

%Loop through each subdirectory and runs a script on all of your
%subfolders(aka sessions). Can run as many scripts as you need
count=1
for subfolder = 1:numel(Subfolders)
    if subfolder<6
    sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
    sDirs = {sessionDir.name}';
    sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I')) = [];
    else 
    sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
    sDirs = {sessionDir.name}';
    sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I') | ~contains(sDirs,'opto')) = [];
    end 

    for session=1:numel(sessionDir)
            Fullpath = fullfile(Subfolders(subfolder).folder, Subfolders(subfolder).name,sessionDir(session).name);
           % LFP_all_struct.(Subfolders(subfolder).name).(sessionDir(session).name)=LFP_analysis_07062022(Fullpath)
           [sess_lon(count),sess_loff(count)]=LFP_analysis_07062022(Fullpath);
           count=count+1;

        disp(num2str(session))
    end 
end

%% Batch for ISPC Will be deprecated soon 

addpath(genpath('D:\CLAS_EX1'))
mainDir = uigetdir('D:\','Choose a Folder');

%Get a list of content

Subfolders = dir(mainDir);

%Remove content that isn't a subdirectory

subDirs = {Subfolders.name}';
Subfolders(~[Subfolders.isdir]' | startsWith(subDirs, '.')) = [];

%Loop through each subdirectory and runs a script on all of your
%subfolders(aka sessions). Can run as many scripts as you need


for subfolder = 1:numel(Subfolders)
    if subfolder<6
    sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
    sDirs = {sessionDir.name}';
    sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I')) = [];
    else 
    sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
    sDirs = {sessionDir.name}';
    sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I') | ~contains(sDirs,'opto')) = [];
    end 

    for session=1:numel(sessionDir)
            Fullpath = fullfile(Subfolders(subfolder).folder, Subfolders(subfolder).name,sessionDir(session).name);
            [wcoh_OFF_e_avg,wcoh_ON_e_avg,f]=create_ISPC(Fullpath,'CLA_PFC',"Chirp");
            wcoh_OFF_sess(session,:,:)=wcoh_OFF_e_avg;
            wcoh_ON_sess(session,:,:)=wcoh_ON_e_avg;

        
    end
     wcoh_OFF_sess_avg=squeeze(mean(wcoh_OFF_sess));
     wcoh_ON_sess_avg=squeeze(mean(wcoh_ON_sess));
     wcoh_OFF_sub(subfolder,:,:)=wcoh_OFF_sess_avg;
     wcoh_ON_sub(subfolder,:,:)=wcoh_ON_sess_avg;
     disp(num2str(subfolder))
end

wcoh_OFF_sub_avg=squeeze(mean(wcoh_OFF_sub));
wcoh_ON_sub_avg=squeeze(mean(wcoh_ON_sub));

 figure()
 subplot(121)
 hold on 
 f_flip=flip(f)
 surf(flip(wcoh_OFF_sub_avg))
 view(2)
 shading interp
 yticks([11 23 35 47 59 71 83])
 yticklabels([2 4 8 16 32 64 128])
 ylim([1 83])
 xline(4000)
 xline(5000)
 title('Laser OFF')
 colorbar() 
 caxis([0.2 0.55])
 %xticks([0 1000 2000 3000 4000 5000])
 %xticklabels([{'-1'} {'-1'}  {'ChirpON'} 2000 3000 4000 5000])
 
 subplot(122)
 hold on 
 f_flip=flip(f)
 surf(flip(wcoh_ON_sub_avg))
 view(2)
 shading interp
 yticks([11 23 35 47 59 71 83])
 yticklabels([2 4 8 16 32 64 128])
 ylim([1 83])
 xline(4000)
 xline(5000)
 title('Laser ON')
 colorbar() 
 caxis([0.2 0.55])
 %xticks([0 1000 2000 3000 4000 5000])
 %xticklabels([{'-1'} {'-1'}  {'ChirpON'} 2000 3000 4000 5000])

%%

Animal='CLAS_012';
Session='CLAS_012_D3_opto';
Region='PFC';
TrialType='LOFF'


checkmax(1)=max(max(LFP_all_struct.(Animal).(Session).LOFF.(Region)(1).Chirp));
checkmax(2)=max(max(LFP_all_struct.(Animal).(Session).LON.(Region)(1).Chirp));
checkmax(3)=max(max(LFP_all_struct.(Animal).(Session).Correct.(Region)(1).Chirp));
checkmax(4)=max(max(LFP_all_struct.(Animal).(Session).Incorrect.(Region)(1).Chirp));
cmax=max(checkmax);
cmax=max(checkmax)-.7*cmax;

tiledlayout(6,2)

ax1=nexttile([2,1]);
surf(LFP_all_struct.(Animal).(Session).(TrialType).(Region)(1).TrialStart)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Trialstart'])
caxis([0 cmax])
xline(4000)

ax2=nexttile([2,1]);
surf(LFP_all_struct.(Animal).(Session).(TrialType).(Region)(1).Chirp)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Chirp'])
caxis([0 cmax])
xline(4000)

ax3=nexttile;
plot(LFP_all_struct.(Animal).(Session).(TrialType).(Region)(2).TrialStart)
ylabel('ERP')
title( [TrialType ' ' Region ' Trialstart'])
xline(4000)

ax4=nexttile;
plot(LFP_all_struct.(Animal).(Session).(TrialType).(Region)(2).Chirp)
ylabel('ERP')
title( [TrialType ' ' Region ' Chirp'])
xline(4000)


ax5=nexttile([2,1]);
surf(LFP_all_struct.(Animal).(Session).(TrialType).(Region)(1).Reward)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Reward'])
caxis([0 cmax])
xline(4000)


ax6=nexttile([2,1]);
surf(LFP_all_struct.(Animal).(Session).(TrialType).(Region)(1).Forage)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Forage'])
caxis([0 cmax])
xline(4000)


ax7=nexttile;
plot(LFP_all_struct.(Animal).(Session).(TrialType).(Region)(2).Reward)
ylabel('ERP')
title( [TrialType ' ' Region ' Reward'])
xline(4000)

ax8=nexttile;
plot(LFP_all_struct.(Animal).(Session).(TrialType).(Region)(2).Forage)
ylabel('ERP')
title( [TrialType ' ' Region ' Forage'])
xline(4000)


cb = colorbar;
cb.Layout.Tile = 'east';

%% Now average everthing: 

TrialTypes=fields(LFP_all_struct.CLAS_009.CLAS_009_D1_opto);
Regions=fields(LFP_all_struct.CLAS_009.CLAS_009_D1_opto.LON);
alignments=fields(LFP_all_struct.CLAS_009.CLAS_009_D1_opto.LON.PFC);
subjects=fields(LFP_all_struct);

% Somthing is wrong with CLAS_009 Day 2 and CLAS_017 Day 3, CLAS_015 Day 3 so I manually
% deleted them 
temp1=zeros(70,8000,3);
temp2=zeros(8000,3);
for tt=1:length(TrialTypes)
    for r=1:length(Regions)
        for a=1:length(alignments)
            for s=1:length(subjects)
                sessions=fields(LFP_all_struct.(subjects{s})) ;
                for sess=1:length(sessions)
                    temp1(:,:,sess)=LFP_all_struct.(subjects{s}).(sessions{sess}).(TrialTypes{tt}).(Regions{r})(1).(alignments{a});
                    temp2(:,sess)=LFP_all_struct.(subjects{s}).(sessions{sess}).(TrialTypes{tt}).(Regions{r})(2).(alignments{a});
                end
                LFP_mean_struct.(subjects{s}).(TrialTypes{tt}).(Regions{r})(1).(alignments{a})=mean(temp1,3);
                LFP_mean_struct.(subjects{s}).(TrialTypes{tt}).(Regions{r})(2).(alignments{a})=mean(temp2,2);
            end 
        end 
    end 
end 
   

%% Now plot sessions averaged 


Animal='CLAS_012';
Region='PFC';
TrialType='LOFF_Correct'


checkmax(1)=max(max(LFP_mean_struct.(Animal).LOFF.(Region)(1).Chirp));
checkmax(2)=max(max(LFP_mean_struct.(Animal).LON.(Region)(1).Chirp));
checkmax(3)=max(max(LFP_mean_struct.(Animal).Correct.(Region)(1).Chirp));
checkmax(4)=max(max(LFP_mean_struct.(Animal).Incorrect.(Region)(1).Chirp));
cmax=max(checkmax);
cmax=max(checkmax)-.3*cmax;

tiledlayout(6,2)

ax1=nexttile([2,1]);
surf(LFP_mean_struct.(Animal).(TrialType).(Region)(1).TrialStart)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Trialstart'])
caxis([0 cmax])
xline(4000)

ax2=nexttile([2,1]);
surf(LFP_mean_struct.(Animal).(TrialType).(Region)(1).Chirp)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Chirp'])
caxis([0 cmax])
xline(4000)

ax3=nexttile;
plot(LFP_mean_struct.(Animal).(TrialType).(Region)(2).TrialStart)
ylabel('ERP')
title( [TrialType ' ' Region ' Trialstart'])
xline(4000)

ax4=nexttile;
plot(LFP_mean_struct.(Animal).(TrialType).(Region)(2).Chirp)
ylabel('ERP')
title( [TrialType ' ' Region ' Chirp'])
xline(4000)


ax5=nexttile([2,1]);
surf(LFP_mean_struct.(Animal).(TrialType).(Region)(1).Reward)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Reward'])
caxis([0 cmax])
xline(4000)


ax6=nexttile([2,1]);
surf(LFP_mean_struct.(Animal).(TrialType).(Region)(1).Forage)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Forage'])
caxis([0 cmax])
xline(4000)


ax7=nexttile;
plot(LFP_mean_struct.(Animal).(TrialType).(Region)(2).Reward)
ylabel('ERP')
title( [TrialType ' ' Region ' Reward'])
xline(4000)

ax8=nexttile;
plot(LFP_mean_struct.(Animal).(TrialType).(Region)(2).Forage)
ylabel('ERP')
title( [TrialType ' ' Region ' Forage'])
xline(4000)


cb = colorbar;
cb.Layout.Tile = 'east';

%% Now FULL average 

 temp1=zeros(70,8000,3);
 temp2=zeros(8000,3);
 temp3=zeros(70,8000,9);
 temp4=zeros(8000,9);

for tt=1:length(TrialTypes)
    for r=1:length(Regions)
        for a=1:length(alignments)
            for s=1:length(subjects)
                sessions=fields(LFP_all_struct.(subjects{s})) ;
                for sess=1:length(sessions)
                    temp1(:,:,sess)=LFP_all_struct.(subjects{s}).(sessions{sess}).(TrialTypes{tt}).(Regions{r})(1).(alignments{a});
                    temp2(:,sess)=LFP_all_struct.(subjects{s}).(sessions{sess}).(TrialTypes{tt}).(Regions{r})(2).(alignments{a});
                end
             
                temp3(:,:,s)=mean(temp1,3);
                temp4(:,s)=mean(temp2,2);
            end 
            LFP_full_struct.(TrialTypes{tt}).(Regions{r})(1).(alignments{a})=mean(temp3,3);
            LFP_full_struct.(TrialTypes{tt}).(Regions{r})(2).(alignments{a})=mean(temp4,2);
        end 
    end 
end 
%% NOW PLOT Full average 
figure()
Region='PFC';
TrialType='LON_Incorrect'


checkmax(1)=max(max(LFP_full_struct.LOFF.(Region)(1).Chirp));
checkmax(2)=max(max(LFP_full_struct.LON.(Region)(1).Chirp));
checkmax(3)=max(max(LFP_full_struct.Correct.(Region)(1).Chirp));
checkmax(4)=max(max(LFP_full_struct.Incorrect.(Region)(1).Chirp));
cmax=max(checkmax);
cmax=max(checkmax)-.1*cmax;

tiledlayout(6,2)

ax1=nexttile([2,1]);
surf(LFP_full_struct.(TrialType).(Region)(1).TrialStart)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Trialstart'])
caxis([0 cmax])
xline(4000)

ax2=nexttile([2,1]);
surf(LFP_full_struct.(TrialType).(Region)(1).Chirp)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Chirp'])
caxis([0 cmax])
xline(4000)

ax3=nexttile;
plot(LFP_full_struct.(TrialType).(Region)(2).TrialStart)
ylabel('ERP')
title( [TrialType ' ' Region ' Trialstart'])
xline(4000)

ax4=nexttile;
plot(LFP_full_struct.(TrialType).(Region)(2).Chirp)
ylabel('ERP')
title( [TrialType ' ' Region ' Chirp'])
xline(4000)


ax5=nexttile([2,1]);
surf(LFP_full_struct.(TrialType).(Region)(1).Reward)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Reward'])
caxis([0 cmax])
xline(4000)


ax6=nexttile([2,1]);
surf(LFP_full_struct.(TrialType).(Region)(1).Forage)
view(2)
shading interp
yticks([1,21,35,52,63,70])
yticklabels([{'1'},{'4'},{'10'},{'35'},{'75'},{'120'}])
ylabel('Power')
title( [TrialType ' ' Region ' Forage'])
caxis([0 cmax])
xline(4000)


ax7=nexttile;
plot(LFP_full_struct.(TrialType).(Region)(2).Reward)
ylabel('ERP')
title( [TrialType ' ' Region ' Reward'])
xline(4000)

ax8=nexttile;
plot(LFP_full_struct.(TrialType).(Region)(2).Forage)
ylabel('ERP')
title( [TrialType ' ' Region ' Forage'])
xline(4000)


cb = colorbar;
cb.Layout.Tile = 'east';
