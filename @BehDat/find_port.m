function [portInfo, dMat, edges] = find_port(obj, varargin)

% This is an updated find_port method that uses the BpodParser
% functionality to find the port times.
% OUTPUT:
%     portInfo - a structure containing current/previous/next port times,
%     as well as port identities, if the port was rewarded, which events
%     were excluded, and which events fall near the proximalState.
% INPUT (name/value pairs):
%     event - the main bpod event
%     trialType/outcome/stimType/trials - a trial subset from config file
%     rewardStates - a cell array full of state names that deliver reward
%     proximalState - a state name to find events near
%     proximalEdges - how far on either side of the proximal state to search
    
% Manage inputs
presets = PresetManager(varargin{:});
validVectorSize = @(x) all(size(x) == [1, 2]);
p = inputParser;
p.KeepUnmatched = true;
addParameter(p, 'rewardStates', {}, @iscell)
addParameter(p, 'proximalState', [], @ischar)
addParameter(p, 'proximalEdges', [-.5 .5], validVectorSize)
parse(p, varargin{:});
rewardStateNames = p.Results.rewardStates;
proxState = p.Results.proximalState;
proxEdges = p.Results.proximalEdges;


% Get times for all events as well as the events preceding and succeeding
% them (off by two, so it returns events of the same type (in or out))
allEventTimes = obj.bpod.event_times('preset', presets, 'ignoreRepeats', true, 'isBracketed', true);
allEventTimesUnadjusted = obj.bpod.event_times('preset', presets);
eventIncluded = cellfun(@(x, y) ismember(x, y), allEventTimesUnadjusted, allEventTimes, 'uni', 0);
[nextEventTimes, nextEventNames] = obj.bpod.event_times('preset', presets, 'returnNext', true);
nextEventID = cellfun(@(x) cellfun(@(y) str2double(y(5)), x), nextEventNames, 'uni', 0);
[prevEventTimes, prevEventNames] = obj.bpod.event_times('preset', presets, 'returnPrev', true);
prevEventID = cellfun(@(x) cellfun(@(y) str2double(y(5)), x), prevEventNames, 'uni', 0);

% Check if event occurred within the user-defined edges of the proximal state
proxStateTimes = obj.bpod.state_times(proxState, 'preset', presets);
proxStateTimesAdjusted = proxStateTimes;
trialHasState = cellfun(@(x) ~isempty(x), proxStateTimes);
proxStateEdges = cellfun(@(x) cellfun(@(y) y + proxEdges, x, 'uni', 0), proxStateTimes(trialHasState), 'uni', 0);
proxStateTimesAdjusted(trialHasState) = proxStateEdges;
[proxStateTimesAdjusted{~trialHasState}] = deal({[-2, -1]});
eventProximal = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), proxStateTimesAdjusted, allEventTimes, 'uni', 0);
eventProximal = cellfun(@(x) cat(1, x{:}), eventProximal, 'uni', 0);
whichProxState = cellfun(@(x) any(x, 2), eventProximal, 'uni', 0);
proxStateStart = cellfun(@(x, y) x(y), proxStateTimes, whichProxState, 'uni', 0);
proxStateTrials = cellfun(@(x) ~isempty(x), proxStateStart);
proxStateStart = cellfun(@(x) cellfun(@(y) y(1), x), proxStateStart(proxStateTrials), 'uni', 0);
proxStateStart = cat(1, proxStateStart{:})';
eventProximal = cellfun(@(x) any(x, 1), eventProximal, 'uni', 0);
rewardStateTimes = cellfun(@(x) obj.bpod.state_times(x, 'preset', presets), rewardStateNames, 'uni', 0);
noRewardTrials = cellfun(@(x) cellfun(@(y) isempty(y), x), rewardStateTimes, 'uni', 0);

% Loop through all reward states
eventRewarded = cell(1, numel(rewardStateNames));
prevEventRewarded = eventRewarded;
nextEventRewarded = eventRewarded;
for r = 1:numel(rewardStateTimes)
    [rewardStateTimes{r}{noRewardTrials{r}}] = deal({[-2, -1]});
    eventRewarded{r} = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), rewardStateTimes{r}, allEventTimes, 'uni', 0);
    eventRewarded{r} = cellfun(@(x) cat(1, x{:}), eventRewarded{r}, 'uni', 0);
    prevEventRewarded{r} = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), rewardStateTimes{r}, prevEventTimes, 'uni', 0);
    prevEventRewarded{r} = cellfun(@(x) cat(1, x{:}), prevEventRewarded{r}, 'uni', 0);
    nextEventRewarded{r} = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), rewardStateTimes{r}, nextEventTimes, 'uni', 0);
    nextEventRewarded{r} = cellfun(@(x) cat(1, x{:}), nextEventRewarded{r}, 'uni', 0);
end

% Some dumb concatenation scheme
eventRewarded = cat(1, eventRewarded{:});
eventRewarded = arrayfun(@(i) vertcat(eventRewarded{:, i}), 1:size(eventRewarded, 2), 'UniformOutput', false);
eventRewarded = cellfun(@(x) any(x, 1), eventRewarded, 'uni', 0);
prevEventRewarded = cat(1, prevEventRewarded{:});
prevEventRewarded = arrayfun(@(i) vertcat(prevEventRewarded{:, i}), 1:size(prevEventRewarded, 2), 'UniformOutput', false);
prevEventRewarded = cellfun(@(x) any(x, 1), prevEventRewarded, 'uni', 0);
nextEventRewarded = cat(1, nextEventRewarded{:});
nextEventRewarded = arrayfun(@(i) vertcat(nextEventRewarded{:, i}), 1:size(nextEventRewarded, 2), 'UniformOutput', false);
nextEventRewarded = cellfun(@(x) any(x, 1), nextEventRewarded, 'uni', 0);

% Convert to blackrock sampling rate
allEventTimesBR = obj.bpod_to_blackrock(allEventTimes, presets);
prevEventTimes = obj.bpod_to_blackrock(prevEventTimes, presets);
nextEventTimes = obj.bpod_to_blackrock(nextEventTimes, presets);

% Concatenate all outputs
allEventTimes = cat(2, allEventTimes{:});
allEventTimesBR = cat(2, allEventTimesBR{:});
eventRewarded = cat(2, eventRewarded{:});
prevEventTimes = cat(2, prevEventTimes{:});
prevEventRewarded = cat(2, prevEventRewarded{:});
prevEventID = cat(2, prevEventID{:});
nextEventTimes = cat(2, nextEventTimes{:});
nextEventRewarded = cat(2, nextEventRewarded{:});
nextEventID = cat(2, nextEventID{:});
eventIncluded = cat(2, eventIncluded{:});
eventProximal = cat(2, eventProximal{:});
proxStateStartAll = nan(size(eventProximal));
proxStateStartAll(eventProximal) = proxStateStart - allEventTimes(eventProximal);

% Bin 
baud=30000;
%edges are bins from prev to next port
%zero-padded
zeroPad=.1*baud;
edges=arrayfun(@(x,y) [x-zeroPad y+zeroPad],prevEventTimes,nextEventTimes,'uni',0);

% create binned event times
BINprevEventTimes=cellfun(@(x,y) histcounts(y,'BinEdges',x(1):baud/1000*presets.binWidth:x(2)),edges,num2cell(prevEventTimes),'UniformOutput',false);
BINnextEventTimes=cellfun(@(x,y) histcounts(y,'BinEdges', x(1):baud/1000*presets.binWidth:x(2)),edges,num2cell(nextEventTimes),'UniformOutput',false);
BINallEventTimesBR=cellfun(@(x,y) histcounts(y,'BinEdges',x(1):baud/1000*presets.binWidth:x(2)),edges,num2cell(allEventTimesBR),'UniformOutput',false);

%create rewarded bins 
BINprevEventRewarded=BINprevEventTimes;
for c=1:numel(BINprevEventRewarded)
    if prevEventRewarded(c)==1
    else
    BINprevEventRewarded{c}=[zeros(1,numel(BINprevEventRewarded{c}))];
    end 
end 

BINallEventRewarded=BINallEventTimesBR;
for c=1:numel(BINallEventRewarded)
    if eventRewarded(c)==1
    else
    BINallEventRewarded{c}=[zeros(1,numel(BINallEventRewarded{c}))];
    end 
end 

BINnextEventRewarded=BINnextEventTimes;
for c=1:numel(BINnextEventRewarded)
    if nextEventRewarded(c)==1
    else
    BINnextEventRewarded{c}=[zeros(1,numel(BINnextEventRewarded{c}))];
    end 
end 


% create binned identity
% Previous 
% % Catagorical: 
% BINprevEventIDidx=cellfun(@(x) find(x==1),BINprevEventTimes);
% BINprevEventID=cellfun(@(x) zeros(1,length(x)),BINprevEventTimes,'uni',0);
% for c=1:numel(prevEventID)
%     BINprevEventID{c}(BINprevEventIDidx(c))=prevEventID(c);
% end 

% % Dummy 
% BINprevEventIDidx=cellfun(@(x) find(x==1),BINprevEventTimes);
% BINprevEventID1=cellfun(@(x) zeros(1,length(x)),BINprevEventTimes,'uni',0);
% BINprevEventID2=BINprevEventID1;
% BINprevEventID3=BINprevEventID1;
% BINprevEventID4=BINprevEventID1;
% BINprevEventID5=BINprevEventID1;
% BINprevEventIDb=BINprevEventID1;
% 
% for c=1:numel(prevEventID)
%     if prevEventID(c)==1
%         BINprevEventID1{c}(BINprevEventIDidx(c))=1;
%     elseif prevEventID(c)==2
%         BINprevEventID2{c}(BINprevEventIDidx(c))=1;
%     elseif prevEventID(c)==3
%         BINprevEventID3{c}(BINprevEventIDidx(c))=1;
%     elseif prevEventID(c)==4
%         BINprevEventID4{c}(BINprevEventIDidx(c))=1;
%     elseif prevEventID(c)==5
%         BINprevEventID5{c}(BINprevEventIDidx(c))=1;
%     elseif prevEventID(c)==7
%         BINprevEventIDb{c}(BINprevEventIDidx(c))=1;
%     end 
% end 

% Current

% %catagorical
% cPort=str2num(presets.event(5));
% BINallEventIDidx=cellfun(@(x) find(x==1),BINallEventTimesBR);
% BINallEventID=cellfun(@(x) zeros(1,length(x)),BINallEventTimesBR,'uni',0);
% for c=1:numel(allEventTimes)
%     BINallEventID{c}(BINallEventIDidx(c))=cPort;
% end 

% %Dummy 
% BINallEventIDidx=cellfun(@(x) find(x==1),BINallEventTimesBR);
% BINallEventID1=cellfun(@(x) zeros(1,length(x)),BINallEventTimesBR,'uni',0);
% BINallEventID2=BINallEventID1;
% BINallEventID3=BINallEventID1;
% BINallEventID4=BINallEventID1;
% BINallEventID5=BINallEventID1;
% BINallEventIDb=BINallEventID1;
% 
% if strcmp(presets.event,'Port1In')
%     for c=1:numel(prevEventID)
%     BINallEventID1{c}(BINallEventIDidx(c))=1;
%     end 
% elseif strcmp(presets.event,'Port2In')
%     for c=1:numel(prevEventID)
%     BINallEventID2{c}(BINallEventIDidx(c))=1;
%     end
% elseif strcmp(presets.event,'Port3In')
%     for c=1:numel(prevEventID)
%     BINallEventID3{c}(BINallEventIDidx(c))=1;
%     end
% elseif strcmp(presets.event,'Port4In')
%     for c=1:numel(prevEventID)
%     BINallEventID4{c}(BINallEventIDidx(c))=1;
%     end
% elseif strcmp(presets.event,'Port5In')
%     for c=1:numel(prevEventID)
%     BINallEventID5{c}(BINallEventIDidx(c))=1;
%     end
% elseif strcmp(presets.event,'Port7In')
%     for c=1:numel(prevEventID)
%     BINallEventIDb{c}(BINallEventIDidx(c))=1;
%     end
% end 

% Next

% % Catagorical: 
% BINnextEventIDidx=cellfun(@(x) find(x==1),BINnextEventTimes);
% BINnextEventID=cellfun(@(x) zeros(1,length(x)),BINnextEventTimes,'uni',0);
% for c=1:numel(nextEventID)
%     BINnextEventID{c}(BINnextEventIDidx(c))=nextEventID(c);
% end 

% % dummy 
% BINnextEventIDidx=cellfun(@(x) find(x==1),BINnextEventTimes);
% BINnextEventID1=cellfun(@(x) zeros(1,length(x)),BINnextEventTimes,'uni',0);
% BINnextEventID2=BINnextEventID1;
% BINnextEventID3=BINnextEventID1;
% BINnextEventID4=BINnextEventID1;
% BINnextEventID5=BINnextEventID1;
% BINnextEventIDb=BINnextEventID1;
% 
% for c=1:numel(nextEventID)
%     if nextEventID(c)==1
%         BINnextEventID1{c}(BINnextEventIDidx(c))=1;
%     elseif nextEventID(c)==2
%         BINnextEventID2{c}(BINnextEventIDidx(c))=1;
%     elseif nextEventID(c)==3
%         BINnextEventID3{c}(BINnextEventIDidx(c))=1;
%     elseif nextEventID(c)==4
%         BINnextEventID4{c}(BINnextEventIDidx(c))=1;
%     elseif nextEventID(c)==5
%         BINnextEventID5{c}(BINnextEventIDidx(c))=1;
%     elseif nextEventID(c)==7
%         BINnextEventIDb{c}(BINnextEventIDidx(c))=1;
%     end 
% end 


% Create output struct
portTimes = struct('previous', prevEventTimes, 'current', allEventTimesBR, 'next', nextEventTimes);
portRewards = struct('previous', prevEventRewarded, 'current', eventRewarded, 'next', nextEventRewarded);
portID = struct('previous', prevEventID, 'next', nextEventID);
proximalInfo = struct('inRange', eventProximal, 'stateStart', proxStateStartAll);
portInfo = struct('times', portTimes, 'reward', portRewards, 'identity', portID, 'proximal', proximalInfo, 'included', eventIncluded);




% create old trialized structure 
dMat(:,1)=prevEventID;
dMat(:,2)=repelem(str2num(presets.event(5)),numel(allEventTimes));
dMat(:,3)=nextEventID;
dMat(:,4)=prevEventRewarded;
dMat(:,5)=eventRewarded;
dMat(:,6)=nextEventRewarded;


% create binned output structure 

% % design matrix catagorical
% dMat(:,1)=[BINprevEventID{:}];
% dMat(:,2)=[BINallEventID{:}];
% dMat(:,3)=[BINnextEventID{:}];
% 
% dMat(:,4)=[BINprevEventRewarded{:}];
% dMat(:,5)=[BINallEventRewarded{:}];
% dMat(:,6)=[BINnextEventRewarded{:}];
% 

%design matrix dummy 
% dMat(:,1)=[BINprevEventID1{:}];
% dMat(:,2)=[BINprevEventID2{:}];
% dMat(:,3)=[BINprevEventID3{:}];
% dMat(:,4)=[BINprevEventID4{:}];
% dMat(:,5)=[BINprevEventID5{:}];
% dMat(:,6)=[BINprevEventIDb{:}];
% 
% dMat(:,7)=[BINallEventID1{:}];
% dMat(:,8)=[BINallEventID2{:}];
% dMat(:,9)=[BINallEventID3{:}];
% dMat(:,10)=[BINallEventID4{:}];
% dMat(:,11)=[BINallEventID5{:}];
% dMat(:,12)=[BINallEventIDb{:}];
% 
% dMat(:,13)=[BINnextEventID1{:}];
% dMat(:,14)=[BINnextEventID2{:}];
% dMat(:,15)=[BINnextEventID3{:}];
% dMat(:,16)=[BINnextEventID4{:}];
% dMat(:,17)=[BINnextEventID5{:}];
% dMat(:,18)=[BINnextEventIDb{:}];
% 
% dMat(:,19)=[BINprevEventRewarded{:}];
% dMat(:,20)=[BINallEventRewarded{:}];
% dMat(:,21)=[BINnextEventRewarded{:}];
% 
% 
% dMat=logical(dMat);







