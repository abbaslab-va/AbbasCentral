% PLOT the z scored firing rates in FiringRateStruct_ALL 
%load('D:\CLAS_EX1\Analysis_Structs\FiringRateStruct_ALL.mat')


%%
% find region index 

for neuron=1:size(FR_combined.Correct,2) 
   if  spike_struct_combined(neuron).Region=="PFC"
       region(neuron)=1;
   elseif spike_struct_combined(neuron).Region=="CLA"
       region(neuron)=2;
   elseif spike_struct_combined(neuron).Region=="AUD"
       region(neuron)=3;
   elseif spike_struct_combined(neuron).Region=="ENTI"
       region(neuron)=4;
   elseif spike_struct_combined(neuron).Region=="MD"
       region(neuron)=5;
   end 
end

for neuron=1:size(spike_struct_combined,1)
    FR(neuron)=spike_struct_combined(neuron).FR;
end



%%  k-means clustering 


% X(:,3)=[FR_combined.LON.FR];
% X(:,1)=[FR_combined.LON.Peak2valley];
% X(:,2)=[FR_combined.LON.WidthPeak];
% 
% 
% opts = statset('Display','final');
% [cluster_idx,C] = kmeans(X,2,'Distance','cityblock',...
%     'Replicates',5,'Options',opts);
% 
% figure;
% scatter3(X(cluster_idx==1,1),X(cluster_idx==1,2),X(cluster_idx==1,3), 'MarkerEdgeColor','k',...
%         'MarkerFaceColor',[0 .75 .75])
% hold on
% 
% scatter3(X(cluster_idx==2,1),X(cluster_idx==2,2),X(cluster_idx==2,3), 'MarkerEdgeColor','g',...
%         'MarkerFaceColor',[0 .75 .75])
% 
% % scatter3(X(cluster_idx==3,1),X(cluster_idx==3,2),X(cluster_idx==3,3), 'MarkerEdgeColor','b',...
% %         'MarkerFaceColor',[0 .75 .75])
% % 
% % scatter3(X(cluster_idx==4,1),X(cluster_idx==4,2),X(cluster_idx==4,3), 'MarkerEdgeColor','c',...
% %         'MarkerFaceColor',[0 .75 .75])
% 
% 



hold off

%% GMM 
%based on https://doi.org/10.1038/nn799, and doi:10.1038/nature12176. I
%can use AP(spike)width and FR



Y(:,1)=[spike_struct_combined.WidthPeak]/30;
Y(:,2)=[spike_struct_combined.FR];

%Y=Y(region==1,:);

gm = fitgmdist(Y,2);

[cluster_idx,nlogL,P,logpdf,d2] = cluster(gm,Y);

figure;
h=gscatter(Y(:,1),Y(:,2),cluster_idx);
legend('Putative PVs','Other','Location','best');
h(1).Color='r';
h(2).Color='k';

set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out')
ax=gca
ax.LineWidth=1.5
ylabel('Firing Rate (Hz)')
xlabel('Spike Width (ms)')
box off

%scatter3([FR_combined.LON.WidthPeak],[FR_combined.LON.Peak2valley],[FR_combined.LON.FR])

figure
scatter(Y(:,1),Y(:,2),10,P(:,1))
c2 = colorbar;
ylabel(c2,'Posterior Probability of Component 1')
caxis([0 1])


figure
scatter(Y(:,1),Y(:,2),10,P(:,2))
c2 = colorbar;
ylabel(c2,'Posterior Probability of Component 2')
caxis([0 1])




%% soft GMM

% Y(:,1)=[FR_combined.LON.WidthPeak]/30;
% Y(:,2)=[FR_combined.LON.FR];
% 
% X=Y;
% 
% gm = fitgmdist(X,2);
% threshold = [0.4 0.6];
% P = posterior(gm,X);
% n = size(X,1);
% [~,order] = sort(P(:,1));
% 
% figure
% plot(1:n,P(order,1),'r-',1:n,P(order,2),'b-')
% legend({'Cluster 1', 'Cluster 2'})
% ylabel('Cluster Membership Score')
% xlabel('Point Ranking')
% title('GMM with Full Unshared Covariances')
% 
% idx = cluster(gm,X);
% idxBoth = find(P(:,1)>=threshold(1) & P(:,1)<=threshold(2)); 
% numInBoth = numel(idxBoth)
% 
% figure
% gscatter(X(:,1),X(:,2),idx,'rb','+o',5)
% hold on
% plot(X(idxBoth,1),X(idxBoth,2),'ko','MarkerSize',10)
% legend({'Cluster 1','Cluster 2','Both Clusters'},'Location','SouthEast')
% title('Scatter Plot - GMM with Full Unshared Covariances')
% hold off

%% K-means 
% 
%  opts = statset('Display','final');
%  [cluster_idx,C] = kmeans(X,2,'Distance','cityblock',...
%      'Replicates',5,'Options',opts); 
% Y(:,1)=[FR_combined.LON.WidthPeak];
% Y(:,2)=[FR_combined.LON.FR];
% 
% 
%  opts = statset('Display','final');
%  [cluster_idx,C] = kmeans(Y,2,'Distance','sqeuclidean',...
%      'Replicates',5,'Options',opts); 
% Y(:,1)=[FR_combined.LON.WidthPeak];
% Y(:,2)=[FR_combined.LON.FR];
% 
% figure;
% gscatter(Y(:,1),Y(:,2),cluster_idx);
% legend('Cluster 1','Cluster 2','Location','best');





% % for 3D
% figure
% scatter3(Y(idx==1,1),Y(idx==1,2),Y(idx==1,3), 'MarkerEdgeColor','k',...
%         'MarkerFaceColor',[0 .75 .75])
% hold on
% 
% scatter3(Y(idx==2,1),Y(idx==2,2),Y(idx==2,3), 'MarkerEdgeColor','g',...
%         'MarkerFaceColor',[0 .75 .75])
% 
% scatter3(Y(idx==3,1),Y(idx==3,2),Y(idx==3,3), 'MarkerEdgeColor','b',...
%         'MarkerFaceColor',[0 .75 .75])


%% My clustering by Eye says 

% Y(:,1)=[spike_struct_combined.WidthPeak]/30;
% Y(:,2)=[spike_struct_combined.FR];
% 
% 
% cluster_idx_fr=find([spike_struct_combined.FR]>10);
% cluster_idx_width=find([spike_struct_combined.WidthPeak]/30<0.24);
% %cluster_idx_1=intersect(cluster_idx_fr,cluster_idx_width);
% cluster_idx_1=intersect(cluster_idx_fr,cluster_idx_width);
% cluster_idx=zeros(1,length([spike_struct_combined.FR]));
% for n=1:length(cluster_idx)
%     if n==96 || n==183
%         cluster_idx(n)=2;    
%     elseif find(cluster_idx_1==n)
%         cluster_idx(n)=1;    
%     else 
%          cluster_idx(n)=2;
%     end 
% end 
% 
% figure;
% h=gscatter(Y(:,1),Y(:,2),cluster_idx);
% legend('Putative PVs','Other','Location','best');
% h(1).Color='r';
% h(2).Color='k';
% 
% set(gca,'FontSize',24);
% set(gca,'FontName','Arial');
% set(gca, 'TickDir', 'out')
% ax=gca
% ax.LineWidth=1.5
% ylabel('Firing Rate (Hz)')
% xlabel('Spike Width (ms)')
% box off

%% find example Waveform 
% figure
% clus1_c=1;
% clus2_c=1;
% hold on
% for n=1:length(spike_struct_combined)
%     if cluster_idx(n)==1
%         figure()
%         p1=plot(spike_struct_combined(n).AvgWaveform*-1,'r');
%         %p1.Color(4)=0.2;
%         clus1(clus1_c,:)=spike_struct_combined(n).AvgWaveform*-1;
%         clus1_c=clus1_c+1;
%         title(num2str(n))
%         pause()
%     else
%         figure()
%         p2=plot(spike_struct_combined(n).AvgWaveform*-1,'k');
%         %p2.Color(4)=0.1;
%         clus2(clus2_c,:)=spike_struct_combined(n).AvgWaveform*-1;
%         clus2_c=clus2_c+1;
%         pause()
%         title(num2str(n))
%     end 
% end
% 
% clus1_avg=mean(clus1);
% clus2_avg=mean(clus2);
% plot(clus1_avg,'r',LineWidth=2)
% plot(clus2_avg,'k',LineWidth=2)
% xlim([30 90])
% xticks([30:15:90])
% xticklabels([30:15:90]/30)
% set(gca,'YTick',[])
% set(gca,'FontSize',24);
% set(gca,'FontName','Arial');
% set(gca, 'TickDir', 'out')
% ax=gca
% ax.LineWidth=1.5
% xlabel('Time(ms)')


hold on
p1=plot(spike_struct_combined(199).AvgWaveform*-1,'r',LineWidth=4);
p2=plot(spike_struct_combined(159).AvgWaveform*-1,'k',LineWidth=4);
axis off

align1='Chirp' ;
align2='Chirp' ;
TType1='LOFF';
TType2='LON';

[FR1_PFC_PV_sorted, FR1_PFC_nPV_sorted, FR1_CLA_nPV_sorted, FR2_PFC_PV_sorted, FR2_PFC_nPV_sorted, FR2_CLA_nPV_sorted]=plot_heatmap_FUN(FR_combined,region,cluster_idx,align1,align2,TType1,TType2);

%% LASer OFF HITS and MISSES 
figure;
 t=tiledlayout(4,2)
 h(1)=nexttile()
    surf(FR1_PFC_PV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    %xticks([0   100   200   300  355  400   500   600   700])
    %xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_PV_sorted,2)])
    %xlim([200 500])
    %title('ACC Laser OFF Hits')
    %xtickangle(45)
    ylabel('Neuron')
    %xlabel('Seconds')
   % set(gca,'XTick',[])
    caxis([-3 3])
    xlim([200 500])
    colorbar

h(2)=nexttile()
   surf(FR2_PFC_PV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_PV_sorted,2)])
    %xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
    caxis([-3 3])
     colorbar


%     set(h, 'CLim', [-2 2])
% 
%     cbh = colorbar(h(end)); 
%     cbh.Layout.Tile = 'east'; 
% 
%     t.TileSpacing = 'tight';
  h(3)=nexttile() 
  surf(FR1_PFC_nPV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_nPV_sorted,2)])
    %xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
   caxis([-3 3])
    colorbar


 h(4)=nexttile() 
  surf(FR2_PFC_nPV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR2_PFC_nPV_sorted,2)])
    %xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
    caxis([-6 6])
    colorbar


 h(5)=nexttile()
    surf(FR1_CLA_PV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    %xticks([0   100   200   300  355  400   500   600   700])
    %xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_CLA_PV_sorted,2)])
    %xlim([200 500])
    %title('ACC Laser OFF Hits')
    %xtickangle(45)
    ylabel('Neuron')
    %xlabel('Seconds')
   % set(gca,'XTick',[])
      caxis([-3 3])
    %xlim([200 500])
    colorbar


h(6)=nexttile()
   surf(FR2_CLA_PV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_CLA_PV_sorted,2)])
    %xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
       caxis([-3 3])

%     set(h, 'CLim', [-2 2])
% 
%     cbh = colorbar(h(end)); 
%     cbh.Layout.Tile = 'east'; 
% 
%     t.TileSpacing = 'tight';
  h(7)=nexttile() 
  surf(FR1_CLA_nPV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_CLA_nPV_sorted,2)])
    %xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
     caxis([-3 3])
    colorbar



 h(8)=nexttile() 
  surf(FR2_CLA_nPV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR2_CLA_nPV_sorted,2)])
    %xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
   caxis([-3 3])
     colorbar



%% For seminar 01/30/2022
align1='Chirp' ;
align2='Chirp' ;
TType1='LON_Correct';
TType2='LON_Incorrect';
[FR1_PFC_PV_sorted_lon, FR1_PFC_nPV_sorted_lon,FR1_CLA_PV_sorted_lon, FR1_CLA_nPV_sorted_lon,FR2_PFC_PV_sorted_lon, FR2_PFC_nPV_sorted_lon,FR2_CLA_PV_sorted_lon, FR2_CLA_nPV_sorted_lon]=plot_heatmap_FUN(FR_combined,region,cluster_idx,align1,align2,TType1,TType2);
%%
figure;
 t=tiledlayout(4,2)
 h(1)=nexttile()
    surf(FR1_PFC_PV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    %xticks([0   100   200   300  355  400   500   600   700])
    %xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_PV_sorted,2)])
    %xlim([200 500])
    %title('ACC Laser OFF Hits')
    %xtickangle(45)
    ylabel('Neuron')
    %xlabel('Seconds')
   % set(gca,'XTick',[])
    caxis([-3 3])
    xlim([200 500])
    colorbar

h(2)=nexttile()
   surf(FR2_PFC_PV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_PV_sorted,2)])
    %xlim([200 500])
    xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
    caxis([-3 3])
     colorbar


%     set(h, 'CLim', [-2 2])
% 
%     cbh = colorbar(h(end)); 
%     cbh.Layout.Tile = 'east'; 
% 
%     t.TileSpacing = 'tight';
  h(3)=nexttile() 
  surf(FR1_PFC_nPV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_nPV_sorted,2)])
    xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
   caxis([-3 3])
    colorbar


 h(4)=nexttile() 
  surf(FR2_PFC_nPV_sorted','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR2_PFC_nPV_sorted,2)])
    xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
    caxis([-3 3])
    colorbar


 h(5)=nexttile()
    surf(FR1_PFC_PV_sorted_lon','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    %xticks([0   100   200   300  355  400   500   600   700])
    %xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_PV_sorted_lon,2)])
    %xlim([200 500])
    %title('ACC Laser OFF Hits')
    %xtickangle(45)
    ylabel('Neuron')
    %xlabel('Seconds')
   % set(gca,'XTick',[])
      caxis([-3 3])
    xlim([200 500])
    colorbar


h(6)=nexttile()
   surf(FR2_PFC_PV_sorted_lon','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_PV_sorted_lon,2)])
    xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
       caxis([-3 3])
       colorbar


  h(7)=nexttile() 
  surf(FR1_PFC_nPV_sorted_lon','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC_nPV_sorted_lon,2)])
    xlim([200 500])
    xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
     caxis([-3 3])
    colorbar



 h(8)=nexttile() 
  surf(FR2_PFC_nPV_sorted_lon','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR2_PFC_nPV_sorted_lon,2)])
    xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
   caxis([-3 3])
     colorbar








%% Unsorted Hits and misses, LAser oFF 
figure;
 t=tiledlayout(2,2)
 h(1)=nexttile()
    surf(FR1_PFC_PV','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    %xticks([0   100   200   300  355  400   500   600   700])
    %xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_PFC,2)])
    %xlim([200 500])
    %title('ACC Laser OFF Hits')
    %xtickangle(45)
    ylabel('Neuron')
    %xlabel('Seconds')
   % set(gca,'XTick',[])
    caxis([-3 3])
    %xlim([200 500])
    colorbar




  h(2)=nexttile() 
  surf(FR2_PFC','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR2_PFC,2)])
    %xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    ylabel('Neuron')
    caxis([-3 3])
    colorbar

h(3)=nexttile()
   surf(FR1_CLA','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR1_CLA,2)])
    %xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    %ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
    ylabel('Neuron')
    caxis([-3 3])
    colorbar


 h(4)=nexttile() 
  surf(FR2_CLA','EdgeColor','none') 
    view(2)
    hold on
    xline(350)
    xline(360)
    xticks([0   100   200   300  350  400   500   600   700])
    xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
    ylim([0 size(FR2_CLA,2)])
   % xlim([200 500])
    %xlim([200 500])
    %title('CLA Laser OFF Misses')
    ylabel('Neuron')
    %xlabel('Seconds')
    %set(gca,'YTick',[])
   caxis([-3 3])
    colorbar

%% population Averages
align1='Chirp' ;
align2='Chirp' ;
TType1='LOFF';
TType2='LON';
[FR1_PFC_PV_sorted_lon, FR1_PFC_nPV_sorted_lon,FR1_CLA_PV_sorted_lon, FR1_CLA_nPV_sorted_lon,FR2_PFC_PV_sorted_lon, FR2_PFC_nPV_sorted_lon,FR2_CLA_PV_sorted_lon, FR2_CLA_nPV_sorted_lon]=plot_heatmap_FUN(FR_combined,region,cluster_idx,align1,align2,TType1,TType2);
%scatter(mean(FR1_PFC_PV_sorted(350:360,:)),mean(FR2_PFC_PV_sorted(350:360,:)))


FR1_PFC_PV_sorted(isinf(FR1_PFC_PV_sorted))=NaN;
FR1_PFC_nPV_sorted(isinf(FR1_PFC_nPV_sorted))=NaN;
FR2_PFC_PV_sorted(isinf(FR2_PFC_PV_sorted))=NaN;
FR2_PFC_nPV_sorted(isinf(FR2_PFC_nPV_sorted))=NaN;

FR1_PFC_PV_sorted_lon(isinf(FR1_PFC_PV_sorted_lon))=NaN;
FR1_PFC_nPV_sorted_lon(isinf(FR1_PFC_nPV_sorted_lon))=NaN;
FR2_PFC_PV_sorted_lon(isinf(FR2_PFC_PV_sorted_lon))=NaN;
FR2_PFC_nPV_sorted_lon(isinf(FR2_PFC_nPV_sorted_lon))=NaN;






FR1_PFC_PV_sorted_avg=nanmean(abs(FR1_PFC_PV_sorted),2);
FR1_PFC_PV_sorted_sem=sem(abs(FR1_PFC_PV_sorted),2);

FR1_PFC_nPV_sorted_avg=nanmean(abs(FR1_PFC_nPV_sorted),2);
FR1_PFC_nPV_sorted_sem=sem(abs(FR1_PFC_nPV_sorted),2);

FR2_PFC_PV_sorted_avg=nanmean(abs(FR2_PFC_PV_sorted),2);
FR2_PFC_PV_sorted_sem=sem(abs(FR2_PFC_PV_sorted),2);

FR2_PFC_nPV_sorted_avg=nanmean(abs(FR2_PFC_nPV_sorted),2);
FR2_PFC_nPV_sorted_sem=sem(abs(FR2_PFC_nPV_sorted),2);



% FR1_PFC_PV_sorted_avg=nanmean(FR1_PFC_PV_sorted,2);
% FR1_PFC_PV_sorted_sem=sem(FR1_PFC_PV_sorted,2)
% 
% FR1_PFC_nPV_sorted_avg=nanmean(FR1_PFC_nPV_sorted,2);
% FR1_PFC_nPV_sorted_sem=sem(FR1_PFC_nPV_sorted,2)
% 
% FR2_PFC_PV_sorted_avg=nanmean(FR2_PFC_PV_sorted,2);
% FR2_PFC_PV_sorted_sem=sem(FR2_PFC_PV_sorted,2)
% 
% FR2_PFC_nPV_sorted_avg=nanmean(FR2_PFC_nPV_sorted,2);
% FR2_PFC_nPV_sorted_sem=sem(FR2_PFC_nPV_sorted,2)


%% lon 
figure()
surf(FR1_PFC_nPV_sorted_lon')
view(2)
shading interp
caxis([-3 3])
figure()
surf(FR2_PFC_nPV_sorted_lon')
view(2)
shading interp
caxis([-3 3])

FR1_PFC_PV_sorted_avg_lon=nanmean(abs(FR1_PFC_PV_sorted_lon),2);
FR1_PFC_PV_sorted_sem_lon=sem(abs(FR1_PFC_PV_sorted_lon),2);

FR1_PFC_nPV_sorted_avg_lon=nanmean(abs(FR1_PFC_nPV_sorted_lon),2);
FR1_PFC_nPV_sorted_sem_lon=sem(abs(FR1_PFC_nPV_sorted_lon),2);

FR2_PFC_PV_sorted_avg_lon=nanmean(abs(FR2_PFC_PV_sorted_lon),2);
FR2_PFC_PV_sorted_sem_lon=sem(abs(FR2_PFC_PV_sorted_lon),2);

FR2_PFC_nPV_sorted_avg_lon=nanmean(abs(FR2_PFC_nPV_sorted_lon),2);
FR2_PFC_nPV_sorted_sem_lon=sem(abs(FR2_PFC_nPV_sorted_lon),2);




% FR1_PFC_PV_sorted_avg_lon=nanmean(FR1_PFC_PV_sorted_lon,2);
% FR1_PFC_PV_sorted_sem_lon=sem(FR1_PFC_PV_sorted_lon,2)
% 
% FR1_PFC_nPV_sorted_avg_lon=nanmean(FR1_PFC_nPV_sorted_lon,2);
% FR1_PFC_nPV_sorted_sem_lon=sem(FR1_PFC_nPV_sorted_lon,2)
% 
% FR2_PFC_PV_sorted_avg_lon=nanmean(FR2_PFC_PV_sorted_lon,2);
% FR2_PFC_PV_sorted_sem_lon=sem(FR2_PFC_PV_sorted_lon,2)
% 
% FR2_PFC_nPV_sorted_avg_lon=nanmean(FR2_PFC_nPV_sorted_lon,2);
% FR2_PFC_nPV_sorted_sem_lon=sem(FR2_PFC_nPV_sorted_lon,2)
% 



%%
figure
subplot(211)
hold on 
ShadedErrorPlot(1:700,FR1_PFC_PV_sorted_avg,FR1_PFC_PV_sorted_sem,'r','r',0.5)
ShadedErrorPlot(1:700,FR1_PFC_nPV_sorted_avg,FR1_PFC_nPV_sorted_sem,'k','k',0.5)
%ShadedErrorPlot(1:700,FR1_PFC_PV_sorted_avg_lon,FR1_PFC_PV_sorted_sem_lon,'b','b',0.5)
xline(350)
xline(360)
xlim([300 400])
ylim([0 3.5])
xticks([0   100   200   300  350  400   500   600   700])
xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out')
ax=gca
ax.LineWidth=1.5
ylabel('Correct')
xlabel('Time (s)')


subplot(212)
hold on 
ShadedErrorPlot(1:700,FR2_PFC_PV_sorted_avg,FR2_PFC_PV_sorted_sem,'r','r',0.5)
ShadedErrorPlot(1:700,FR2_PFC_nPV_sorted_avg,FR2_PFC_nPV_sorted_sem,'k','k',0.5)
%ShadedErrorPlot(1:700,FR2_PFC_PV_sorted_avg_lon,FR2_PFC_PV_sorted_sem_lon,'b','b',0.5)
xlim([300 400])
ylim([0 3.5])
xline(350)
xline(360)
xticks([0   100   200   300  350  400   500   600   700])
xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out')
ax=gca
ax.LineWidth=1.5
ylabel('Incorrect')
xlabel('Time (s)')


ShadedErrorPlot(1:700,FR1_PFC_PV_sorted_avg,FR1_PFC_PV_sorted_sem,'r','r',0.5)
ShadedErrorPlot(1:700,FR2_PFC_nPV_sorted_avg,FR2_PFC_nPV_sorted_sem,'k','k',0.5)

%% Run Stats 
% for n=1:size(FR1_PFC_PV_sorted,2)
%  b=discretize(1:700,1:10:701);
%  splitapply(@mean,FR1_PFC_PV_sorted(:,n)',b)
% 
% yX=reshape([FR1_PFC_PV_sorted FR1_PFC_nPV_sorted FR2_PFC_PV_sorted FR2_PFC_nPV_sorted],[1 434*700]);
% C    = cell(1, size(FR1_PFC_PV_sorted,1)*size(FR1_PFC_PV_sorted,2));
% C(:) = {'PV'};
% 
% g1a=C;
% 
% C    = cell(1, size(FR1_PFC_nPV_sorted,1)*size(FR1_PFC_nPV_sorted,2));
% C(:) = {'nPV'};
% 
% g1b=C;
% 
% C    = cell(1, size(FR2_PFC_PV_sorted,1)*size(FR2_PFC_PV_sorted,2));
% C(:) = {'PV'};
% 
% g1c=C;
% 
% C    = cell(1, size(FR2_PFC_nPV_sorted,1)*size(FR2_PFC_nPV_sorted,2));
% C(:) = {'nPV'};
% 
% g1d=C;
% 
% g1=[g1a g1b g1c g1d];
% 
% 
% %
% C    = cell(1, size(FR1_PFC_PV_sorted,1)*size(FR1_PFC_PV_sorted,2));
% C(:) = {'Correct'};
% 
% g2a=C;
% 
% C    = cell(1, size(FR1_PFC_nPV_sorted,1)*size(FR1_PFC_nPV_sorted,2));
% C(:) = {'Correct'};
% 
% g2b=C;
% 
% C    = cell(1, size(FR2_PFC_PV_sorted,1)*size(FR2_PFC_PV_sorted,2));
% C(:) = {'Incorrect'};
% 
% g2c=C;
% 
% C    = cell(1,  size(FR2_PFC_nPV_sorted,1)*size(FR2_PFC_nPV_sorted,2));
% C(:) = {'Incorrect'};
% 
% g2d=C;
% 
% g2=[g2a g2b g2c g2d];
% 
% 
% g3=reshape(repmat([1:700],1,434),[1 434*700]);
% 
% 
% p = anovan(yX,{g1 g2 g3},'model','interaction','varnames',{'g1','g2','g3'})
%%  LOFF vs LON


figure
subplot(211)
hold on 
ShadedErrorPlot(1:700,FR1_PFC_PV_sorted_avg_lon,FR1_PFC_PV_sorted_sem_lon,'r','r',0.5)
ShadedErrorPlot(1:700,FR1_PFC_nPV_sorted_avg_lon,FR1_PFC_nPV_sorted_sem_lon,'k','k',0.5)
ShadedErrorPlot(1:700,FR1_PFC_PV_sorted_avg_lon,FR1_PFC_PV_sorted_sem_lon,'b','b',0.5)
xline(350)
xline(360)
xlim([300 400])
ylim([-1 3.5])
xticks([0   100   200   300  350  400   500   600   700])
xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out')
ax=gca
ax.LineWidth=1.5
ylabel('LOFF')
xlabel('Time (s)')


subplot(212)
hold on 
ShadedErrorPlot(1:700,FR2_PFC_PV_sorted_avg_lon,FR2_PFC_PV_sorted_sem_lon,'r','r',0.5)
ShadedErrorPlot(1:700,FR2_PFC_nPV_sorted_avg_lon,FR2_PFC_nPV_sorted_sem_lon,'k','k',0.5)
%ShadedErrorPlot(1:700,FR2_PFC_PV_sorted_avg_lon,FR2_PFC_PV_sorted_sem_lon,'b','b',0.5)
xlim([300 400])
ylim([-1 3.5])
xline(350)
xline(360)
xticks([0   100   200   300  350  400   500   600   700])
xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out')
ax=gca
ax.LineWidth=1.5
ylabel('LON')
xlabel('Time (s)')


%%

figure
subplot(211)
hold on 
%ShadedErrorPlot(1:700,FR1_PFC_PV_sorted_avg,FR1_PFC_PV_sorted_sem,'r','r',0.5)
ShadedErrorPlot(1:700,FR1_PFC_nPV_sorted_avg,FR1_PFC_nPV_sorted_sem,'k','k',0.5)
ShadedErrorPlot(1:700,FR2_PFC_nPV_sorted_avg_lon,FR2_PFC_nPV_sorted_sem_lon,'b','b',0.5)
%ShadedErrorPlot(1:700,FR1_PFC_PV_sorted_avg_lon,FR1_PFC_PV_sorted_sem_lon,'b','b',0.5)
xline(350)
xline(360)
xlim([300 400])
ylim([0 3.5])
xticks([0   100   200   300  350  400   500   600   700])
xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out')
ax=gca
ax.LineWidth=1.5
ylabel('Correct')
xlabel('Time (s)')


subplot(212)
hold on 
ShadedErrorPlot(1:700,FR1_PFC_PV_sorted_avg,FR1_PFC_PV_sorted_sem,'k','k',0.5)
ShadedErrorPlot(1:700,FR2_PFC_PV_sorted_avg_lon,FR2_PFC_PV_sorted_sem_lon,'b','b',0.5)
xlim([300 400])
ylim([0 3.5])
xline(350)
xline(360)
xticks([0   100   200   300  350  400   500   600   700])
xticklabels([{'-17.5'} {'-12.5'} {'-7.5'}  {'-2.5'} {'Chirp'} {'2.5'} {'7.5'} {'12.5'} {'17.5'}])
set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out')
ax=gca
ax.LineWidth=1.5
ylabel('Incorrect')
xlabel('Time (s)')





    
%% 




