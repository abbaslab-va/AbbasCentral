
function designTable = binned_port_identity(obj)


    binSize=50;
    stepSize = floor(30000/1000*binSize);
    eventEdges=[1 obj.info.samples];
    binEdges = eventEdges(1):stepSize:eventEdges(2);
    
    
    
    temp1=struct2cell(obj.spikes);
    spike_cellery=temp1(1,:);
    
    
    binnedSpikes= cellfun(@(x) histcounts(x, 'BinEdges', binEdges),spike_cellery,'UniformOutput',false);
    
    
    Y= cellfun(@(x) normalize(smoothdata(x,2,"gaussian",50),'range'),binnedSpikes,'UniformOutput',false);
    
    %figure()
    %plot(Y{24})
    
    %% Events
    % In/Out
    ports={'Port1In','Port2In','Port3In','Port4In','Port5In', 'Port7In'};
    for p=1:numel(ports)
        Pin{p} = obj.find_event('event', ports{p}, 'bpod',true, 'trialtype', 'Laser On','removeEnds', true, 'ignoreRepeats', true);
    end 
    
    
    for p=1:numel(ports)
        Pout{p} = obj.find_event('event', ports{p}, 'bpod',true, 'trialtype', 'Laser On','returnOut', true,'removeEnds', true,'ignoreRepeats', true);
    end 
    
    
    binnedPortsOut = cellfun(@(x) histcounts(x, 'BinEdges', binEdges),Pout,'uni',false) ; 
    binnedPortsIn = cellfun(@(x) histcounts(x, 'BinEdges', binEdges),Pin,'uni',false) ; 
    
    
    % Forage Reward 
    fReward= obj.find_event('event','Forage', 'trialtype', 'Laser On');
    binnedPortsfReward = histcounts(fReward, 'BinEdges', binEdges);   
    
    
    
    
    % Reward
    Reward= obj.find_event('event','Reward', 'trialtype', 'Laser On');
    binnedPortsReward = histcounts(Reward, 'BinEdges', binEdges);    
    
    % % Reward
    % Punish= obj.find_event('event','Punish', 'trialtype', 'Laser On');
    % binnedPortsPunish = histcounts(Punish, 'BinEdges', binEdges);    
   
    
    dm=[cell2mat(binnedPortsIn')', binnedPortsfReward'];
    
    dm=array2table(dm, 'VariableNames',{'Port1In','Port2In','Port3In','Port4In','Port5In', 'Port6In','fReward'});
    designTable=dm;
    %% Cap multiple entries 
    % List the columns that need to be capped at 1 in designTable (e.g., PortIn/Out, Reward, Cue)
    columnsToCap = {'Port1In','Port2In','Port3In','Port4In','Port5In', 'Port6In','fReward'};
    
    % Loop through each column and cap its values at 1
    for i = 1:length(columnsToCap)
        columnName = columnsToCap{i};
        % Cap the values at 1
        designTable.(columnName)(designTable.(columnName) > 1) = 1;
    end
    

end 

%% 
