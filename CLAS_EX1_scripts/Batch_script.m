%{
Updated:12/30/2022
This is the main script for CLA_EX1 
%}



%% Z-Scored Heat maps 
%{ 
this will create Z-Scored firing rates for all neurons, One alignment structure for each laser On Laser off, incorrect, correct 
this script is currently set up only for sessions with  opto + recording, there are extra female sessions that are only recording
I could add),Once you run this use Plot_cell_heatmaps.m to plot these data 
%}


%addpath(genpath('D:\CLAS_EX1')) % change to current directory 
mainDir = uigetdir('D:\','Choose a Folder');

%Get a list of content
Subfolders = dir(mainDir);

%Remove content that isn't a subdirectory

subDirs = {Subfolders.name}';
Subfolders(~[Subfolders.isdir]' | startsWith(subDirs, '.')) = [];

%Loop through each subdirectory and run a script on all of your
%subfolders(aka sessions). Can run as many scripts as you need

for subfolder = 1:numel(Subfolders)
    if subfolder<6 % if males 
        sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
        sDirs = {sessionDir.name}';
        sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I')) = []; % Remove DOI sessions and weird ". ." cells 
    else 
        sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
        sDirs = {sessionDir.name}';
        sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I') | ~contains(sDirs,'opto')) = [];% Remove DOI sessions,  weird ". ." cells, and non-opto recordingd for females 
    end 

    for session=1:numel(sessionDir)
        Fullpath = fullfile(Subfolders(subfolder).folder, Subfolders(subfolder).name,sessionDir(session).name);
        FiringRateStruct_ALL.(Subfolders(subfolder).name).(sessionDir(session).name)=DF_create_CLA_neurons(Fullpath)
        disp(num2str(session))
    end 
end


%% New modular script 
mainDir = uigetdir('D:\','Choose a Folder');

%Get a list of content
Subfolders = dir(mainDir);

%Remove content that isn't a subdirectory

subDirs = {Subfolders.name}';
Subfolders(~[Subfolders.isdir]' | startsWith(subDirs, '.')) = [];

%Loop through each subdirectory and run a script on all of your
%subfolders(aka sessions). Can run as many scripts as you need

for subfolder = 1:numel(Subfolders)
    if subfolder<6 % if males 
        sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
        sDirs = {sessionDir.name}';
        sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I')) = []; % Remove DOI sessions and weird ". ." cells 
    else 
        sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
        sDirs = {sessionDir.name}';
        sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'I') | ~contains(sDirs,'opto')) = [];% Remove DOI sessions,  weird ". ." cells, and non-opto recordingd for females 
    end 

    for session=1:numel(sessionDir)
        Fullpath = fullfile(Subfolders(subfolder).folder, Subfolders(subfolder).name,sessionDir(session).name);
        [spikes_struct_ALL.(sessionDir(session).name) ts_struct_trial_ALL.(sessionDir(session).name), ts_struct_ALL.(sessionDir(session).name)]=spikes_lfp_events_trialTypes(Fullpath)
        disp(num2str(session))
    end 
end
%% Generate Z_scores
sessions=fieldnames(spikes_struct_ALL);
alignments=fieldnames(ts_struct_trial_ALL.CLAS_009_D1_opto);
trialTypes=fieldnames(ts_struct_trial_ALL.CLAS_009_D1_opto.TrialStart);
for sess=1:length(sessions)
    for align=1:length(alignments)
        for ttype=1:length(trialTypes)
            for n=1:length(spikes_struct_ALL.(sessions{sess}))
                spike_times=spikes_struct_ALL.(sessions{sess})(n).SpikeTimes;
                ts=ts_struct_trial_ALL.(sessions{sess}).(alignments{align}).(trialTypes{ttype});
               [z_score_struct.(sessions{sess}).(trialTypes{ttype})(n).(alignments{align}), raw_FR_struct.(sessions{sess}).(trialTypes{ttype})(n).(alignments{align})]=z_scoreFUN(spike_times,ts,ts_struct_ALL.(sessions{sess}).Trialstart);
            end
        end
    end
    disp(sessions{sess})
end


%%  LFP 
filterbank= cwtfilterbank('SignalLength', 8000, 'SamplingFrequency',2000, 'TimeBandwidth',60, 'FrequencyLimits',[1 120], 'VoicesPerOctave', 10);   
PFC_ch=[1,3,5,7,9,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32];
CLA_ch=[17,19,21,23,25,27,29,31];
ENTI_ch=15;
AUD_ch=13;
MD_ch=11;

sessions=fieldnames(spikes_struct_ALL);
alignments=fieldnames(ts_struct_trial_ALL.CLAS_009_D1_opto);
trialTypes=fieldnames(ts_struct_trial_ALL.CLAS_009_D1_opto.TrialStart);
for sess=2:length(sessions)
    Fullpath=strcat('D:\CLAS_EX1\Data\',sessions{sess}(1:8),'\',sessions{sess});
   
    NEV_file = strcat(Fullpath,'\',sessions{sess}, '.nev');
    NEV=openNEV(NEV_file);
    NS_6 = strcat(Fullpath,'\',sessions{sess}, '.ns6');
    openNSx(NS_6);
    NS6_Length = length(NS6.Data);


    Raw_Data =double(NS6.Data);
    PFC_lfp=Raw_Data(PFC_ch,:);
    %CLA_lfp=Raw_Data(CLA_ch,:);
 for pfc_ch=1:size(PFC_lfp,1) 
     lfp=PFC_lfp(pfc_ch,:);
    for align= 2 %1:length(alignments) % just look at Chirp
        for ttype=1:length(trialTypes)
             ts=ts_struct_trial_ALL.(sessions{sess}).(alignments{align}).(trialTypes{ttype});
             LFP_struct.(sessions{sess}).(trialTypes{ttype})(pfc_ch).(alignments{align})=PWR_FUN(lfp,ts,filterbank);
             % surf(Power)
                % view(2)
            % shading interp
        end
    end
   disp(num2str(pfc_ch))  
 end 
    disp(sessions{sess})
end
% 

%% 

sessions=fieldnames(LFP_struct);
for ttype=1:length(trialTypes)
LFP_combined.(trialTypes{ttype})=[{LFP_struct.(sessions{1}).(trialTypes{ttype}).Chirp}... 
 {LFP_struct.(sessions{2}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{3}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{4}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{5}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{6}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{7}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{8}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{9}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{10}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{13}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{14}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{15}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{18}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{19}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{20}).(trialTypes{ttype}).Chirp}...
 {LFP_struct.(sessions{21}).(trialTypes{ttype}).Chirp}]

end 
for ttype=[1,2,5,6] %length(trialTypes)
    for c=1:336 %length(LFP_combined.(trialTypes{ttype}))
        LFP_all.(trialTypes{ttype})(:,:,c)=LFP_combined.(trialTypes{ttype}){c};
    end 
end 
%%
    figure()    
    surf(mean(LFP_all.LOFF_Correct,3));
    view(2)
    shading interp
    colorbar
    caxis([0 .25])

    figure()    
    surf(mean(LFP_all.LOFF_Incorrect,3));
    view(2)
    shading interp
    colorbar
caxis([0 .25])

    figure()    
    surf(mean(LFP_all.LOFF,3));
    view(2)
    shading interp
    colorbar
    caxis([0 .25])

    figure()    
    surf(mean(LFP_all.LON,3));
    view(2)
    shading interp
    colorbar
caxis([0 .25])


%% Concatentate structures 
sessions=fieldnames(z_score_struct);
for ttype=1:length(trialTypes)
FR_combined.(trialTypes{ttype})=[z_score_struct.(sessions{1}).(trialTypes{ttype})... 
 z_score_struct.(sessions{2}).(trialTypes{ttype})...
 z_score_struct.(sessions{3}).(trialTypes{ttype})...
 z_score_struct.(sessions{4}).(trialTypes{ttype})...
 z_score_struct.(sessions{5}).(trialTypes{ttype})...
 z_score_struct.(sessions{6}).(trialTypes{ttype})...
 z_score_struct.(sessions{7}).(trialTypes{ttype})...
 z_score_struct.(sessions{8}).(trialTypes{ttype})...
 z_score_struct.(sessions{9}).(trialTypes{ttype})...
 z_score_struct.(sessions{10}).(trialTypes{ttype})...
 z_score_struct.(sessions{13}).(trialTypes{ttype})...
 z_score_struct.(sessions{14}).(trialTypes{ttype})...
 z_score_struct.(sessions{15}).(trialTypes{ttype})...
 z_score_struct.(sessions{18}).(trialTypes{ttype})...
 z_score_struct.(sessions{19}).(trialTypes{ttype})...
 z_score_struct.(sessions{20}).(trialTypes{ttype})...
 z_score_struct.(sessions{21}).(trialTypes{ttype})]

end 


%z_score_struct.(sessions{11}).(trialTypes{ttype})...
 %z_score_struct.(sessions{12}).(trialTypes{ttype})...
 %z_score_struct.(sessions{16}).(trialTypes{ttype})...
 %z_score_struct.(sessions{17}).(trialTypes{ttype})...
%%
spike_struct_combined=vertcat(spikes_struct_ALL.(sessions{1}),...
    spikes_struct_ALL.(sessions{2}),...
    spikes_struct_ALL.(sessions{3}),...
    spikes_struct_ALL.(sessions{4}),...
    spikes_struct_ALL.(sessions{5}),...
    spikes_struct_ALL.(sessions{6}),...
    spikes_struct_ALL.(sessions{7}),...
    spikes_struct_ALL.(sessions{8}),...
    spikes_struct_ALL.(sessions{9}),...
    spikes_struct_ALL.(sessions{10}),...
    spikes_struct_ALL.(sessions{11}),...
    spikes_struct_ALL.(sessions{12}),...
    spikes_struct_ALL.(sessions{13}),...
    spikes_struct_ALL.(sessions{14}),...
    spikes_struct_ALL.(sessions{15}),...
    spikes_struct_ALL.(sessions{16}),...
    spikes_struct_ALL.(sessions{17}),...
    spikes_struct_ALL.(sessions{18}),...
    spikes_struct_ALL.(sessions{19}),...
    spikes_struct_ALL.(sessions{20}),...
    spikes_struct_ALL.(sessions{21}))
%% 

sessions=fieldnames(raw_FR_struct);
for ttype=1:length(trialTypes)
FR_combined_raw.(trialTypes{ttype})=[raw_FR_struct.(sessions{1}).(trialTypes{ttype})... 
  raw_FR_struct.(sessions{2}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{3}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{4}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{5}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{6}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{7}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{8}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{9}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{10}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{11}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{12}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{13}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{14}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{15}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{16}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{17}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{18}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{19}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{20}).(trialTypes{ttype})...
 raw_FR_struct.(sessions{21}).(trialTypes{ttype})]

end 



%% ZETA TEST 




%% spike heatmaps DOI 
addpath(genpath('D:\CLAS_EX1'))
mainDir = uigetdir('D:\','Choose a Folder');

%Get a list of content

Subfolders = dir(mainDir);

%Remove content that isn't a subdirectory

subDirs = {Subfolders.name}';
Subfolders(~[Subfolders.isdir]' | startsWith(subDirs, '.')) = [];

%Loop through each subdirectory and runs a script on all of your
%subfolders(aka sessions). Can run as many scripts as you need

for subfolder = 1:3 %numel(Subfolders)
    sessionDir=dir(fullfile(Subfolders(subfolder).folder,Subfolders(subfolder).name))
    sDirs = {sessionDir.name}';
    sessionDir(~[sessionDir.isdir]' | startsWith(sDirs, '.') | endsWith(sDirs, 'o')) = [];
    
    Fullpath = fullfile(Subfolders(subfolder).folder, Subfolders(subfolder).name,sessionDir.name);
    FR_all_struct.(Subfolders(subfolder).name).(sessionDir.name)=DF_create_CLA_neurons_DOI(Fullpath)

    disp(num2str(subfolder))
end





%% Batch Script LFP
clear all
tic 
%addpath(genpath('D:\CLAS_EX1'))
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
            LFP_all_struct.(Subfolders(subfolder).name).(sessionDir(session).name)=LFP_analysis_07062022(Fullpath);
        disp(num2str(session))
    end 
     %save(fullfile('D:\CLAS_EX1\Analysis_Structs',[Subfolders(subfolder).name '.mat']),'LFP_all_struct','-v7.3')
     %clearvars LFP_all_struct
end     
toc




%% BAtch Script for Classifier 

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
               FR_all_struct.(Subfolders(subfolder).name).(sessionDir(session).name)=DF_create_CLA_neurons(Fullpath)

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

%%  BAtch script for pfc synchrony 

clear all
tic 
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
            ppc_all_struct.(Subfolders(subfolder).name).(sessionDir(session).name)=PV_gamma_synchrony(Fullpath);
        disp(num2str(session))
    end 
     %save(fullfile('D:\CLAS_EX1\Analysis_Structs',[Subfolders(subfolder).name '.mat']),'LFP_all_struct','-v7.3')
     %clearvars LFP_all_struct
end     
toc


