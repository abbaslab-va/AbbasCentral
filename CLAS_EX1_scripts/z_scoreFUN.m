function [Z_score_FR, raw_FR]=z_scoreFUN(spike_times,ts,TrialStart_timestamps)

if class(ts)=="cell"
    ts=ts(~cellfun('isempty',ts));
    ts=cell2mat(ts); 
        if size(ts,2)==1
        else 
            ts=ts';
        end 
else 
end 

if isempty(ts)
    Z_score_FR=NaN(700,1);
    raw_FR=NaN(700,1);
else



fs=30000;
offset=(35*fs)/2; % offset in seconds 
bin_size=50*fs/1000; %input bin size in ms


 aligned_SpikeArray=zeros(length(ts),offset*2/bin_size);
    for row=1:length(ts)
        bin_edges=[ts(row)-offset:bin_size:ts(row)+offset];
        aligned_SpikeArray(row,:) = histcounts(spike_times,'BinEdges',bin_edges);
    end 




%plot raster for comfirmation 
% figure()
% bin_size=1*fs/1000;
%  aligned_SpikeArray_raster=zeros(length(ts),offset*2/bin_size);
%     for row=1:length(ts)
%         bin_edges=[ts(row)-offset:bin_size:ts(row)+offset];
%         aligned_SpikeArray_raster(row,:) = histcounts(spike_times,'BinEdges',bin_edges);
%     end 
% rasterplot(find(aligned_SpikeArray_raster'),size(aligned_SpikeArray_raster,1),size(aligned_SpikeArray_raster,2),gca)

aligned_SpikeArray_avg=mean(aligned_SpikeArray,1)*20; % becays 20 50 ms bins fit in a second 

%figure()
%plot(aligned_SpikeArray_avg)

FR_mat_avg_smoothed=smoothdata(aligned_SpikeArray_avg,'gaussian',5);
%FR_mat_avg_smoothed=aligned_SpikeArray_avg;
raw_FR=aligned_SpikeArray_avg;

%Z_score_FR=FR_mat_avg_smoothed; % Use for no Z_scoring 

%figure()
%plot(FR_mat_avg_smoothed)
% figure
% plot(FR_mat_avg_smoothed)
% xline(10/0.05) % 10 seconds/ 50ms bins 




%%% 4 different Z-Score methods: 1) by trial, 2) across trial type, 3) across
%%% all trials. 


%%% 1) Z-Score normalize the the average trial 
% figure()
%Z_score_FR=normalize(FR_mat_avg_smoothed);
% plot(Z_score_FR)


%%% 1) by Trial 
% for t=1:size(FR_mat,2)
%     t_mean=mean(FR_mat(:,t));
%     t_std=std(FR_mat(:,t));
%     for b=1:size(FR_mat,1)
%         Z_FR(b,t)=(FR_mat(b,t)-t_mean)./t_std;
%     end 
% end 
% 
% Z_score_FR=mean(Z_FR,2);



%%% 2) By Trial Type
%Z_score_FR=(mean(FR_mat,2)-mean(mean(FR_mat,2)))./std(mean(FR_mat,2));

%instead of the mean of everthing like above use the mean of a baseline
%period. 
% Z_score_FR=(mean(FR_mat,2)-mean(mean(FR_mat(100:200,:))))./std(mean(FR_mat(100:200,:)));




%%% 3) By All Trial Types 
% fs=30000;
% offset=(15*fs); % offset in seconds 
% bin_size=50*fs/1000; %input bin size in ms
% 
%     aligned_SpikeArray_norm=zeros(length(TrialStart_timestamps),(5*fs)/bin_size);
%     for row=1:length(TrialStart_timestamps)
%         bin_edges=[TrialStart_timestamps{row}+offset:bin_size:TrialStart_timestamps{row}+(offset+5*fs)];
%         aligned_SpikeArray_norm(row,:) = histcounts(spike_times,'BinEdges',bin_edges);
%     end
% 
% aligned_SpikeArray_norm_avg=mean(aligned_SpikeArray_norm)*20; % becays 20 50 ms bins fit in a second 



%FR_mat_avg_norm_smoothed=smoothdata(aligned_SpikeArray_norm_avg,'gaussian');
% figure()
% plot(FR_mat_avg_smoothed)

Z_score_FR=(FR_mat_avg_smoothed-mean(FR_mat_avg_smoothed(200:300)))./std(FR_mat_avg_smoothed(200:300));

%Z_score_FR=normalize(FR_mat_avg_smoothed);

% figure()
% plot(Z_score_FR)

% 
%  for trial=1:length(TrialStart_timestamps)
%         time = 1;
%         for bin = 1:bin_size
%            FR_mat_all(bin,trial) = numel(nonzeros(aligned_SpikeArray_norm(trial,time:time+ advance)))/Hz_convert;
%            time = time +  window;
%         end
%  end
% 
% 
%  Z_score_FR=(mean(FR_mat,2)-mean(mean(FR_mat_all,2)))./std(mean(FR_mat_all,2));


%% Z scoring each bin PSTH to Baseline 

% PSTH=sum(aligned_SpikeArray,1);
% FR_mat=zeros(bin_size,1);
%         time = 1;
%         for bin = 1:bin_size
%            FR_mat(bin) = numel(nonzeros(PSTH(time:time+ advance)))/Hz_convert;
%            time = time +  window;
%         end
%    
% 
%  Z_score_FR=(mean(FR_mat(350:360))-mean(FR_mat(200:300)))./std(FR_mat(200:300));





end