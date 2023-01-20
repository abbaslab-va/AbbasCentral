%% ERT example
sig = .05;
consec_thresh = 10; 

% Graphing parameters
ylims = [-1 4];
xlims = [-3 5];
sig_plot_level = linspace(4,3.2,7);
ts=[-17.5 17.5]

%baseline_avg=mean(mean(FR1_PFC_PV_sorted(200:300,:),2));
FR1_PFC_PV_sorted(isinf(FR1_PFC_PV_sorted))=NaN;
FR1_PFC_nPV_sorted(isinf(FR1_PFC_nPV_sorted))=NaN;
FR2_PFC_PV_sorted(isinf(FR2_PFC_PV_sorted))=NaN;
FR2_PFC_nPV_sorted(isinf(FR2_PFC_nPV_sorted))=NaN;

FR1_PFC_PV_sorted_m=rmmissing(FR1_PFC_PV_sorted');
FR1_PFC_nPV_sorted_m=rmmissing(FR1_PFC_nPV_sorted');
FR2_PFC_PV_sorted_m=rmmissing(FR2_PFC_PV_sorted');
FR2_PFC_nPV_sorted_m=rmmissing(FR2_PFC_nPV_sorted');


%FR1_PFC_PV_sorted=abs(FR1_PFC_PV_sorted)-baseline_avg;
%FR2_PFC_PV_sorted=abs(FR2_PFC_PV_sorted)-baseline_avg;
con1=FR1_PFC_PV_sorted_m;
%r = randi([1 50],1,50)
con2=FR2_PFC_PV_sorted_m;

%% By Philip Jean-Richard-dit-Bressel, UNSW Sydney, 2020
% Feel free to use with citation: Jean-Richard-dit-Bressel et al. (2020). https://doi.org/10.3389/fnmol.2020.00014

%% GNU
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

%%
[n_Cp,ev_win] = size(con1);
[n_Cm,~] = size(con2);
timeline = linspace(ts(1),ts(2),ev_win);

Cp_t_crit = tinv(1-sig/2,n_Cp-1);
Cm_t_crit = tinv(1-sig/2,n_Cm-1);

mean_Cp = mean(con1,1);
sem_Cp = sem(con2);
Cp_bCI = boot_CI(con2,1000,sig);
[adjLCI,adjUCI] = CIadjust(Cp_bCI(1,:),Cp_bCI(2,:),[],n_Cp,2);
Cp_bCIexp = [adjLCI;adjUCI];
Cp_tCI = [mean_Cp - sem_Cp*Cp_t_crit ; mean_Cp + sem_Cp*Cp_t_crit];

mean_Cm = mean(con2,1);
sem_Cm = sem(con2);
Cm_bCI = boot_CI(con2,1000,sig);
[adjLCI,adjUCI] = CIadjust(Cm_bCI(1,:),Cm_bCI(2,:),[],n_Cm,2);
Cm_bCIexp = [adjLCI;adjUCI];
Cm_tCI = [mean_Cm - sem_Cm*Cm_t_crit ; mean_Cm + sem_Cm*Cm_t_crit];

perm_p = permTest_array(con1,con2,1000);
diff_bCI = boot_diffCI(con1,con2,1000,sig);
[adjLCI,adjUCI] = CIadjust(diff_bCI(1,:),diff_bCI(2,:),[],n_Cm,2);
diff_bCIexp = [adjLCI;adjUCI];

%% Significance bars
%tCI
Cp_tCI_sig = NaN(1,ev_win);
sig_idx = find((Cp_tCI(1,:) > 0) | (Cp_tCI(2,:) < 0));
consec = consec_idx(sig_idx,consec_thresh);
Cp_tCI_sig(sig_idx(consec)) = sig_plot_level(1);

Cm_tCI_sig = NaN(1,ev_win);
sig_idx = find((Cm_tCI(1,:) > 0) | (Cm_tCI(2,:) < 0));
consec = consec_idx(sig_idx,consec_thresh);
Cm_tCI_sig(sig_idx(consec)) = sig_plot_level(2);

diff_tCI_sig = NaN(1,ev_win);
sig_idx = ttest2(con1,con2);
sig_idx = find(sig_idx == 1);
consec = consec_idx(sig_idx,consec_thresh);
diff_tCI_sig(sig_idx(consec)) = sig_plot_level(3);

%bCI
Cp_bCIexp_sig = NaN(1,ev_win);
sig_idx = find((Cp_bCIexp(1,:) > 0) | (Cp_bCIexp(2,:) < 0));
consec = consec_idx(sig_idx,consec_thresh);
Cp_bCIexp_sig(sig_idx(consec)) = sig_plot_level(4);

Cm_bCIexp_sig = NaN(1,ev_win);
sig_idx = find((Cm_bCIexp(1,:) > 0) | (Cm_bCIexp(2,:) < 0));
consec = consec_idx(sig_idx,consec_thresh);
Cm_bCIexp_sig(sig_idx(consec)) = sig_plot_level(5);

diff_bCIexp_sig = NaN(1,ev_win);
sig_idx = find((diff_bCIexp(1,:) > 0) | (diff_bCIexp(2,:) < 0));
consec = consec_idx(sig_idx,consec_thresh);
diff_bCIexp_sig(sig_idx(consec)) = sig_plot_level(6);

%Permutation test
perm_p_sig = NaN(1,ev_win);
sig_idx = find(perm_p < sig);
consec = consec_idx(sig_idx,consec_thresh);
perm_p_sig(sig_idx(consec)) = sig_plot_level(7);


%% Plot
correct_col=[0 1 0]
%correct_col=[0.4660 0.6740 0.1880];
%correct_col='k';
%incorrect_col=[1 0 0];
incorrect_col=[0.4940 0.1840 0.5560]

bCl_diff_col=[0 0.4470 0.7410];

figure; hold on
ShadedErrorPlot(timeline,mean_Cm,sem_Cm,correct_col,correct_col,0.15)
ShadedErrorPlot(timeline,mean_Cp,sem_Cp,incorrect_col,incorrect_col,0.15)

%Plor tCI sig
% plot(timeline,Cp_tCI_sig,'Color',col_rep(2),'Marker','.')
% text(xlims(1),sig_plot_level(1),'\bf CS+ tCI','Color',col_rep(2));
% plot(timeline,Cm_tCI_sig,'Color',col_rep(3),'Marker','.')
% text(xlims(1),sig_plot_level(2),'\bf CS- tCI','Color',col_rep(3));
% plot(timeline,diff_tCI_sig,'Color',col_rep(4),'Marker','.')
% text(xlims(1),sig_plot_level(3),'\bf Diff tCI','Color',col_rep(4));

%Plot bCI sig
%figure()
%hold on
plot(timeline,Cp_bCIexp_sig,'Color',incorrect_col,'Marker','.')
text(xlims(1),sig_plot_level(4),'\bf CS+ bCI','Color',incorrect_col);
plot(timeline,Cm_bCIexp_sig,'Color',correct_col,'Marker','.')
text(xlims(1),sig_plot_level(5),'\bf CS- bCI','Color',correct_col);
plot(timeline,diff_bCIexp_sig,'Color',bCl_diff_col,'Marker','.')
text(xlims(1),sig_plot_level(6),'\bf Diff bCI','Color',bCl_diff_col);

% plot(timeline,Cp_tCI_sig,'Color',incorrect_col,'Marker','.')
% text(xlims(1),sig_plot_level(1),'\bf CS+ bCI','Color',incorrect_col);
% plot(timeline,Cm_tCI_sig,'Color',correct_col,'Marker','.')
% text(xlims(1),sig_plot_level(2),'\bf CS- bCI','Color',correct_col);
% plot(timeline,diff_tCI_sig,'Color',bCl_diff_col,'Marker','.')
% text(xlims(1),sig_plot_level(3),'\bf Diff bCI','Color',bCl_diff_col);

%Plot permutation test sig
% plot(timeline,perm_p_sig,'Color',col_rep(1),'Marker','.')
% text(xlims(1),sig_plot_level(7),'\bf Perm','Color',col_rep(1));

plot([0 0],ylim,'k:')
plot([0.5 0.5],ylim,'k:')
plot([-0.5 -0.5],ylim,'k--')
plot([1 1],ylim,'k--')
plot(xlim,[0 0],'k--')
xticks([-3,0,2.5 ,5])  
xticklabels([3, {'Chirp'} ,2.5, 5])
xlim(xlims);
set(gca,'FontSize',24);
set(gca,'FontName','Arial');
set(gca, 'TickDir', 'out')
ax=gca
ax.LineWidth=1.5
ylabel('Normalized FR')
xlabel('Time (s)')