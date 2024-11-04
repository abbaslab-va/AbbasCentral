%[pctAllLOFF, binnedPctAllLOFF] = arrayfun(@(x) get_rule_following_pct(x), allSessions([1:14,16:21]), 'uni', 0);
[pctAllLON, binnedPctAllLON] = arrayfun(@(x) get_rule_following_pct(x), allSessions([1:14,16:21]), 'uni', 0);

%%
%  for s=[1:14,16:21]
%  get_rule_following_pct(allSessions(s))
%  end 
 %%
%% 
names=arrayfun(@(x) x.info.name, allSessions([1:14,16:21]), 'uni', 0);
animals=unique(names);
figure()
for a=1:numel(animals)
    hold on
    scatter(ones(1,sum(strcmp(names,animals{a})))*a,cell2num(pctAll(strcmp(names,animals{a}))))
end 
ylim([70 100])
xlim([0.5 8.5])
xticks([1:8])
ax = gca;
ax.FontSize=20
ax.TickDir='out'
ax.LineWidth=2
xlabel('Mouse ID')
ylabel('% Correct Forage Visits')

%% 
figure()
 count=1;
hold on
for a=33:35
    plot(smoothdata(binnedPctAll{a},'movmean',20),'DisplayName',['Session ' num2str(count)],'LineWidth',1.5)
    count=count+1;
end 

ylim([70 100])
xlim([1 500])
%xlim([0.5 13.5])
%xticks([1:13])
ax = gca;
ax.FontSize=20
ax.TickDir='out'
ax.LineWidth=2
xlabel('Rewarded Forage Visits')
ylabel('% Optimal next Visit')
legend show

%%
[poop, pee] = get_rule_following_pct(allSessions(5));
%%

function [pctRuleFollowed, binnedRulePct] = get_rule_following_pct(sess)
    
    dmTable = binned_port_identity(sess);
    
    ruleID = {[2 3], ...
        [1 3], ...
        [2 4], ...
        [3 5], ...
        [3 4]};
    
    forageRewards = find(dmTable.fReward);
    whichPort = [dmTable.Port1In, dmTable.Port2In, dmTable.Port3In, dmTable.Port4In, dmTable.Port5In];
    %%
    numForageRewards = size(forageRewards, 1);
    forageIdxAll = zeros(1, numForageRewards);
    nextIdxAll = zeros(1, numForageRewards);
    hasPort = any(whichPort, 2);
    for row = 1:numForageRewards
    % for row = numForageRewards
        forageBin = forageRewards(row);
        portIdx = find(whichPort(forageBin, :));
        if isempty(portIdx)
            prevPortBin = find(hasPort(1:forageBin), 1, 'last');
            portIdx = find(whichPort(prevPortBin, :));
        end
        forageIdxAll(row) = portIdx;
        remaininingWhichPort = whichPort(forageBin+1:end, :);
        remainingHasPort = hasPort(forageBin+1:end);
        nextPortBin = find(remainingHasPort, 1, 'first');
        try
            nextIdxAll(row) = find(remaininingWhichPort(nextPortBin, :));
        catch
            nextIdxAll(row) = portIdx;
        end
    end
    goodPorts = arrayfun(@(x, y) x ~= y, forageIdxAll, nextIdxAll);
    forageIdxAll = forageIdxAll(goodPorts);
    nextIdxAll = nextIdxAll(goodPorts);
    nextRule = arrayfun(@(x) ruleID{x}, forageIdxAll, 'uni', 0);
    nextIdxCell = num2cell(nextIdxAll);
    nextRuleFollowed = cellfun(@(x, y) ismember(x, y), nextIdxCell, nextRule);
    pctRuleFollowed = sum(nextRuleFollowed)/length(nextRuleFollowed)*100;
    binSize = 50;        % Number of elements per bin
    binOverlap = 49;     % Number of elements to overlap between bins
    numBins = floor((numel(nextRuleFollowed) - binSize) / (binSize - binOverlap)) + 1;
    binnedRulePct = zeros(1, numBins);
    

    for bin = 1:numBins
        startIdx = (bin - 1) * (binSize - binOverlap) + 1; % Adjust for overlap
        endIdx = startIdx + binSize - 1;
        
        % Ensure we don't exceed the array bounds
        if endIdx > numel(nextRuleFollowed)
            endIdx = numel(nextRuleFollowed);
        end
        
        nextRuleBin = nextRuleFollowed(startIdx:endIdx);
        binnedRulePct(bin) = sum(nextRuleBin) / binSize * 100;
    end
end
%% 

function [pctRuleFollowed, binnedRulePct] = get_rule_following_pct_ap(sess)
    
    dmTable = binned_port_identity(sess);
    
    ruleID = {[2 3], ...
        [1 3], ...
        [2 4], ...
        [3 5], ...
        [3 4]};
    
    forageRewards = find([dmTable.Port1In | dmTable.Port2In | dmTable.Port3In | dmTable.Port4In |dmTable.Port5In]);
    whichPort = [dmTable.Port1In dmTable.Port2In, dmTable.Port3In, dmTable.Port4In, dmTable.Port5In];
    %%
    numForageRewards = size(forageRewards, 1);
    forageIdxAll = zeros(1, numForageRewards);
    nextIdxAll = zeros(1, numForageRewards);
    hasPort = any(whichPort, 2);
    for row = 1:numForageRewards
    % for row = numForageRewards
        forageBin = forageRewards(row);
        portIdx = find(whichPort(forageBin, :));
        if isempty(portIdx)
            prevPortBin = find(hasPort(1:forageBin), 1, 'last');
            portIdx = find(whichPort(prevPortBin, :));
        end
        forageIdxAll(row) = portIdx(1);
        remaininingWhichPort = whichPort(forageBin+1:end, :);
        remainingHasPort = hasPort(forageBin+1:end);
        nextPortBin = find(remainingHasPort, 1, 'first');
        try
            nextIdxAll(row) = find(remaininingWhichPort(nextPortBin, :));
        catch
            nextIdxAll(row) = portIdx;
        end
    end
    goodPorts = arrayfun(@(x, y) x ~= y, forageIdxAll, nextIdxAll);
    forageIdxAll = forageIdxAll(goodPorts);
    nextIdxAll = nextIdxAll(goodPorts);
    nextRule = arrayfun(@(x) ruleID{x}, forageIdxAll, 'uni', 0);
    nextIdxCell = num2cell(nextIdxAll);
    nextRuleFollowed = cellfun(@(x, y) ismember(x, y), nextIdxCell, nextRule);
    pctRuleFollowed = sum(nextRuleFollowed)/length(nextRuleFollowed)*100;
    binSize = 5;
    numBins = floor(numel(nextRuleFollowed)/binSize);
    binnedRulePct = zeros(1, numBins);
    for bin = 1:numBins
        portIdx = (1:binSize)*bin;
        nextRuleBin = nextRuleFollowed(portIdx);
        binnedRulePct(bin) = sum(nextRuleBin)/binSize*100;
    end
end







