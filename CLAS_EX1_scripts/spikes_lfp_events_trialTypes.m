


% % %YOU MUST RUN Kilosort3 + Phy2 and SAVE your session BEFORE running this script!!

%This script organizes data that has been run through Kilosort3 and Phy2
%into a Spike_Struct made from 'good' spike clusters (individual neurons), and creates an average
%spike waveform for 'good' neurons (first section). It also organizes event timestamps and plots spiking around
%specific events if applicable (second section).

%Choose the folder where the saved kilosorted data for a specific mouse/experiment is located
%Fullpath = uigetdir('D:\', 'Choose a Folder'); %Pick the folder containing the experiment you want to import %Fullpath
%addpath(genpath('D:\pipeline')); %The Blackrock NPMK github code needs to be downloaded to the same main parent folder as above

function [spike_struct,ts_struct_trial,ts_struct]=spikes_lfp_events_trialTypes(Fullpath)
    % 
    %Fullpath='D:\CLAS_EX1\Data\CLAS_009\CLAS_009_D1_opto'
    %Fullpath='D:\CLAS_EX1\Data\CLAS_012\CLAS_012_D3_opto'
    %Fullpath='D:\CLAS_EX1\Data\CLAS_015\CLAS_015_opto_D3'
    cd(Fullpath)
    load('SessionData.mat', 'SessionData');
    
    [~,FolderName] = fileparts(Fullpath);

    
    NEV_file = strcat(Fullpath,'\',FolderName, '.nev');
    if ~isempty(dir(fullfile(Fullpath , '*.nev'))) == 1
    NEV=openNEV(NEV_file);
    end
    
    NS_6 = strcat(Fullpath,'\',FolderName, '.ns6');
    if ~isempty(dir(fullfile(Fullpath , '*.ns6'))) == 1
    openNSx(NS_6)
    end
    
    NS6_Length = length(NS6.Data);
    
    
    %% Timestamp Section
% % 65528 - no input
% % 65529 - wire 1          Trial start
% % 65530 - wire 2          Chirp 
% % 65531 - wires 1 and 2   Forage Reward
% % 65532 - wire 3          Reward
% % 65533 - wires 1 and 3   Punish
% % 65534 - wires 2 and 3   End of ITI
% % 65535 - wires 1, 2 and 3 NOTHING

% diff=1 will take care of extra weird ones 
  
    %Refining and finding event timestamps, 
    EventTimestamps(1,:) = double(NEV.Data.SerialDigitalIO.TimeStamp);
    EventTimestamps(2,:) = double(NEV.Data.SerialDigitalIO.UnparsedData');
 
    AdjustedTimestamps(1,:)=EventTimestamps(1,:);
    AdjustedTimestamps(2,:)=EventTimestamps(2,:);

    
    diffs=diff(EventTimestamps(1,:)) ; 
    take_out1=find(diffs~=1);

    AdjustedTimestamps=AdjustedTimestamps(:,take_out1);
    AdjustedTimestamps(1,:) = double((AdjustedTimestamps(1,:)));


   
    
    %% Check Length of Adjusted Timestamps and bPOD
    Check_length=find(AdjustedTimestamps(2,:)==65529);
    if length(Check_length)-length(SessionData.SessionPerformance)==1
       AdjustedTimestamps=AdjustedTimestamps(:,1:Check_length(end)-2);
   
    elseif length(Check_length)-length(SessionData.SessionPerformance)==0
        disp("Length Match!")
    else
         ME = MException('MyComponent:noSuchVariable', ...
        'length mismatch');
        throw(ME)
    end 
     
    TrialStart_Index=find(AdjustedTimestamps(2,:)==65529);
    %TrialStart_Index=find(EventTimestamps(2,:)==65529);
    
    num_trials=length(TrialStart_Index);
    %% Create Forage Reward, Back Reward, Back Punish, Chirp, and laser on time stamps
    
    TrialStart_timestamps=AdjustedTimestamps(1,TrialStart_Index);
    forage_ts =cell(length(TrialStart_Index),1);
    reward_ts =cell(length(TrialStart_Index),1);
    chirp_ts  =cell(length(TrialStart_Index),1);
    punish_ts =cell(length(TrialStart_Index),1);
    
    
    for trial=1:length(TrialStart_Index)-1
        fi=find(AdjustedTimestamps(2,TrialStart_Index(trial): TrialStart_Index(trial+1))==65531);
        ri=find(AdjustedTimestamps(2,TrialStart_Index(trial): TrialStart_Index(trial+1))==65532);
        ci=find(AdjustedTimestamps(2,TrialStart_Index(trial): TrialStart_Index(trial+1))==65530); % denotes Laser ON
        pi=find(AdjustedTimestamps(2,TrialStart_Index(trial): TrialStart_Index(trial+1))==65533);
        
        temp=AdjustedTimestamps(1,TrialStart_Index(trial): TrialStart_Index(trial+1));
       
        forage_ts{trial}=temp(fi);
        reward_ts{trial}=temp(ri);
        chirp_ts{trial}=temp(ci);
        punish_ts{trial}=temp(pi);
        clearvars temp fi ci ri pi 
    end 
    
    laser_ts=chirp_ts;
    chirp_ts=cellfun(@(x) x+15000,chirp_ts,'un',0);% at 0.5 seconds so the chirp is aligned 

 % This adds a time stamp for the third forage (the 3rd Forage is arbitrary)    
 third_forage_ts=num2cell(zeros(num_trials,1));
    for row=1:length(TrialStart_Index)
        if numel(forage_ts{row,1})>=3 % 
          third_forage_ts{row} =forage_ts{row}(3);
        else 
           third_forage_ts{row}=[];
        end 
    end 

 trialStart_ts=num2cell(TrialStart_timestamps)';

    %% Make Spike time array will all neurons  
    
    %Getting spike info from Kilosort3 files
    UnsortedSpikeTimes = double(readNPY(strcat(Fullpath, '\spike_times.npy')));
    UnsortedSpikeClusters = double(readNPY(strcat(Fullpath, '\spike_clusters.npy')))+1;
    ClusterInfo = tdfread(strcat(Fullpath, '\cluster_info.tsv'));
    
    %Combining your manually curated clusters (if any) with those that kilosort
    %automatically assigns
    
    for Cluster = 1:length(ClusterInfo.id)
        
        if isnan(ClusterInfo.group(Cluster,1))
           ClusterInfo.group(Cluster,1) = ClusterInfo.KSLabel(Cluster,1); 
        elseif regexp('   ', ClusterInfo.group(Cluster,:)) == 1
           ClusterInfo.group(Cluster,1) = ClusterInfo.KSLabel(Cluster,1);
        elseif regexp('    ', ClusterInfo.group(Cluster,:)) == 1
           ClusterInfo.group(Cluster,1) = ClusterInfo.KSLabel(Cluster,1);
        elseif regexp('     ', ClusterInfo.group(Cluster,:)) == 1
           ClusterInfo.group(Cluster,1) = ClusterInfo.KSLabel(Cluster,1);
        end
        
    end
    
    %Pulling out only the clusters labeled 'good' (the ones that start with a 'g')
    %and putting them into a matrix called GoodClusters
    GoodClusters = ClusterInfo.id(ismember(ClusterInfo.group(:,1),'g') == 1)+1;
    ClusterInfo.ch = ClusterInfo.ch + 1; 
    GoodChannels = ClusterInfo.ch(ismember(ClusterInfo.group(:,1),'g') == 1); 
    
    %Creates a cell array with each 'good' cluster on a separate row, matches 
    %spike times for each cluster, and gets bursting and average waveform for each cluster
    SpikeTimeArray = cell(length(GoodClusters),3);
    
    for Cluster = 1:length(GoodClusters)
        
        SpikeTimeArray{Cluster,1} = GoodClusters(Cluster);
        SpikeTimeArray{Cluster,2} = GoodChannels(Cluster);
        SpikeTimeArray{Cluster,3} = (UnsortedSpikeTimes(UnsortedSpikeClusters == GoodClusters(Cluster))');
 
    end

   FiringRateArray = cell(length(GoodClusters),8);
   spike_struct= cell2struct(FiringRateArray, {'SpikeTimes','Region','FR','WidthValley','WidthPeak','Peak2Valley','AvgWaveform','Chan'},2);
 

%% extract waveform

HighpassedData = zeros(length(GoodChannels), length(NS6.Data)); %#ok<PREALL>
HighpassedData = highpass(single(NS6.Data(GoodChannels, :))', 500, 30000);
HighpassedData = HighpassedData';

%%
Average_Waveforms = cell(length(GoodClusters),1);

for Neuron = 1:length(GoodClusters)

Average_Waveforms{Neuron} = zeros(1000,101);
   
   
            for spike = 1:1000
                try
                    Average_Waveforms{Neuron}(spike,:) = HighpassedData(Neuron,SpikeTimeArray{Neuron,3}(spike)-50 : SpikeTimeArray{Neuron,3}(spike)+50);
                catch
                end
            end
            
    Average_Waveforms{Neuron} = mean(Average_Waveforms{Neuron});
  
%     figure;
%     plot(Average_Waveforms{Neuron}*-1)
%     pause()
%     set(gca, 'visible', 'off')

end

%% Waveform metrics 

for n=1:length(Average_Waveforms)
    [pks,locs,w,p]=findpeaks(Average_Waveforms{n});
%     figure;
%     findpeaks((Average_Waveforms{n}),'Annotate','extents')
%     pause()
    [max_val,max_idx]=max(p);
    half_valley_width(n,1)=w(max_idx);
    peak2valley(n,1)=abs(min(Average_Waveforms{n}))/abs(max(Average_Waveforms{n}));
end

for n=1:length(Average_Waveforms)
    [pks,locs,w,p]=findpeaks(Average_Waveforms{n}*-1);
%     figure;
%     findpeaks((Average_Waveforms{n}),'Annotate','extents')
%     pause()
    [max_val,max_idx]=max(p);
    half_peak_width(n,1)=w(max_idx);
end

% firing rate 
for n=1:size(SpikeTimeArray,1)
    fr_rate(n,1)=length(SpikeTimeArray{n,3})/(NS6_Length/30000);
end 


%% Region 
for r=1:size(SpikeTimeArray,1)
 if  GoodChannels(r)==1|| GoodChannels(r)==3|| GoodChannels(r)==5|| GoodChannels(r)==7|| ... 
                GoodChannels(r)==9|| GoodChannels(r)==2|| GoodChannels(r)==4 || GoodChannels(r)==6|| ... 
                GoodChannels(r)==8|| GoodChannels(r)==10|| GoodChannels(r)==12|| GoodChannels(r)==14|| ...
                GoodChannels(r)==16||  GoodChannels(r)==7|| GoodChannels(r)==9|| GoodChannels(r)==2|| ...
                GoodChannels(r)==4 || GoodChannels(r)==6|| GoodChannels(r)==8|| GoodChannels(r)==10|| ... 
                GoodChannels(r)==12|| GoodChannels(r)==14|| GoodChannels(r)==16|| GoodChannels(r)==18|| ...
                GoodChannels(r)==20|| GoodChannels(r)==22|| GoodChannels(r)==24 || GoodChannels(r)==26|| ...
                GoodChannels(r)==28|| GoodChannels(r)==30|| GoodChannels(r)==32
              region{r}='PFC';
            elseif GoodChannels(r)==17|| GoodChannels(r)==19|| GoodChannels(r)==21|| GoodChannels(r)==23||...
                GoodChannels(r)==25|| GoodChannels(r)==27|| GoodChannels(r)==29 || GoodChannels(r)==31
              region{r}='CLA';
            elseif GoodChannels(r)==15
              region{r}='ENTI';
            elseif GoodChannels(r)==13
              region{r}='AUD';
            elseif GoodChannels(r)==11
              region{r}='MD';
 else
 end
end 




%% More specific  trial types 



 TrialTypes=num2cell(SessionData.TrialTypes'); 

   %Trialstart 
   trialstart_vec=find(TrialStart_timestamps);
   reward_vec=find(cellfun(@isempty,reward_ts)~=1);
   noreward_vec=find(cellfun(@isempty,reward_ts));
   corr_vec=intersect(trialstart_vec,reward_vec);
   incorr_vec=intersect(trialstart_vec,noreward_vec);
   LON_vec=intersect(find(cellfun(@(x) x<7,TrialTypes)),trialstart_vec);
   LOFF_vec=intersect(find(cellfun(@(x) x>6 & x<13,TrialTypes)),trialstart_vec);
   LON_corr_vec=intersect(corr_vec,LON_vec);
   LON_incorr_vec=intersect(incorr_vec,LON_vec);
   LOFF_corr_vec=intersect(corr_vec,LOFF_vec);
   LOFF_incorr_vec=intersect(incorr_vec,LOFF_vec);

   ts_struct.TrialStart.LON=TrialStart_timestamps(LON_vec);
   ts_struct.TrialStart.LOFF=TrialStart_timestamps(LOFF_vec);
   
   ts_struct.TrialStart.LON_Incorrect=TrialStart_timestamps(LON_incorr_vec);
   ts_struct.TrialStart.LON_Correct=TrialStart_timestamps(LON_corr_vec);
   
   ts_struct.TrialStart.LOFF_Correct=TrialStart_timestamps(LOFF_corr_vec);
   ts_struct.TrialStart.LOFF_Incorrect=TrialStart_timestamps(LOFF_incorr_vec);
   
   ts_struct.TrialStart.Incorrect=TrialStart_timestamps(incorr_vec);
   ts_struct.TrialStart.Correct=TrialStart_timestamps(corr_vec);
   



   
   %Chirp 
   chirp_vec=find(cellfun(@isempty,chirp_ts)~=1);
   reward_vec=find(cellfun(@isempty,reward_ts)~=1);
   noreward_vec=find(cellfun(@isempty,reward_ts));
   corr_vec=intersect(chirp_vec,reward_vec);
   incorr_vec=intersect(chirp_vec,noreward_vec);
   LON_vec=intersect(find(cellfun(@(x) x<7,TrialTypes)),chirp_vec);
   LOFF_vec=intersect(find(cellfun(@(x) x>6 & x<13,TrialTypes)),chirp_vec);
   LON_corr_vec=intersect(corr_vec,LON_vec);
   LON_incorr_vec=intersect(incorr_vec,LON_vec);
   LOFF_corr_vec=intersect(corr_vec,LOFF_vec);
   LOFF_incorr_vec=intersect(incorr_vec,LOFF_vec);

   ts_struct.Chirp.LON=cell2mat(chirp_ts(LON_vec));
   ts_struct.Chirp.LOFF=cell2mat(chirp_ts(LOFF_vec));
   
   ts_struct.Chirp.LON_Incorrect=cell2mat(chirp_ts(LON_incorr_vec));
   ts_struct.Chirp.LON_Correct=cell2mat(chirp_ts(LON_corr_vec));
  
   ts_struct.Chirp.LOFF_Correct=cell2mat(chirp_ts(LOFF_corr_vec));
   ts_struct.Chirp.LOFF_Incorrect=cell2mat(chirp_ts(LOFF_incorr_vec));

   ts_struct.Chirp.Incorrect=cell2mat(chirp_ts(incorr_vec));
   ts_struct.Chirp.Correct=cell2mat(chirp_ts(corr_vec));
   


% Reward
   reward_vec=find(cellfun(@isempty,reward_ts)~=1);
   noreward_vec=find(cellfun(@isempty,reward_ts));
   corr_vec=reward_vec;
   incorr_vec=noreward_vec;
   LON_vec=intersect(find(cellfun(@(x) x<7,TrialTypes)),reward_vec);
   LOFF_vec=intersect(find(cellfun(@(x) x>6 & x<13,TrialTypes)),reward_vec);
   LON_corr_vec=intersect(corr_vec,LON_vec);
   LON_incorr_vec=intersect(incorr_vec,LON_vec);
   LOFF_corr_vec=intersect(corr_vec,LOFF_vec);
   LOFF_incorr_vec=intersect(incorr_vec,LOFF_vec);



  
   ts_struct.Reward.LON=cell2mat(reward_ts(LON_vec));
   ts_struct.Reward.LOFF=cell2mat(reward_ts(LOFF_vec));
   
  
   ts_struct.Reward.LON_Incorrect=cell2mat(reward_ts(LON_incorr_vec));
   ts_struct.Reward.LON_Correct=cell2mat(reward_ts(LON_corr_vec));
   
  
   ts_struct.Reward.LOFF_Correct=cell2mat(reward_ts(LOFF_corr_vec));
   ts_struct.Reward.LOFF_Incorrect=cell2mat(reward_ts(LOFF_incorr_vec));


   ts_struct.Reward.Incorrect=cell2mat(reward_ts(incorr_vec));
   ts_struct.Reward.Correct=cell2mat(reward_ts(corr_vec));
   



   % Forage 

 forage_ts_3=num2cell(zeros(num_trials,1));
    for row=1:length(TrialStart_Index)
        if numel(forage_ts{row,1})>=3 % 
          forage_ts_3{row} =forage_ts{row}(3);
        else 
            forage_ts_3{row}=[];
        end 
    end



   forage_vec=find(cellfun(@isempty,forage_ts_3)~=1);
   reward_vec=find(cellfun(@isempty,reward_ts)~=1);
   noreward_vec=find(cellfun(@isempty,reward_ts));
   corr_vec=intersect(forage_vec,reward_vec);
   incorr_vec=intersect(forage_vec,noreward_vec);
   LON_vec=intersect(find(cellfun(@(x) x<7,TrialTypes)),forage_vec);
   LOFF_vec=intersect(find(cellfun(@(x) x>6 & x<13,TrialTypes)),forage_vec);
   LON_corr_vec=intersect(corr_vec,LON_vec);
   LON_incorr_vec=intersect(incorr_vec,LON_vec);
   LOFF_corr_vec=intersect(corr_vec,LOFF_vec);
   LOFF_incorr_vec=intersect(incorr_vec,LOFF_vec);





   ts_struct.Forage.LON=cell2mat(forage_ts_3(LON_vec));
   ts_struct.Forage.LOFF=cell2mat(forage_ts_3(LOFF_vec));

   
   ts_struct.Forage.LON_Incorrect=cell2mat(forage_ts_3(LON_incorr_vec));
   ts_struct.Forage.LON_Correct=cell2mat(forage_ts_3(LON_corr_vec));
  
   ts_struct.Forage.LOFF_Correct=cell2mat(forage_ts_3(LOFF_corr_vec));
   ts_struct.Forage.LOFF_Incorrect=cell2mat(forage_ts_3(LOFF_incorr_vec));

   ts_struct.Forage.Incorrect=cell2mat(forage_ts_3(incorr_vec));
   ts_struct.Forage.Correct=cell2mat(forage_ts_3(corr_vec));


%%  populate firing rate struct 
if exist('fr_rate')
fr_cell=num2cell(fr_rate);
WidthValley_cell=num2cell(half_valley_width);
WidthPeak_cell=num2cell(half_peak_width);
peak2valley_cell=num2cell(peak2valley);
end 


if ~isempty(SpikeTimeArray)

[spike_struct.SpikeTimes]=SpikeTimeArray{:,3};
[spike_struct.Region]=region{:};
[spike_struct.Region]=region{:};
[spike_struct.FR]=fr_cell{:};
[spike_struct.WidthValley]=WidthValley_cell{:};
[spike_struct.WidthPeak]=WidthPeak_cell{:};
[spike_struct.Peak2Valley]=peak2valley_cell{:};
[spike_struct.AvgWaveform]=Average_Waveforms{:};
chan_cell=num2cell(GoodChannels);
[spike_struct.Chan]=chan_cell{:};
end 

ts_struct_trial=ts_struct;

clearvars ts_struct

ts_struct.Trialstart=trialStart_ts;
ts_struct.Chirp=chirp_ts;
ts_struct.Reward=reward_ts;
ts_struct.forage=forage_ts;
   
        
%% LFP
%     PFC_ch=[1,3,5,7,9,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32];
%     CLA_ch=[17,19,21,23,25,27,29,31];
%     ENTI_ch=15;
%     AUD_ch=13;
%     MD_ch=11;
% 
%     Raw_Data =double(NS6.Data);
%     
%     PFC_lfp=Raw_Data(PFC_ch,:);
%     
%     CLA_lfp=Raw_Data(CLA_ch,:);
% 
%     ENTI_lfp=Raw_Data(ENTI_ch,:);
%     
%     AUD_lfp=Raw_Data(AUD_ch,:);
%     
%     MD_lfp=Raw_Data(MD_ch,:);
% 
%     lfp_struct.PFC=int16(PFC_lfp);
%     lfp_struct.CLA=int16(CLA_lfp);
%     lfp_struct.AUD=int16(AUD_lfp);
%     lfp_struct.ENTI=int16(ENTI_lfp);
%     lfp_struct.MD=int16(MD_lfp);
end 









