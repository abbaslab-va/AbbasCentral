
function designTable = make_continuous_bpod_readout(obj)
% Makes a continuous binned interpretation of a bpod behavioral session.
% Will be made to allow variable inputs to control what variables are
% binned for a given BpodParser object.

binSize = .00005; % temp to deal with microsecond state transitions, 500 us probably better
eventEdges = [0 obj.session.TrialEndTimestamp(end)];
binEdges = eventEdges(1):binSize:eventEdges(2);
outputBinSize = 0.05;   %ms
outputBinEdges = eventEdges(1):outputBinSize:eventEdges(2);
numOutputBins = numel(outputBinEdges) - 1;
conversionFactor = outputBinSize/binSize;
binnedSingleTemplate = false(numOutputBins, 1);
%% Trial level variables
outcomes = obj.session.SessionPerformance;
previousOutcomes = circshift(outcomes, 1);
previousOutcomes(1) = -1;
trialTypes = obj.session.TrialTypes;
delayLength = DMTS_tri_delay_length(obj);
delayBin = discretize(delayLength, [0 3 5 7.5]);

%% Events
% In/Out
ports = {'Port1In','Port2In','Port3In'};
pIn = cellfun(@(x) ...
    obj.event_times('event', x, 'bpod', true, 'removeEnds', true), ...
    ports, 'uni', 0);
pOut = cellfun(@(x) ...
    obj.event_times('event', x, 'bpod', true, 'returnOut', true, 'removeEnds', true), ...
    ports, 'uni', 0);
trialStart = num2cell(obj.session.TrialStartTimestamp);
trialEnd = num2cell(obj.session.TrialEndTimestamp);
pIn = cellfun(@(x) cellfun(@(y, z) ...
    y + z, x, trialStart, 'uni', 0), pIn, 'uni', 0);
pOut = cellfun(@(x) cellfun(@(y, z) ...
    y + z, x, trialStart, 'uni', 0), pOut, 'uni', 0);
pIn = cellfun(@(x) cat(2, x{:}), pIn, 'uni', 0);
pOut = cellfun(@(x) cat(2, x{:}), pOut, 'uni', 0);
binnedPortsIn = cellfun(@(x) ...
    histcounts(x, 'BinEdges', binEdges), pIn, 'uni', 0); 
binnedPortsOut = cellfun(@(x) ...
    histcounts(x, 'BinEdges', binEdges), pOut, 'uni', 0); 
summedPortsIn = cellfun(@(x) ...
    cumsum(x), binnedPortsIn, 'uni', 0);
summedPortsOut = cellfun(@(x) ...
    cumsum(x), binnedPortsOut, 'uni', 0);
binnedPortEntries = cellfun(@(x, y) ...
    x - y, summedPortsIn, summedPortsOut, 'uni', 0);
binnedPortEntries = cat(1, binnedPortEntries{:})';
%% States

binnedOutcome = binnedSingleTemplate;
binnedPrevOutcome = binnedSingleTemplate;
binnedTrialType = binnedSingleTemplate;
binnedDelayLength = binnedSingleTemplate;
stateNamesLookup = obj.session.RawData.OriginalStateNamesByNumber;
stateSequence = cellfun(@(x) ...
    num2cell(x), obj.session.RawData.OriginalStateData, 'uni', 0);
stateTimestamps = obj.session.RawData.OriginalStateTimestamps;
adjustedStateTimestamps = cellfun(@(x, y) ...
    x + y, stateTimestamps, trialStart, 'uni', 0);
binnedStateOnset = cellfun(@(x) ...
    num2cell(find(histcounts(x, 'BinEdges', binEdges))), ...
    adjustedStateTimestamps, 'uni', 0);
binnedStateEntries = false(numel(binEdges) - 1, numel(stateNamesLookup{1}));
binnedStateDuration = cellfun(@(x) cellfun(@(y, z) ...
    z - y, x(1:end-1), x(2:end), 'uni', 0), ...
    binnedStateOnset, 'uni', 0);
for trial = 1:numel(binnedStateDuration)
    startBin = round(trialStart{trial} / binSize);
    endBin = round(trialEnd{trial} / binSize);
    binnedOutcome(startBin:endBin) = outcomes(trial);
    binnedPrevOutcome(startBin:endBin) = previousOutcomes(trial);
    binnedTrialType(startBin:endBin) = trialTypes(trial);
    binnedDelayLength(startBin:endBin) = delayBin(trial);
    for state = 1:numel(binnedStateDuration{trial})
        numEntries = binnedStateDuration{trial}{state};
        stateCol = stateSequence{trial}{state};
        binnedStateEntries(startBin:startBin + numEntries-1, stateCol) = true;
        startBin = startBin + numEntries;
    end
end

%% bin size conversion
outputPortEntries = false(numOutputBins, size(binnedPortEntries, 2));
outputStateEntries = false(numOutputBins, size(binnedStateEntries, 2));

for bin = 1:numel(outputBinEdges) - 1
    collapseEdges = (bin-1)*conversionFactor + 1:bin*conversionFactor;
    outputPortEntries(bin, :) = any(binnedPortEntries(collapseEdges, :), 1);
    outputStateEntries(bin, :) = any(binnedStateEntries(collapseEdges, :), 1);
end


disp('poop')

%     % Forage Reward 
%     fReward= obj.find_event('event','Forage', 'trialtype', 'Laser On');
%     binnedPortsfReward = histcounts(fReward, 'BinEdges', binEdges);   
% 
% 
% 
% 
%     % Reward
%     Reward= obj.find_event('event','Reward', 'trialtype', 'Laser On');
%     binnedPortsReward = histcounts(Reward, 'BinEdges', binEdges);    
% 
%     % % Reward
%     % Punish= obj.find_event('event','Punish', 'trialtype', 'Laser On');
%     % binnedPortsPunish = histcounts(Punish, 'BinEdges', binEdges);    
% 
% 
%     dm=[cell2mat(binnedPortsIn')', binnedPortsfReward'];
% 
%     dm=array2table(dm, 'VariableNames',{'Port1In','Port2In','Port3In','Port4In','Port5In', 'Port6In','fReward'});
%     designTable=dm;
%     %% Cap multiple entries 
%     % List the columns that need to be capped at 1 in designTable (e.g., PortIn/Out, Reward, Cue)
%     columnsToCap = {'Port1In','Port2In','Port3In','Port4In','Port5In', 'Port6In','fReward'};
% 
%     % Loop through each column and cap its values at 1
%     for i = 1:length(columnsToCap)
%         columnName = columnsToCap{i};
%         % Cap the values at 1
%         designTable.(columnName)(designTable.(columnName) > 1) = 1;
%     end
% 
% 
% end 
% 
% %% 
