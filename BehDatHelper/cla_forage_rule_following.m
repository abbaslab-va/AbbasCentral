[pctAll, binnedPctAll] = arrayfun(@(x) get_rule_following_pct(x), allSessions, 'uni', 0);

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
    binSize = 3;
    numBins = floor(numel(nextRuleFollowed)/binSize);
    binnedRulePct = zeros(1, numBins);
    for bin = 1:numBins
        portIdx = (1:binSize)*bin;
        nextRuleBin = nextRuleFollowed(portIdx);
        binnedRulePct(bin) = sum(nextRuleBin)/binSize*100;
    end
end