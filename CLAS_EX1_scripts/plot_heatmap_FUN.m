function [FR1_PFC_PV_sorted, FR1_PFC_nPV_sorted, FR1_CLA_nPV_sorted,FR2_PFC_PV_sorted, FR2_PFC_nPV_sorted, FR2_CLA_nPV_sorted]=plot_heatmap_FUN(FR_combined,region,cluster_idx,align1,align2,TType1,TType2)

% Now create  a matrix by region 
%clearvars -except FiringRateStruct_ALL FR region FR_combined cluster_idx
%Select alignments and trial types 

%TType3='LON_Correct';
%TType4='LON_Incorrect';
%TType5='LON';


for n=1:260
    FR_mat(:,n)=FR_combined.(TType1)(n).(align1);
    FR_mat2(:,n)=FR_combined.(TType2)(n).(align1);
end 
% FR_mat3=[FR_combined.(TType3).(align1)];
% FR_mat4=[FR_combined.(TType4).(align1)];
% 
% FR_mat5=[FR_combined.(TType5).(align1)];
% FR_mat6=[FR_combined.(TType2).(align2)];
% FR_mat7=[FR_combined.(TType3).(align2)];
% FR_mat8=[FR_combined.(TType4).(align2)];
   
[B_region,idx_region]=sort(region);
FR_mat_region= FR_mat(:,idx_region);
FR_mat2_region= FR_mat2(:,idx_region);

cluster_region=cluster_idx(idx_region);
% FR_mat3_region= FR_mat3(:,idx_region);
% FR_mat4_region= FR_mat4(:,idx_region);
% FR_mat5_region= FR_mat5(:,idx_region);
% FR_mat6_region= FR_mat6(:,idx_region);
% FR_mat7_region= FR_mat7(:,idx_region);
% FR_mat8_region= FR_mat8(:,idx_region);

PFC_region_lims=find(B_region==1);
CLA_region_lims=find(B_region==2);

cluster_region_PFC=cluster_region(PFC_region_lims(1): PFC_region_lims(end));
cluster_region_CLA=cluster_region(CLA_region_lims(1): CLA_region_lims(end));

FR1_PFC=FR_mat_region(:,PFC_region_lims(1): PFC_region_lims(end));
FR1_CLA=FR_mat_region(:,CLA_region_lims(1): CLA_region_lims(end));

FR2_PFC=FR_mat2_region(:,PFC_region_lims(1): PFC_region_lims(end));
FR2_CLA=FR_mat2_region(:,CLA_region_lims(1): CLA_region_lims(end));

% Now sort by  cluster
clusPV_idx_PFC=find(cluster_region_PFC==1);
clusPV_idx_CLA=find(cluster_region_CLA==1);
clus_nPV_idx_PFC=find(cluster_region_PFC~=1);
clus_nPV_idx_CLA=find(cluster_region_CLA~=1);


FR1_PFC_PV=FR1_PFC(:,clusPV_idx_PFC);
FR1_CLA_PV=FR1_CLA(:,clusPV_idx_CLA);

FR1_PFC_nPV=FR1_PFC(:,clus_nPV_idx_PFC);
FR1_CLA_nPV=FR1_CLA(:,clus_nPV_idx_CLA);


FR2_PFC_PV=FR2_PFC(:,clusPV_idx_PFC);
FR2_CLA_PV=FR2_CLA(:,clusPV_idx_CLA);

FR2_PFC_nPV=FR2_PFC(:,clus_nPV_idx_PFC);
FR2_CLA_nPV=FR2_CLA(:,clus_nPV_idx_CLA);



% % make cutofs and seperate Hi an low FR 
% 
% %[minValue,closestIndex_PFC] = min(abs(b_clus_PFC-5))
% [minValue,closestIndex_CLA] = min(abs(b_clus_CLA-5))
% 
% FR1_PFC_low=FR1_PFC_clus(:,1:closestIndex_PFC);
% FR1_CLA_low=FR1_CLA_clus(:,1:closestIndex_CLA);
% 
% FR1_PFC_high=FR1_PFC_clus(:,closestIndex_PFC+1:size(FR1_PFC_clus,2));
% FR1_CLA_high=FR1_CLA_clus(:,closestIndex_CLA+1:size(FR1_CLA_clus,2));
% 
% FR2_PFC_low=FR2_PFC_clus(:,1:closestIndex_PFC);
% FR2_CLA_low=FR2_CLA_clus(:,1:closestIndex_CLA);
% 
% FR2_PFC_high=FR2_PFC_clus(:,closestIndex_PFC+1:size(FR2_PFC_clus,2));
% FR2_CLA_high=FR2_CLA_clus(:,closestIndex_CLA+1:size(FR2_CLA_clus,2));



% FR3_PFC=FR_mat3_region(:,PFC_region_lims(1): PFC_region_lims(end));
% FR3_CLA=FR_mat3_region(:,CLA_region_lims(1): CLA_region_lims(end));
% 
% FR4_PFC=FR_mat4_region(:,PFC_region_lims(1): PFC_region_lims(end));
% FR4_CLA=FR_mat4_region(:,CLA_region_lims(1): CLA_region_lims(end));
% 
% 
% %
% FR5_PFC=FR_mat5_region(:,PFC_region_lims(1): PFC_region_lims(end));
% FR5_CLA=FR_mat5_region(:,CLA_region_lims(1): CLA_region_lims(end));
% 
% FR6_PFC=FR_mat6_region(:,PFC_region_lims(1): PFC_region_lims(end));
% FR6_CLA=FR_mat6_region(:,CLA_region_lims(1): CLA_region_lims(end));
% 
% FR7_PFC=FR_mat7_region(:,PFC_region_lims(1): PFC_region_lims(end));
% FR7_CLA=FR_mat7_region(:,CLA_region_lims(1): CLA_region_lims(end));
% 
% FR8_PFC=FR_mat8_region(:,PFC_region_lims(1): PFC_region_lims(end));
% FR8_CLA=FR_mat8_region(:,CLA_region_lims(1): CLA_region_lims(end));


%% Now sort the first PFC and CLA matrix by activity 


bin_size=700;
bin_range=[350:360];
%bin_range=[550:650]; % For trial start begause the ITI start at trial start  sort by the lights
% turning on 
bin_range_after=[360:370];




for n=1:size(FR1_PFC_PV,2)
    diff_list_FR1_PFC_PV(n)=mean(FR1_PFC_PV(bin_range,n))-mean(FR1_PFC_PV(bin_range_after,n));
end 
[diff_list_FR1_PFC_PV_sorted,diff_FR1_PFC_PV_idx]=sort(diff_list_FR1_PFC_PV); 

FR1_PFC_PV_sorted=FR1_PFC_PV(:,diff_FR1_PFC_PV_idx);

for n=1:size(FR1_PFC_nPV,2)
    diff_list_FR1_PFC_nPV(n)=mean(FR1_PFC_nPV(bin_range,n))-mean(FR1_PFC_nPV(bin_range_after,2));
end 
[diff_list_FR1_PFC_nPV_sorted,diff_FR1_PFC_nPV_idx]=sort(diff_list_FR1_PFC_nPV); 

FR1_PFC_nPV_sorted=FR1_PFC_nPV(:,diff_FR1_PFC_nPV_idx);
    
% % now sort by activity for CLA FR1
% for n=1:size(FR1_CLA_PV,2)
%     diff_list_FR1_CLA_PV(n)=mean(FR1_CLA_PV(bin_range,n))-mean(FR1_CLA_PV(bin_range_after,2));
% end 
% [diff_list_FR1_CLA_PV_sorted,diff_FR1_CLA_PV_idx]=sort(diff_list_FR1_CLA_PV); 
% 
% FR1_CLA_PV_sorted=FR1_CLA_PV(:,diff_FR1_CLA_PV_idx);
% 
for n=1:size(FR1_CLA_nPV,2)
    diff_list_FR1_CLA_nPV(n)=mean(FR1_CLA_nPV(bin_range,n))-mean(FR1_CLA_nPV(bin_range_after,2));
end 
[diff_list_FR1_CLA_nPV_sorted,diff_FR1_CLA_nPV_idx]=sort(diff_list_FR1_CLA_nPV); 

FR1_CLA_nPV_sorted=FR1_CLA_nPV(:,diff_FR1_CLA_nPV_idx);



%%% This is just the highest value during the chirp 
% for n=1:size(FR1_PFC_PV,2)
%     diff_list_FR1_PFC_PV(n)=mean(FR1_PFC_PV(bin_range,n));
% end 
% [diff_list_FR1_PFC_PV_sorted,diff_FR1_PFC_PV_idx]=sort(diff_list_FR1_PFC_PV); 
% 
% FR1_PFC_PV_sorted=FR1_PFC_PV(:,diff_FR1_PFC_PV_idx);
% 
% for n=1:size(FR1_PFC_nPV,2)
%     diff_list_FR1_PFC_nPV(n)=mean(FR1_PFC_nPV(bin_range,n));
% end 
% [diff_list_FR1_PFC_nPV_sorted,diff_FR1_PFC_nPV_idx]=sort(diff_list_FR1_PFC_nPV); 
% 
% FR1_PFC_nPV_sorted=FR1_PFC_nPV(:,diff_FR1_PFC_nPV_idx);
%     
% % now sort by activity for CLA FR1
% for n=1:size(FR1_CLA_PV,2)
%     diff_list_FR1_CLA_PV(n)=mean(FR1_CLA_PV(bin_range,n));
% end 
% [diff_list_FR1_CLA_PV_sorted,diff_FR1_CLA_PV_idx]=sort(diff_list_FR1_CLA_PV); 
% 
% FR1_CLA_PV_sorted=FR1_CLA_PV(:,diff_FR1_CLA_PV_idx);
% 
% for n=1:size(FR1_CLA_nPV,2)
%     diff_list_FR1_CLA_nPV(n)=mean(FR1_CLA_nPV(bin_range,n));
% end 
% [diff_list_FR1_CLA_nPV_sorted,diff_FR1_CLA_nPV_idx]=sort(diff_list_FR1_CLA_nPV); 
% 
% FR1_CLA_nPV_sorted=FR1_CLA_nPV(:,diff_FR1_CLA_nPV_idx);


 
   
 % NOW sort FR2,FR3,FR4 by FR1 
  
FR2_PFC_PV_sorted=FR2_PFC_PV(:,diff_FR1_PFC_PV_idx);
FR2_PFC_nPV_sorted=FR2_PFC_nPV(:,diff_FR1_PFC_nPV_idx);

% FR2_CLA_PV_sorted=FR2_CLA_PV(:,diff_FR1_CLA_PV_idx);
 FR2_CLA_nPV_sorted=FR2_PFC_nPV(:,diff_FR1_CLA_nPV_idx);
%% Tak out nans 
% FR1_PFC_PV_sorted(isnan(FR1_PFC_PV_sorted))=0;
% FR1_PFC_nPV_sorted(isnan(FR1_PFC_nPV_sorted))=0;
% FR2_PFC_PV_sorted(isnan(FR2_PFC_PV_sorted))=0;
% FR2_PFC_nPV_sorted(isnan(FR2_PFC_nPV_sorted))=0;
% 
% FR1_CLA_PV_sorted(isnan(FR1_CLA_PV_sorted))=0;
% FR1_CLA_nPV_sorted(isnan(FR1_CLA_nPV_sorted))=0;
% FR2_CLA_PV_sorted(isnan(FR2_CLA_PV_sorted))=0;
% FR2_CLA_nPV_sorted(isnan(FR2_CLA_nPV_sorted))=0;

%%
% FR3_PFC_sorted=FR3_PFC(:,diff_FR1_PFC_idx);
% FR3_CLA_sorted=FR3_CLA(:,diff_FR1_CLA_idx);
% 
% FR4_PFC_sorted=FR4_PFC(:,diff_FR1_PFC_idx);
% FR4_CLA_sorted=FR4_CLA(:,diff_FR1_CLA_idx);
% 
% FR5_PFC_sorted=FR5_PFC(:,diff_FR1_PFC_idx);
% FR5_CLA_sorted=FR5_CLA(:,diff_FR1_CLA_idx);
% 
% FR6_PFC_sorted=FR6_PFC(:,diff_FR1_PFC_idx);
% FR6_CLA_sorted=FR6_CLA(:,diff_FR1_CLA_idx);
% 
% FR7_PFC_sorted=FR7_PFC(:,diff_FR1_PFC_idx);
% FR7_CLA_sorted=FR7_CLA(:,diff_FR1_CLA_idx);
% 
% FR8_PFC_sorted=FR8_PFC(:,diff_FR1_PFC_idx);
% FR8_CLA_sorted=FR8_CLA(:,diff_FR1_CLA_idx);


%% now take out nan values
% FR1_PFC_sorted(isnan(FR1_PFC_sorted))=0;
% FR1_CLA_sorted(isnan(FR1_CLA_sorted))=0;
% 
% FR2_PFC_sorted(isnan(FR2_PFC_sorted))=0;
% FR2_CLA_sorted(isnan(FR2_CLA_sorted))=0;

% FR3_PFC_sorted(isnan(FR3_PFC_sorted))=0;
% FR3_CLA_sorted(isnan(FR3_CLA_sorted))=0;
% 
% FR4_PFC_sorted(isnan(FR4_PFC_sorted))=0;
% FR4_CLA_sorted(isnan(FR4_CLA_sorted))=0;
% 
% FR5_PFC_sorted(isnan(FR5_PFC_sorted))=0;
% FR5_CLA_sorted(isnan(FR5_CLA_sorted))=0;
% 
% FR6_PFC_sorted(isnan(FR6_PFC_sorted))=0;
% FR6_CLA_sorted(isnan(FR6_CLA_sorted))=0;
% 
% FR7_PFC_sorted(isnan(FR7_PFC_sorted))=0;
% FR7_CLA_sorted(isnan(FR7_CLA_sorted))=0;
% 
% FR8_PFC_sorted(isnan(FR8_PFC_sorted))=0;
% FR8_CLA_sorted(isnan(FR8_CLA_sorted))=0;







    

%Combine PFC and CLA 
% % FR1_sorted=[ FR1_PFC_sorted FR1_CLA_sorted];
% % FR2_sorted=[ FR2_PFC_sorted FR2_CLA_sorted];
% % FR3_sorted=[ FR3_PFC_sorted FR3_CLA_sorted];
% % FR4_sorted=[ FR4_PFC_sorted FR4_CLA_sorted];