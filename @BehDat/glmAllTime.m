load('Z:\CLA_EX4\allSessionsAutocorrFiltered.mat');
%%
clearvars -except allSessions
%% 
tic
s=32;
 for s=1:numel(allSessions)
     cpd{s}=findcpd(allSessions(s),s);
     disp(s)
 end 
toc

%% 
clearvars -except cpd allSessions trialAvgSpikesAllPfc trialAvgSpikesAllCla
[significantRegressorMatrix, uniqueRegressors] = extract_significant_regressors(cpd, 0.05);

%% 
%---------------------
regionAll=arrayfun(@(x) [extractfield(x.spikes,'region')],allSessions,'Uni',0);
regionAll=[regionAll{:}]; 

region_idx_PFC=find(regionAll=="PFC");

region_idx_CLA=find(regionAll=="CLA");



%---------------------
%cpdMat=significantRegressorMatrix(:,2:end);

cpdMat=significantRegressorMatrix(:,2:end);

cpdPfcMat=cpdMat(region_idx_PFC,:);
cpdClaMat=cpdMat(region_idx_CLA,:);


%% 
absValueThreshold = 3;  % Absolute value threshold for removing small values
nanThreshold = 0.8;  % NaN percentage threshold for removing neurons/regressors

[cleanedDataCla, regIdxCla] = clean_regressors(cpdClaMat, absValueThreshold, nanThreshold);
[cleanedDataPfc, regIdxPfc] = clean_regressors(cpdPfcMat, absValueThreshold, nanThreshold);



%% 
% Define parameters
numClusters = 4;  % Set the number of clusters


% Run the function with a fixed number of clusters
[clusterIdxPfc, Y] = run_tsne_kmeans_with_fixed_clusters(cleanedDataPfc, numClusters);

%% 
numClusters = 4;  % Set the number of clusters


[clusterIdxCla, Y] = run_tsne_kmeans_with_fixed_clusters(cleanedDataCla, numClusters);


%%
% absValueThreshold = 1;  % Absolute value threshold for removing small values
% nanThreshold = 0.75;  % NaN percentage threshold for removing neurons/regressors
% 
% [clusterPfcC, regIdxPfc, neuronIdxPfc] = clean_and_track(cpdPfcMat, clusterIdxPfc, absValueThreshold, nanThreshold);
% [clusterClaC, regIdxCla, neuronIdxCla] = clean_and_track(cpdClaMat, clusterIdxCla, absValueThreshold, nanThreshold);
%%
% clearvars  clusterPfcC clusterClaC
% 
% rNames=uniqueRegressors(2:end);
% rNames = rNames(~cellfun(@isempty, rNames))
% 
% 
% 
% clusterPfcC{1}=cleanedDataPfc(clusterIdxPfc==1 & cleanedDataPfc(:,16)>0,:);
% clusterPfcC{2}=cleanedDataPfc(clusterIdxPfc==1 & cleanedDataPfc(:,16)<0,:);
% clusterPfcC{3}=cleanedDataPfc(clusterIdxPfc==2 & cleanedDataPfc(:,16)>0,:);
% clusterPfcC{4}=cleanedDataPfc(clusterIdxPfc==2 & cleanedDataPfc(:,16)<0,:);
%    
% cleanedDataPfc(isnan(cleanedDataPfc(:,16)),16)=1
%     
% clusterIdxPfcNew=zeros(numel(clusterIdxPfc),1);
% clusterIdxPfcNew(clusterIdxPfc==1 & cleanedDataPfc(:,16)>0,:)=1;
% clusterIdxPfcNew(clusterIdxPfc==1 & cleanedDataPfc(:,16)<0,:)=2;
% clusterIdxPfcNew(clusterIdxPfc==2 & cleanedDataPfc(:,16)>0,:)=3;
% clusterIdxPfcNew(clusterIdxPfc==2 & cleanedDataPfc(:,16)<0,:)=4;
% 

%% 

clearvars clusterPfcC clusterClaC

% Split the original clusters based on Port6TimeIn (column 16 in the data)
for c = 1:numel(unique(clusterIdxCla))
    clusterPfcC{c} = cleanedDataPfc(clusterIdxPfc == c, :);
    clusterClaC{c} = cleanedDataCla(clusterIdxCla == c, :);
end

rNames = uniqueRegressors(2:end);
rNames = rNames(~cellfun(@isempty, rNames));





%%



for c=1:numel(clusterClaC)
    figure()
    hold on
    title(['CLA' num2str(c)])
    temp=clusterClaC{1,c};
    for n=1:size(temp,1)
    %temp(isnan(temp))=0;
    plot(temp(n,:))
    end
    xticks([1:sum(regIdxCla)])
    xticklabels(rNames(regIdxCla))
end 
 


for c=1:numel(clusterPfcC)
    figure()
    title(['PFC' num2str(c)])
    hold on 
    temp=clusterPfcC{1,c};
    for n=1:size(temp,1)
    %temp(isnan(temp))=0;
    plot(temp(n,:))
   
    xticks([1:sum(regIdxPfc)])
    xticklabels(rNames(regIdxPfc))
    % pause(1)
    end
 
end 
%% 

%%

%---- calculate means of clusters 
clusterClaAvg=cellfun(@(x) nanmean(x),clusterClaC,'uni',false);
clusterPfcAvg=cellfun(@(x) nanmean(x),clusterPfcC,'uni',false);

%----------------- Visualize

rNames=uniqueRegressors(2:end);

for c=1:numel(clusterClaAvg)
    figure()
    hold on
    title(['CLA' num2str(c)])
    temp=clusterClaAvg{1,c};
    temp(isnan(temp))=0;
    plot(temp)
    xticks([1:sum(regIdxCla{c})])
    xticklabels(rNames(regIdxCla{c}))
end 
 


for c=1:numel(clusterPfcAvg)
    figure()
    hold on
    title(['ACC' num2str(c)])
    temp=clusterPfcAvg{1,c};
    temp(isnan(temp))=0;
    plot(temp)
    xticks([1:sum(regIdxPfc{c})])
    xticklabels(rNames(regIdxPfc{c}))
end 
 

%% plot: clusters

for sess=1:length(allSessions)
    temp1=struct2cell(allSessions(sess).spikes);
    spike_cellery{sess}=temp1(1,:);
end 
%% 

baud=30000; % 30000 samples/s
window=[-2 2]; % 
bin_size=1; %ms
smoothWin=50; %50 ms 
center=2; %s

% front port out precceding back port in, Hit 
event_cell= arrayfun(@(x) x.find_event('event','Reward','trialtype','Laser Off'),allSessions,'uni',0)';
%event_cell=[event_cell1' event_cell2']';
[trialAvgSpikesAllPfc, trialAvgSpikesAllCla]=spikemap(event_cell,window,baud,spike_cellery,allSessions,bin_size,smoothWin);

%% 

sortparams1=[{[0 0.5],[0 0.5], [0 0.5],[0 0.5]}];
%sortparams2=[{[-0.5 0]}];
%%
plotHeatmapClust(trialAvgSpikesAllPfc,clusterIdxPfc,sortparams1,window,bin_size,center,clusterPfcC)
%%
plotHeatmapClust(trialAvgSpikesAllCla,clusterIdxCla,sortparams1,window,bin_size,center,clusterClaC)
%%

%% 
allSessions(34).psth(23,'event','Chirp','trialtype', 'Laser Off')
allSessions(30).raster(23,'event','Chirp','trialtype', 'Laser Off')
%% -------------------------------------------- functions -----------------------------------------%%

function [cleanedData, regIdx] = clean_regressors(dataMat, absValueThreshold, nanThreshold)
    % Function to clean data matrix by applying an absolute value threshold,
    % removing regressors (columns) with too many NaNs, and tracking the indices.
    % INPUTS:
    % dataMat: Matrix (n-neurons by r-regressors) to be cleaned
    % absValueThreshold: Absolute value threshold for replacing small values with NaNs
    % nanThreshold: Percentage threshold for removing regressors based on NaNs (e.g., 0.5 for 50%)
    % OUTPUTS:
    % cleanedData: Cleaned data matrix with NaNs filled and small values replaced
    % regIdx: Logical array tracking which regressors were kept

    % ---------------- Apply Absolute Value Threshold ----------------
    % Set values to NaN if their absolute value is lower than the threshold
    dataMat(abs(dataMat) < absValueThreshold) = NaN;

    % ---------------- Track and Remove Regressors with Too Many NaNs ----------------
    regressorNanCount = sum(isnan(dataMat), 1);  % Count NaNs per regressor (column)
    keepRegressors = regressorNanCount <= size(dataMat, 1) * nanThreshold;  % Logical array of regressors to keep
    regIdx = keepRegressors;  % Track original regressor indices

    % Remove regressors with too many NaNs
    cleanedData = dataMat(:, keepRegressors);
end


%% 



function [cleanedClusterData, regIdx, neuronIdx] = clean_and_track(dataMat, clusterIdx,absValueThreshold, nanThreshold)
    % Function to clean cluster data by applying an absolute value threshold,
    % removing neurons and regressors with too many NaNs, and tracking the indices.
    % INPUTS:
    % clusterData: Cell array containing clusters (each cell is an n-neurons by r-regressors matrix)
    % absValueThreshold: Absolute value threshold for replacing small values with NaNs
    % nanThreshold: Percentage threshold for removing neurons and regressors based on NaNs (e.g., 0.5 for 50%)
    % OUTPUTS:
    % cleanedClusterData: Cleaned cell array of data with NaNs filled and small values replaced
    % regIdx: Logical array tracking which regressors were kept
    % neuronIdx: Logical array tracking which neurons were kept
    
    for c=1:numel(unique(clusterIdx))
        clusterData{c}=dataMat(clusterIdx==c,:);
    end 
    % Initialize cleaned data storage and index tracking
    cleanedClusterData = cell(size(clusterData));
    regIdx = cell(size(clusterData));  % Logical indexing for regressors
    neuronIdx = cell(size(clusterData));  % Logical indexing for neurons

    % Process each cluster
    for cluster = 1:length(clusterData)
        data = clusterData{cluster};  % Get the n-neurons by r-regressors matrix for this cluster
        
        % ---------------- Apply Absolute Value Threshold ----------------
        % Set values to NaN if their absolute value is lower than the threshold
        data(abs(data) < absValueThreshold) = NaN;

        % ---------------- Track and Remove Regressors with Too Many NaNs ----------------
        regressorNanCount = sum(isnan(data), 1);  % Count NaNs per regressor
        keepRegressors = regressorNanCount <= size(data, 1) * nanThreshold;  % Logical array of regressors to keep
        regIdx{cluster} = keepRegressors;  % Track original regressor indices
        cleanedNeuronData = data(:, keepRegressors);  % Remove regressors with too many NaNs

        % ---------------- Track and Remove Neurons with Too Many NaNs ----------------
        neuronNanCount = sum(isnan(cleanedNeuronData), 2);  % Count NaNs per neuron
        keepNeurons = neuronNanCount <= size(cleanedNeuronData, 2) * nanThreshold;  % Logical array of neurons to keep
        neuronIdx{cluster} = keepNeurons;  % Track original neuron indices
        dbcNeuronData = cleanedNeuronData(keepNeurons, :);  % Remove neurons with too many NaNs

        % ---------------- Store Cleaned Data ----------------
        cleanedClusterData{cluster} = dbcNeuronData;  % Store cleaned data for this cluster
    end
end
 %% 
function [clusterIdx, Y] = run_tsne_kmeans_with_fixed_clusters(dataMat, numClusters)
  % Assuming your matrix is 'dataMat' and NaNs have been replaced by zeros previously

% Z-score normalization (preserves sign)
mu = mean(dataMat, 'omitnan');  % Mean ignoring NaNs
sigma = std(dataMat, 'omitnan');  % Standard deviation ignoring NaNs

% Normalize the data by subtracting the mean and dividing by the std dev
normalizedDataMat = (dataMat - mu) ./ sigma;

% Preserve the zeros (which were previously NaNs)
normalizedDataMat=fillmissing(normalizedDataMat,'constant',0);

% Now run K-means on the normalized data

   % eva=evalclusters(normalizedDataMat,"kmeans","CalinskiHarabasz","KList",1:10)
        % Run t-SNE to reduce to 2 dimensions
     [Y,loss] = tsne(normalizedDataMat,'Algorithm','exact','NumDimensions',3);
    % ---------------- Step 2: Run K-means with Fixed Number of Clusters ----------------
   [clusterIdx, ~] = kmeans(normalizedDataMat, numClusters,'Replicates', 10);  % Use fixed number of clusters
    scatter3(Y(:,1),Y(:,2),Y(:,3),15,clusterIdx,'filled')
end



%% 

function [significantRegressorMatrix ,uniqueRegressors] = extract_significant_regressors(cpd, threshold)
    % Function to extract significant regressor coefficients for each neuron
    % INPUTS:
    % cpd: Cell array containing neuron models (with tStats and pValues)
    % threshold: The significance threshold (e.g., 0.05 for p-values)
    % OUTPUT:
    % significantRegressorMatrix: Matrix containing coefficients of significant regressors only
    
    % ---------------- Step 1: Collect all unique regressors across neurons ----------------
    allRegressors = {};  % Initialize a list to collect all unique regressors
    for session = 1:length(cpd)
        neuronModels = cpd{session};  % Get the models for the current session
        for neuron = 1:length(neuronModels)
            regressorNames = neuronModels{neuron}.Properties.RowNames;  % Regressor names for this neuron
            allRegressors = [allRegressors; regressorNames];  % Collect the regressors
        end
    end
    
    % Get unique regressors across all neurons
    uniqueRegressors = unique(allRegressors);
    
    % ---------------- Step 2: Create n-neurons by r-regressors coefficient matrix ----------------
    nNeurons = sum(cellfun(@length, cpd));  % Total number of neurons across all sessions
    rRegressors = length(uniqueRegressors);  % Total number of unique regressors
    
    neuronRegressorMatrix = NaN(nNeurons, rRegressors);  % Preallocate matrix for coefficients
    significanceMatrix = NaN(nNeurons, rRegressors);  % Preallocate matrix for significance (binary)
    
    neuronCounter = 1;  % Counter for neuron index
    
    % ---------------- Step 3: Fill the coefficient and significance matrices ----------------
    for session = 1:length(cpd)
        neuronModels = cpd{session};  % Get the models for the current session
        for neuron = 1:length(neuronModels)
            regressorNames = neuronModels{neuron}.Properties.RowNames;  % Regressor names for this neuron
            coefficients = neuronModels{neuron}.tStat;  % Coefficients (tStat)
            pValues = neuronModels{neuron}.pValue;  % P-values for significance
            
            % Find the position of each regressor in the unique regressor list
            [~, regressorIndices] = ismember(regressorNames, uniqueRegressors);
            
            % Fill in the corresponding coefficients for this neuron in the matrix
            neuronRegressorMatrix(neuronCounter, regressorIndices) = coefficients;
            
            % Mark as 1 if the p-value is significant (< threshold), otherwise 0
            significanceMatrix(neuronCounter, regressorIndices) = pValues < threshold;
            
            neuronCounter = neuronCounter + 1;  % Increment the neuron index
        end
    end
    
    % ---------------- Step 4: Apply the significance mask ----------------
    % Element-wise multiplication to keep only significant regressors
    significantRegressorMatrix = neuronRegressorMatrix .* significanceMatrix;
    
    % Set non-significant entries to NaN
    significantRegressorMatrix(significanceMatrix == 0) = NaN;
end
%% 

function [trialAvgSpikesAllPfc, trialAvgSpikesAllCla] = spikemap(event_cell,window,baud,spike_cellery,allSessions,bin_size,smoothWin,idx)

event_edges=cellfun(@(x) mat2cell(reshape([x+(window(1)*baud) x+(window(2)*baud)],numel(x),2),repelem(1,numel(x)),[1 1]),event_cell,'uni',0);
exclude=cellfun(@(x) ~isempty(x),event_edges,'UniformOutput',true);

if ~exist('idx','var')
temp_sub=spike_cellery(exclude);
event_sub=event_edges(exclude)';
else
temp_sub=spike_cellery(idx);
event_sub=event_edges'; 
end 

spikedata=cellfun(@(x,y) bin_spikes_RO(x,y,bin_size),temp_sub,event_sub,'uni',0);

for sess=1:numel(spikedata)
    trialAvgSpikesBySess{sess}=normalize(smoothdata(mean(reshape(cell2mat(spikedata{sess}),[size(spikedata{sess}{1},1) size(spikedata{sess}{1},2) size(spikedata{sess},2)]),3)*(1000/bin_size),2,'Gaussian',smoothWin)*1000,2);
end 

trialAvgSpikesAll=cell2mat(trialAvgSpikesBySess');

if ~exist('idx','var')
regionAll=arrayfun(@(x) [extractfield(x.spikes,'region')],allSessions(exclude),'Uni',0);
regionAll=[regionAll{:}]; 

else 
regionAll=arrayfun(@(x) [extractfield(x.spikes,'region')],allSessions(idx),'Uni',0);
regionAll=[regionAll{:}];   
end 

region_idx_PFC=find(regionAll=="PFC");

region_idx_CLA=find(regionAll=="CLA");


trialAvgSpikesAllPfc=trialAvgSpikesAll(region_idx_PFC,:);
trialAvgSpikesAllCla=trialAvgSpikesAll(region_idx_CLA,:);

end 
%% 
function plotHeatmapClust(pop1,clust1,sort1,window,bin_size,center,regMat)

numClusters=numel(unique(nonzeros(clust1)));
sort1=cellfun(@(x) (x+center)*1000/bin_size,sort1,'uni',0);
     top_40_all_clusters = [];
    bottom_40_all_clusters = [];

for clust=1:numClusters
    temp=pop1(find(clust1==clust),:);
    regtemp=regMat{clust};
    %temp=temp(nIdx{clust},:);
    [sort_output, sort_idx]=sort(nanmean(temp(:,sort1{clust}(1):sort1{clust}(2)),2)); 
    pop1_sorted{clust}=temp(sort_idx,:);
    reg1_sorted{clust}=regtemp(sort_idx,:);


% Determine the indices for the top 40% and bottom 40%
        num_neurons = size(pop1_sorted{clust}, 1);
        top_40_idx = round(0.6 * num_neurons) + 1 : num_neurons;  % Top 40%
        bottom_40_idx = 1 : round(0.4 * num_neurons);  % Bottom 40%
        
        % Extract the top 40% and bottom 40%
        top_40 = pop1_sorted{clust}(top_40_idx, :);
        bottom_40 = pop1_sorted{clust}(bottom_40_idx, :);
        
        % Combine across clusters
        top_40_all_clusters = [top_40_all_clusters; top_40];
        bottom_40_all_clusters = [bottom_40_all_clusters; bottom_40];
end 

%pop1_sorted{1}=   top_40_all_clusters ;
%pop1_sorted{2}=  bottom_40_all_clusters;

figure;
t=tiledlayout(1,numClusters+1);
for clust=1:numClusters
    nexttile()
    hold on 
    title(['CLUST' num2str(clust)])
    surf(pop1_sorted{clust},EdgeColor="none");
    ylim([0 size(pop1_sorted{clust},1)]);
    view(2);
    caxis([-5 5]);
    ax = gca;
    ax.FontSize=20;
    ax.TickDir='out';
    ax.LineWidth=2;
    xticks(0:1000/bin_size:window(2)*2*1000/bin_size);
    xticklabels([window(1):1:window(2)]);
end 

  nexttile()

for clust=1:numClusters
    plot(smoothdata(nanmean(pop1_sorted{clust}),'movmean',25),'LineWidth',2,'DisplayName',num2str(clust));
    hold on;
end 
    legend show;
    xline(center*1000/bin_size);
    xticks(0:1000/bin_size:window(2)*2*1000/bin_size);
    xticklabels([window(1):1:window(2)]);


t.TileSpacing = 'compact';

end 


%%
function cpd=findcpd(Sess,num)


binSize=50;
stepSize = floor(30000/1000*binSize);
eventEdges=[1 Sess.info.samples];
binEdges = eventEdges(1):stepSize:eventEdges(2);



temp1=struct2cell(Sess.spikes);
spike_cellery=temp1(1,:);


binnedSpikes= cellfun(@(x) histcounts(x, 'BinEdges', binEdges),spike_cellery,'UniformOutput',false);


Y= cellfun(@(x) normalize(smoothdata(x,2,"gaussian",50),'range'),binnedSpikes,'UniformOutput',false);

%figure()
%plot(Y{24})

%% Events
% In/Out
ports={'Port1In','Port2In','Port3In','Port4In','Port5In', 'Port7In'};
for p=1:numel(ports)
    Pin{p} = Sess.find_event('event', ports{p}, 'bpod',true, 'trialtype', 'Laser Off','removeEnds', true, 'ignoreRepeats', true);
end 


for p=1:numel(ports)
    Pout{p} = Sess.find_event('event', ports{p}, 'bpod',true, 'trialtype', 'Laser Off','returnOut', true,'removeEnds', true,'ignoreRepeats', true);
end 


binnedPortsOut = cellfun(@(x) histcounts(x, 'BinEdges', binEdges),Pout,'uni',false) ; 
binnedPortsIn = cellfun(@(x) histcounts(x, 'BinEdges', binEdges),Pin,'uni',false) ; 


% Forage Reward 
fReward= Sess.find_event('event','Forage', 'trialtype', 'Laser Off');
binnedPortsfReward = histcounts(fReward, 'BinEdges', binEdges);   




% Reward
Reward= Sess.find_event('event','Reward', 'trialtype', 'Laser Off');
binnedPortsReward = histcounts(Reward, 'BinEdges', binEdges);    

% % Reward
% Punish= Sess.find_event('event','Punish', 'trialtype', 'Laser Off');
% binnedPortsPunish = histcounts(Punish, 'BinEdges', binEdges);    

% ChirpPlay 
if num>21
    chirp= Sess.find_event('event','Chirp', 'trialtype', 'Laser Off');
    binnedPortsChirp = histcounts(chirp, 'BinEdges', binEdges);    
else 
    chirp= Sess.find_event('event','Laser On','offset', 0.5, 'trialtype', 'Laser Off');
    binnedPortsChirp = histcounts(chirp, 'BinEdges', binEdges);  
end 

% % Laser 
% %event_cell1= arrayfun(@(x) x.find_event('event','Laser On','offset', 0.5);
% laser= allSessions(5).find_event('event','Laser_On');
% binnedPortsChirp = histcounts(chirp, 'BinEdges', binEdges);    

dm=[cell2mat(binnedPortsIn')', cell2mat(binnedPortsOut')', binnedPortsfReward' , binnedPortsReward',binnedPortsChirp'];

dm=array2table(dm, 'VariableNames',{'Port1In','Port2In','Port3In','Port4In','Port5In', 'Port6In','Port1Out','Port2Out','Port3Out','Port4Out','Port5Out', 'Port6Out','fReward','Reward', 'Cue'});
dm = dm(:,{'Port1In','Port1Out','Port2In','Port2Out','Port3In', 'Port3Out','Port4In','Port4Out','Port5In','Port5Out' 'Port6In','Port6Out','fReward','Reward', 'Cue'});
designTable=dm;
%% Cap multiple entries 
% List the columns that need to be capped at 1 in designTable (e.g., PortIn/Out, Reward, Cue)
columnsToCap = {'Port1In', 'Port1Out', 'Port2In', 'Port2Out', 'Port3In', 'Port3Out', ...
                'Port4In', 'Port4Out', 'Port5In', 'Port5Out', 'Port6In', 'Port6Out', ...
                'fReward','Reward', 'Cue'};

% Loop through each column and cap its values at 1
for i = 1:length(columnsToCap)
    columnName = columnsToCap{i};
    % Cap the values at 1
    designTable.(columnName)(designTable.(columnName) > 1) = 1;
end


%% add time spent in port 
% Convert the relevant columns of the table into a matrix for faster computation
% portInOutMatrix = [designTable.Port1In, designTable.Port1Out, ...
%                    designTable.Port2In, designTable.Port2Out, ...
%                    designTable.Port3In, designTable.Port3Out, ...
%                    designTable.Port4In, designTable.Port4Out, ...
%                    designTable.Port5In, designTable.Port5Out, ...
%                    designTable.Port6In, designTable.Port6Out];
% 
% 
% % Initialize a matrix for time spent in port (time bins × 6 ports)
% timeSpentInPort = zeros(size(portInOutMatrix, 1), 6);
% 
% % Loop through each port and calculate time spent in port
% for port = 1:6
%     % Extract PortIn and PortOut for each port
%     portIn = portInOutMatrix(:, 2*port - 1); % Port1In, Port2In, etc.
%     portOut = portInOutMatrix(:, 2*port);   % Port1Out, Port2Out, etc.
%     
%     inPort = false; % Track if mouse is in the port
%     
%     % Loop through time bins (rows)
%     for t = 1:size(portInOutMatrix, 1)
%         % Handle multiple port entries: set entry to 1 if there's at least one
%         if portIn(t) >= 1
%             portIn(t) = 1; % Treat any multiple entries in the same bin as a single entry
%         end
%         
%         % New logic: if both PortIn and PortOut happen in the same bin, assume the mouse entered and exited in the same bin
%         if portIn(t) == 1 && portOut(t) == 1
%             inPort = false;  % Mouse entered and exited in the same bin, so set inPort to false
%         elseif portOut(t) == 1
%             inPort = false;  % Mouse exits the port
%         elseif portIn(t) == 1
%             inPort = true;   % Mouse enters the port
%         end
%         
%         % Update the time spent in port matrix for this port
%         timeSpentInPort(t, port) = inPort;
%     end
% end
% 
% % If needed, you can convert this matrix back to a table to append it to your original designTable
% timeSpentInPortTable = array2table(timeSpentInPort, 'VariableNames', ...
%                                    {'Port1TimeIn', 'Port2TimeIn', 'Port3TimeIn', ...
%                                     'Port4TimeIn', 'Port5TimeIn','Port6TimeIn'});
% % Append the time spent in port columns to the designTable
% designTable = [designTable, timeSpentInPortTable];



%% 
% Convert the relevant columns of the table into a matrix for faster computation
portInOutMatrix = [designTable.Port1In, designTable.Port1Out, ...
                   designTable.Port2In, designTable.Port2Out, ...
                   designTable.Port3In, designTable.Port3Out, ...
                   designTable.Port4In, designTable.Port4Out, ...
                   designTable.Port5In, designTable.Port5Out, ...
                   designTable.Port6In, designTable.Port6Out];


% Initialize a matrix for time spent in port (time bins × 6 ports)
timeSpentInPort = zeros(size(portInOutMatrix, 1), 6);

% Loop through each port and calculate time spent in port
for port = 1:6
    % Extract PortIn and PortOut for each port
    portIn = portInOutMatrix(:, 2*port - 1); % Port1In, Port2In, etc.
    portOut = portInOutMatrix(:, 2*port);   % Port1Out, Port2Out, etc.
    
    inPort = false; % Track if mouse is in the port
    
    % Loop through time bins (rows)
    for t = 1:size(portInOutMatrix, 1)
        % Handle multiple port entries: set entry to 1 if there's at least one
        if portIn(t) >= 1
            portIn(t) = 1; % Treat any multiple entries in the same bin as a single entry
        end
        
        % New logic: if both PortIn and PortOut happen in the same bin, count it as 1 and set inPort to false
        if portIn(t) == 1 && portOut(t) == 1
            inPort = true;   % Mouse enters the port in the same bin
            timeSpentInPort(t, port) = 1; % Count this bin as spent in the port
            inPort = false;  % Set inPort to false immediately after, as the mouse also exits
        elseif portIn(t) == 1
            inPort = true;   % Mouse enters the port
        elseif portOut(t) == 1 && inPort
            timeSpentInPort(t, port) = 1; % Mark the exit bin as 1 (since we're counting this as part of time in the port)
            inPort = false;  % Mouse exits the port in the next bin
        end
        
        % Always update the time spent in port matrix if the mouse is still in the port
        if inPort
            timeSpentInPort(t, port) = 1;
        end
    end
end

% Convert the matrix back to a table to append it to your original designTable
timeSpentInPortTable = array2table(timeSpentInPort, 'VariableNames', ...
                                   {'Port1TimeIn', 'Port2TimeIn', 'Port3TimeIn', ...
                                    'Port4TimeIn', 'Port5TimeIn', 'Port6TimeIn'});

% Append the time spent in port columns to the designTable
designTable = [designTable, timeSpentInPortTable];



%% 
% designMatrix = table2array(designTable);
% rewardColumnIndex = find(strcmp(designTable.Properties.VariableNames, 'Reward'));
% % Initialize vectors to track the reward status of the last 2 port exits
% previousReward = zeros(size(designMatrix, 1), 1);       % Last port reward
% previousReward2 = zeros(size(designMatrix, 1), 1);      % Second last port reward
% 
% % Initialize variables to keep track of the last 2 port exits
% lastReward = 0;    % Reward from the last port exit
% secondLastReward = 0;  % Reward from the second last port exit
% 
% for t = 2:size(designMatrix, 1) % Start from 2 since no previous reward at the first time bin
%     % Check for PortOut in any of the 5 ports (adjust if using 6 ports)
%     for port = 1:5
%         portOut = designMatrix(t, 2*port);   % Port1Out, Port2Out, etc.
%         reward = designMatrix(t, rewardColumnIndex);     % Assuming 'Reward' column is second to last
%         
%         % If there's an exit from any port
%         if portOut == 1
%             % Shift the reward tracking: move lastReward to secondLastReward
%             secondLastReward = lastReward;   % Previous last reward becomes the second last
%             lastReward = reward;             % Current reward becomes the last reward
%         end
%     end
%     
%     % Store the last and second last rewards for the current time bin
%     previousReward(t) = lastReward;            % Last port reward
%     previousReward2(t) = secondLastReward;     % Second last port reward
% end
% 
% % Add previousReward and previousReward2 to the design matrix
% designMatrix = [designMatrix, previousReward, previousReward2];
% 
% % Convert the updated design matrix back to a table
% newVariableNames = [designTable.Properties.VariableNames, {'PreviousRewardAnyPort', 'Previous2RewardAnyPort'}];
% designTable = array2table(designMatrix, 'VariableNames', newVariableNames);
% 
% designTable=designTable(:,[13:end]);
%% 

% Initialize the predictor for the number of port entries since the last reward
rewardHistory = zeros(height(designTable), 1);  % NaN for non-port entry bins

% Track how many port entries have occurred since the last reward (for ports 1-5)
entriesSinceLastReward = 0;

% Loop through the design matrix
for t = 1:height(designTable)
    
    % Check if a reward was given at the current time bin
    if designTable.fReward(t) == 1
        entriesSinceLastReward = 0;  % Reset the count after a reward
    end
    
    % Check for a port entry in the front 5 ports
    if any([designTable.Port1In(t), designTable.Port2In(t), designTable.Port3In(t), ...
            designTable.Port4In(t), designTable.Port5In(t)])
        % If an entry occurs in ports 1-5, update the reward history
        rewardHistory(t) = entriesSinceLastReward;
        entriesSinceLastReward = entriesSinceLastReward + 1;  % Increment after port entry
    
    % Check if the animal enters Port 6 and is unrewarded
    elseif designTable.Port6In(t) == 1 && designTable.Reward(t) == 0
        % Reset the counter if the animal visits Port 6 and it's unrewarded
        entriesSinceLastReward = 0;
    end
end

% Add the reward history term to the design table
designTable.RewardHistory = rewardHistory;

designTable=designTable(:,[13:end]);

%% 
% Combine all PortXTimeIn variables for front ports (1-5) and back port (Port 6)
frontPortTimeInMatrix = [designTable.Port1TimeIn, designTable.Port2TimeIn, ...
                         designTable.Port3TimeIn, designTable.Port4TimeIn, ...
                         designTable.Port5TimeIn];
backPortTimeIn = designTable.Port6TimeIn;

% Initialize variables to store the last valid values for fReward, RewardHistory, and Reward
lastFrontRewardHistory = 0;
lastFrontReward = 0;
lastBackReward = 0;

% --------------------- First loop: Handle RewardHistory for front ports (1-5) ---------------------

for t = 1:height(designTable)
    % Check if the mouse is in any front port at the current time bin
    if any(frontPortTimeInMatrix(t, :) == 1)
        % If we're in any front port, repeat the last valid value of RewardHistory
        if designTable.RewardHistory(t) > 0
            lastFrontRewardHistory = designTable.RewardHistory(t);  % Update the last valid RewardHistory
        end
        
        % Set the RewardHistory value for the current bin
        designTable.RewardHistory(t) = lastFrontRewardHistory;
    end
end

% --------------------- Second loop: Handle fReward for front ports (1-5) ---------------------

for t = 1:height(designTable)
    % Check if the mouse is in any front port at the current time bin
    if any(frontPortTimeInMatrix(t, :) == 1)
        % If we're in any front port, repeat the last valid value of fReward
        if designTable.fReward(t) > 0
            lastFrontReward = designTable.fReward(t);  % Update the last valid fReward
        end
        
        % Set the fReward value for the current bin
        designTable.fReward(t) = lastFrontReward;
    end
end

% --------------------- Third loop: Handle Reward for the back port (Port 6) ---------------------

for t = 1:height(designTable)
    % Check if the mouse is in the back port (Port 6) at the current time bin
    if backPortTimeIn(t) == 1
        % If we're in the back port, repeat the last valid value of Reward
        if designTable.Reward(t) > 0
            lastBackReward = designTable.Reward(t);  % Update the last valid back Reward
        end
        
        % Set the Reward value for the current bin (back port only)
        designTable.Reward(t) = lastBackReward;
    end
end





%% add interaction terms 

% % Initialize interaction terms
% portRewardInteraction = zeros(height(designTable), 6);  % 6 ports
% 
% % Loop through each port and create interaction terms between port entry and reward history
% for port = 1:6
%     portIn = designTable.(['Port', num2str(port), 'TimeIn']);  % Extract PortXIn variable
%     currentReward = designTable.Reward;  % Reward at current time bin
%     previousReward = designTable.RewardHistory;  % Reward at previous port
%     
%     % Create interaction terms (portIn * previousReward and portIn * currentReward)
%     portRewardInteraction(:, port) = portIn .* previousReward + portIn .* currentReward;
% end
% 
% % Add the interaction terms to the design table
% interactionTermNames = {'Port1RewardInteraction', 'Port2RewardInteraction', 'Port3RewardInteraction', ...
%                         'Port4RewardInteraction', 'Port5RewardInteraction','Port6RewardInteraction'};
% interactionTable = array2table(portRewardInteraction, 'VariableNames', interactionTermNames);
% 
% % Append the interaction terms to the existing designTable
% designTable = [designTable, interactionTable];

% Specify the new desired order of variable names
newOrder = {'Port1TimeIn', 'Port2TimeIn', 'Port3TimeIn','Port4TimeIn', 'Port5TimeIn','Port6TimeIn','fReward', 'RewardHistory','Reward','Cue'};

% newOrder = {'Port1TimeIn', 'Port2TimeIn', 'Port3TimeIn','Port4TimeIn', 'Port5TimeIn','Port6TimeIn', 'Reward', 'RewardHistory','Cue'...
%     'Port1RewardInteraction', 'Port2RewardInteraction', 'Port3RewardInteraction', ...
%     'Port4RewardInteraction', 'Port5RewardInteraction','Port6RewardInteraction'};


% Reorder the table columns
designTable = designTable(:, newOrder);

%%
cpd=cellfun(@(x) calculateCPD(designTable,x),Y,'uni',false);
%%
 %Sess.psth(1,'event','Reward','trialtype', 'Laser Off')
 %Sess.raster(4,'event','Reward','trialtype', 'Laser Off')
% 
% Sess.raster(2,'event','Port[1234]In','bpod',true,'trialtype', 'Laser Off','ignoreRepeats',true)
% Sess.psth(2,'event','Port[1234]In','bpod',true,'trialtype', 'Laser Off','ignoreRepeats',true)
end 

%% 
function cpd = calculateCPD(dm, Y)
    % Function to fit a GLM, identify significant coefficients, and calculate CPD.
    newVariableTable = array2table(Y', 'VariableNames', {'FiringRate'});
    dmat=table2array(dm);
    dm=[dm newVariableTable];
% Concatenate the new variable with the existing table, placing it at the beginning
    %% 
designTable=dm;

%% Convolve
% Define parameters for the Gaussian kernel
sigma = 2;  % Standard deviation of the Gaussian (adjust based on your needs)
timeWindow = 100;  % Duration for convolution (e.g., 100 ms)
samplingRate = 20;  % Sampling rate for 50 ms bins

% Convert time window from ms to time bins
timePoints = -floor(timeWindow * samplingRate / 1000) : floor(timeWindow * samplingRate / 1000);  % Symmetric around 0

% Define the Gaussian kernel
gaussianKernel = exp(-timePoints.^2 / (2 * sigma^2));
gaussianKernel = gaussianKernel / sum(gaussianKernel);  % Normalize the kernel

% Initialize matrix to hold the convolved data
convolvedMatrix = [];

% Convolve each PortIn and PortOut variable with the Gaussian kernel
%portVariables ={'Reward','Cue','Port1RewardInteraction', 'Port2RewardInteraction', 'Port3RewardInteraction', ...
            %     'Port4RewardInteraction', 'Port5RewardInteraction','Port6RewardInteraction'};
portVariables =designTable.Properties.VariableNames;

for i = 1:length(portVariables)
    varName = portVariables{i};
    varData = designTable.(varName);  % Extract the binary data for the current variable
    
    % Perform the convolution with the Gaussian kernel
    convolvedData = conv(varData, gaussianKernel, 'same');  % Convolve with the kernel
    
    % Append the convolved data to the matrix
    convolvedMatrix = [convolvedMatrix, convolvedData];
end

% Create new variable names for the convolved data (same as the original ones)
convolvedVariableNames = portVariables;

% Convert the convolved data into a table
convolvedTable = array2table(convolvedMatrix, 'VariableNames', convolvedVariableNames);

% Replace the original PortIn and PortOut variables with the convolved versions
designTable(:, convolvedVariableNames) = convolvedTable;
  
% %% 
% % Fit the original GLM model
% mdl = fitglm(designTable, 'Distribution', 'normal');
% 
% % Initialize a structure to store partial R-squared results for task-related variables
% partialRSquaredTaskVariables = struct();
% 
% predictorNames = mdl.CoefficientNames(2:end);  % Skip the intercept
% cpd=zeros(1,numel(predictorNames));
% % Loop over each task-related variable to shuffle and calculate partial R-squared
% for i = 1:length(predictorNames)
%     varName = predictorNames{i};
%     
%     % Shuffle the current task-related variable
%     shuffledTable = designTable;
%     columnData = table2array(shuffledTable(:, varName));
%     shuffledData = columnData(randperm(length(columnData)));
%     shuffledTable.(varName) = shuffledData;
%     
%     % Fit the model with the shuffled task-related variable (spike history remains intact)
%     mdlShuffled = fitglm(shuffledTable,'Distribution', 'normal');
%     
%     % Calculate the partial R-squared for the task-related variable (after accounting for spike history)
%        temp = (( mdlShuffled.SSE - mdl.SSE) /  mdlShuffled.SSE) * 100;
%             if temp < 0
%                 temp = NaN;
%             end
%     partialRSquaredTaskVariables.(varName) = temp;
%     cpd(i)=temp;
% end
% 
% cpd(mdl.Coefficients.pValue(2:end)>0.05)=NaN;


% Define main effects and interaction terms as before


   
    % Fit a stepwise GLM
    mdl = stepwiselm(designTable,'Verbose',0);
    cpd=mdl.Coefficients;
      




end


