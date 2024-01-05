function [cPortTimes,cReward,pPortTimes,pReward,pPid,nPortTimes,nReward,nPid,adjust,chirpOccur] = find_port(obj,varargin)



% OUTPUT:
%     timestamps - a 1xE vector of timestamps from the desired event
% INPUT:
%     event -  an event character vector from the bpod SessionData
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'trials' - a vector of trial numbers to include
%     'trialized' - a logical that determines whether to return a cell array of timestamps for each trial or a vector of all timestamps
%     'excludeEventsByState' - a character vector of a state to exclude trials from
%     'withinState' - a character vector, string, or cell array of a state(s) to find the event within
%     'priorToState' - a character vector, string, or cell array of a state(s) to find the event prior to
%     'priorToEvent' - a character vector of an event to find the time prior to
presets=PresetManager(varargin{:});
validStates = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
p=inputParser;
p.KeepUnmatched=true;
addParameter(p, 'withinStateCell', [], validStates);
parse(p, varargin{:});

event = presets.event;
offset = round(presets.offset * obj.info.baud);
outcomeField = presets.outcome;
trialTypeField = presets.trialType;
trials = presets.trials;
trialized = presets.trialized;
rawEvents = obj.bpod.RawEvents.Trial;
rawData = obj.bpod.RawData;
excludeEventsByState = presets.excludeEventsByState;
withinState = presets.withinState;
priorToState = presets.priorToState;
priorToEvent = presets.priorToEvent;

% Find trial start times in acquisition system timestamps
trialStartTimes = obj.find_event('event','Trial Start');
% Identify trials with the event of interest
fieldNames = cellfun(@(x) fields(x.Events), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) regexp(fields(x.Events), event), rawEvents, 'uni', 0);
trialHasEvent = cellfun(@(x) cellfun(@(y) ~isempty(y), x), trialHasEvent, 'uni', 0);
fieldsToIndex = cellfun(@(x, y) x(y), fieldNames, trialHasEvent, 'uni', 0);
eventTimes = cellfun(@(x, y) cellfun(@(z) x.Events.(z), y, 'uni', 0), rawEvents, fieldsToIndex, 'uni', 0);
% Initialize trial intersect vectors
numTrialStart = numel(trialStartTimes);
eventTrials = 1:numTrialStart;
eventTrialTypes = obj.bpod.TrialTypes(eventTrials);
eventOutcomes = obj.bpod.SessionPerformance(eventTrials);
trialIncluded = ones(1, numel(eventTrials));
isDesiredTT = trialIncluded;
isDesiredOutcome = trialIncluded;

if ischar(trialTypeField)
    trialTypeField = regexprep(trialTypeField, " ", "_");
    try
        trialTypes = obj.info.trialTypes.(trialTypeField);
        isDesiredTT = ismember(eventTrialTypes, trialTypes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeField));
        throw(mv)
    end
elseif iscell(trialTypeField)
    numTT = numel(trialTypeField);
    intersectMat = zeros(numTT, numel(eventTrials));
    for tt = 1:numTT
        trialTypeString = regexprep(trialTypeField{tt}, " ", "_");
        try
            trialTypes = obj.info.trialTypes.(trialTypeString);
            intersectMat(tt, :) = ismember(eventTrialTypes, trialTypes);
        catch
            mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeString));
            throw(mv)
        end
    end
    isDesiredTT = any(intersectMat, 1);
end

if ~isempty(outcomeField)
    outcomeField(outcomeField == ' ') = '_';
    try
        outcomes = obj.info.outcomes.(outcomeField);
        isDesiredOutcome = ismember(eventOutcomes, outcomes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeField));
        throw(mv)
    end
end

if ~isempty(trials)
    trialIncluded = ismember(eventTrials, trials);
end

% Intersect all logical matrices to index bpod trial cells with
goodTrials = isDesiredTT & isDesiredOutcome & trialIncluded;

trialStartTimes = num2cell(trialStartTimes(goodTrials));
rawEvents2Check = rawEvents(goodTrials);
rawData2Check = structfun(@(x) x(goodTrials), rawData, 'uni', 0);
eventTimes2Check = eventTimes(goodTrials);
goodEventTimes = cellfun(@(x) [x{:}], eventTimes2Check, 'uni', 0);

if ~isempty(excludeEventsByState)
    % Get cell array of all state times to exclude events within
    goodStates = cellfun(@(x) strcmp(fields(x.States), excludeEventsByState), rawEvents2Check, 'uni', 0);
    trialCells = cellfun(@(x) struct2cell(x.States), rawEvents2Check, 'uni', 0);
    excludeStateTimes = cellfun(@(x, y) x(y), trialCells, goodStates);
    % Find those state times that are nan (did not happen in the trial)
    nanStates = cellfun(@(x) isnan(x(1)), excludeStateTimes);
    % This replaces all the times that were nans with negative state edges
    % since that's something that will never happen in a bpod state and
    % it's easier than removing those trials
    for i = find(nanStates)
        excludeStateTimes{i} = [-2 -1];
    end
    excludeStateTimes = cellfun(@(x) num2cell(x, 2), excludeStateTimes, 'uni', 0);
    timesToRemove = cellfun(@(x, y) cellfun(@(z) discretize(x, z), y, 'uni', 0), goodEventTimes, excludeStateTimes, 'uni', 0);
    timesToRemove = cellfun(@(x) cat(1, x{:}), timesToRemove, 'uni', 0);
    timesToRemove = cellfun(@(x) any(x == 1, 1), timesToRemove, 'uni', 0);
    goodEventTimes = cellfun(@(x, y) x(~y), goodEventTimes, timesToRemove, 'uni', 0);
end



if ~isempty(priorToState)    
    stateNumbers = rawData2Check.OriginalStateData;
    stateNames = rawData2Check.OriginalStateNamesByNumber;
    sortedStateNames = cellfun(@(x, y) x(y), stateNames, stateNumbers, 'uni', 0);
    sortedStateTimes = cellfun(@(x) x(1:end-1), rawData2Check.OriginalStateTimestamps, 'uni', 0);
    [sortedEventNames, eventInds] = cellfun(@(x) map_bpod_events(x), rawData2Check.OriginalEventData, 'uni', 0);
    sortedEventTimes = cellfun(@(x, y) x(y), rawData2Check.OriginalEventTimestamps, eventInds, 'uni', 0); 
    eventAndStateTimes = cellfun(@(x, y) [x y], sortedEventTimes, sortedStateTimes, 'uni', 0);
    eventAndStateNames = cellfun(@(x, y) [x y], sortedEventNames, sortedStateNames, 'uni', 0);
    [sortedCombinedTimes, sortedCombinedInds] = cellfun(@(x) sort(x), eventAndStateTimes, 'uni', 0);
    sortedEventAndStateNames = cellfun(@(x, y) x(y), eventAndStateNames, sortedCombinedInds, 'uni', 0);
    currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedCombinedTimes, goodEventTimes, 'uni', 0);
    priorToStateTimes = cellfun(@(x) strcmp(x, priorToState), sortedEventAndStateNames, 'uni', 0);
    % Shift priorTo matrix one event to the left, eliminate the last event
    % due to circular shifting, and intersect logical matrices
    eventPriorToState = cellfun(@(x) circshift(x, -1), priorToStateTimes, 'uni', 0);
    for t = 1:numel(eventPriorToState)
        eventPriorToState{t}(end) = false;
    end
    timesToKeep = cellfun(@(x, y) x & y, currentEventTimes, eventPriorToState, 'uni', 0);
    goodEventTimes = cellfun(@(x, y) x(y), sortedCombinedTimes, timesToKeep, 'uni', 0);
end

% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, goodEventTimes, bpodStartTimes, 'uni', 0);
% subtract the factor by which bpod outpaces the blackrock system
averageOffset = num2cell(obj.sampling_diff(presets));
eventOffsetCorrected = cellfun(@(x,y) round(x - x.*y), eventOffset,averageOffset, 'uni', 0);
eventTimesCorrected = cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrected, 'uni', 0);

% eventTimesCorrected=  a cell array of trials, each cell has events in
% them in blackrock sampling time 
allTrials=eventTimesCorrected;  

%% 
% find if chirp occured withing 1 sec of port in event  
stateTimes = obj.find_bpod_state('ChirpPlay','preset',presets);

stateTimes=cellfun(@(x) cellfun(@(y) [y(1)-1*30000 y(2)],x,'uni',0), stateTimes,'uni',0);


% This double cellfun operates on withinState which contains a cell for each trial,
% with a cell for each state inside of that.
goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), stateTimes, eventTimesCorrected, 'uni', 0);
includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
eventTimesCorrectedChirp = cellfun(@(x, y) x(y), eventTimesCorrected, includeTimes, 'uni', 0);


chirpOccur=cellfun(@(x,y) ismember(x,y), eventTimesCorrected,eventTimesCorrectedChirp,'uni',0);


%% finds if Current port is rewarded 
%find state times of reward port 3 ports 
stateTimes = obj.find_bpod_state(withinState, 'outcome', outcomeField, 'trialType', trialTypeField,'trials', trials);

% This double cellfun operates on withinState which contains a cell for each trial,
% with a cell for each state inside of that.
goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), stateTimes, eventTimesCorrected, 'uni', 0);
includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
eventTimesCorrectedCurrentR = cellfun(@(x, y) x(y), eventTimesCorrected, includeTimes, 'uni', 0);

cRewarded=cellfun(@(x,y) ismember(x,y), eventTimesCorrected,eventTimesCorrectedCurrentR,'uni',0);

%% find previous port 

[sortedNames, eventInds] = cellfun(@(x) map_bpod_events(x), rawData2Check.OriginalEventData, 'uni', 0);
sortedTimes = cellfun(@(x, y) x(y), rawData2Check.OriginalEventTimestamps, eventInds, 'uni', 0); 
% Event times are now organized chronologically in sortedTimes, with a
% corresponding cell array for the names of the events
currentEventTimes = cellfun(@(x, y) ismember(x, y), sortedTimes, goodEventTimes, 'uni', 0);
eventPrior = cellfun(@(x) circshift(x, -2),  currentEventTimes, 'uni', 0);
prevPort= cellfun(@(x, y) x(y), sortedNames, eventPrior, 'uni', 0);
prevPortTimes= cellfun(@(x, y) x(y), sortedTimes, eventPrior, 'uni', 0);

% take out events where the previous event is the same, this is made here
% but done later
for c=1:numel(prevPort)
    prevPortLeaveOut{c}=zeros(1,length(prevPort{c}));
    for e=numel(prevPort{c}):-1:1
        if strcmp(prevPort{c}(e),event) || strcmp(prevPort{c}(e),[event(1:5),'Out'])
            prevPortLeaveOut{c}(e)=1;
        end 
    end 
end 

%just changing from srtrings to numbers 
for c=1:numel(prevPort)
    for e=1:numel(prevPort{c})
        if strcmp(prevPort{c}(e),'Port1Out') || strcmp(prevPort{c}(e),'Port1In')
            prevPort{c}{e}=1;
        elseif strcmp(prevPort{c}(e),'Port2Out') || strcmp(prevPort{c}(e),'Port2In')
            prevPort{c}{e}=2;
        elseif strcmp(prevPort{c}(e),'Port3Out') || strcmp(prevPort{c}(e),'Port3In')
            prevPort{c}{e}=3;
        elseif strcmp(prevPort{c}(e),'Port4Out') || strcmp(prevPort{c}(e),'Port4In')
            prevPort{c}{e}=4;
        elseif strcmp(prevPort{c}(e),'Port5Out') || strcmp(prevPort{c}(e),'Port5In')
            prevPort{c}{e}=5;
        elseif strcmp(prevPort{c}(e),'Port7Out') || strcmp(prevPort{c}(e),'Port7In')
            prevPort{c}{e}=7;
        end 
    end
end 

% convert prevPorttimes (in bpod time) to blackrocktime 
eventOffsetPrev = cellfun(@(x, y) (x - y) * obj.info.baud, prevPortTimes, bpodStartTimes, 'uni', 0);
eventOffsetCorrectedPrev = cellfun(@(x,y) round(x - x.*y), eventOffsetPrev,averageOffset, 'uni', 0);
eventTimesCorrectedPrevPortTimes= cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrectedPrev, 'uni', 0);



%% find if Previous port is rewarded 
withinStateCell={'Reward1_1', 'Reward2_1', 'Reward3_1' ,'Reward4_1' ,'Reward5_1', 'Reward'};
stateTimeCell = cellfun(@(x) obj.find_bpod_state(x, 'outcome', outcomeField, 'trialType', trialTypeField,'trials', trials), withinStateCell, 'uni', 0);
stateTimeCell = cat(1, stateTimeCell{:});
eventIdx = num2cell(1:numel(eventTimesCorrectedPrevPortTimes));
stateTimes = cellfun(@(x) cat(1, stateTimeCell{:, x}), eventIdx, 'uni', 0);

% This double cellfun operates on withinState which contains a cell for each trial,
% with a cell for each state inside of that.
goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), stateTimes, eventTimesCorrectedPrevPortTimes, 'uni', 0);
includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
eventTimesCorrectedPrevPortR = cellfun(@(x, y) x(y), eventTimesCorrectedPrevPortTimes, includeTimes, 'uni', 0);
eventTimesCorrectedPrevPortR=cellfun(@(x, y) ismember(x,y), eventTimesCorrectedPrevPortTimes,eventTimesCorrectedPrevPortR,'UniformOutput',0);


%%  finds Next port  
eventNext= cellfun(@(x) circshift(x, +2),  currentEventTimes, 'uni', 0);
nextPort= cellfun(@(x, y) x(y), sortedNames, eventNext, 'uni', 0);
nextPortTimes= cellfun(@(x, y) x(y), sortedTimes, eventNext, 'uni', 0);

% take out events where the previous event is the same 
for c=1:numel(nextPort)
   nextPortLeaveOut{c}=zeros(1,length(nextPort{c}));
    for e=numel(nextPort{c}):-1:1
        if strcmp(nextPort{c}(e),event) || strcmp(nextPort{c}(e),[event(1:5),'Out'])
        nextPortLeaveOut{c}(e)=1;
        end 
    end 
end 

for c=1:numel(nextPort)
    for e=1:numel(nextPort{c})
        if strcmp(nextPort{c}(e),'Port1In')|| strcmp(nextPort{c}(e),'Port1Out')
            nextPort{c}{e}=1;
        elseif strcmp(nextPort{c}(e),'Port2In') || strcmp(nextPort{c}(e),'Port2Out')
            nextPort{c}{e}=2;
        elseif strcmp(nextPort{c}(e),'Port3In') || strcmp(nextPort{c}(e),'Port3Out')
            nextPort{c}{e}=3;
        elseif strcmp(nextPort{c}(e),'Port4In') || strcmp(nextPort{c}(e),'Port4Out')
            nextPort{c}{e}=4;
        elseif strcmp(nextPort{c}(e),'Port5In') || strcmp(nextPort{c}(e),'Port5Out')
            nextPort{c}{e}=5;
        elseif strcmp(nextPort{c}(e),'Port7In') || strcmp(nextPort{c}(e),'Port7Out')
            nextPort{c}{e}=7;
        end 
    end
end 
          


% convert prevPorttimes (in bpod time) to blackrocktime 
eventOffsetNext = cellfun(@(x, y) (x - y) * obj.info.baud, nextPortTimes, bpodStartTimes, 'uni', 0);
eventOffsetCorrectedNext = cellfun(@(x,y) round(x - x.*y), eventOffsetNext,averageOffset, 'uni', 0);
eventTimesCorrectedNextPortTimes= cellfun(@(x, y) x + y, trialStartTimes, eventOffsetCorrectedNext, 'uni', 0);


%%  finds next port rewarded
eventIdx = num2cell(1:numel(eventTimesCorrectedNextPortTimes));
stateTimes = cellfun(@(x) cat(1, stateTimeCell{:, x}), eventIdx, 'uni', 0);

% This double cellfun operates on withinState which contains a cell for each trial,
% with a cell for each state inside of that.
goodTimesAll = cellfun(@(x, y) cellfun(@(z) discretize(y, z), x, 'uni', 0), stateTimes, eventTimesCorrectedNextPortTimes, 'uni', 0);
includeTimes = cellfun(@(x) cat(1, x{:}), goodTimesAll, 'uni', 0);
includeTimes = cellfun(@(x) ~isnan(x), includeTimes, 'uni', 0);
includeTimes = cellfun(@(x) any(x, 1), includeTimes, 'uni', 0);
eventTimesCorrectedNextPortR = cellfun(@(x, y) x(y), eventTimesCorrectedNextPortTimes, includeTimes, 'uni', 0);
eventTimesCorrectedNextPortR=cellfun(@(x, y) ismember(x,y), eventTimesCorrectedNextPortTimes,eventTimesCorrectedNextPortR,'UniformOutput',0);



%% if case there are emptys where no events happened 
emptyIdx=~cellfun(@isempty,eventTimesCorrected);

eventTimesCorrected=eventTimesCorrected(emptyIdx);
allTrials=allTrials(emptyIdx);
eventTimesCorrectedPrevPortTimes=eventTimesCorrectedPrevPortTimes(emptyIdx);
eventTimesCorrectedNextPortTimes=eventTimesCorrectedNextPortTimes(emptyIdx);
eventTimesCorrectedPrevPortR=eventTimesCorrectedPrevPortR(emptyIdx);
eventTimesCorrectedNextPortR=eventTimesCorrectedNextPortR(emptyIdx);
nextPort=nextPort(emptyIdx);
prevPort=prevPort(emptyIdx);


trialswhereEventisfirst=cellfun(@(x) x(1),allTrials);
trialswhereEventislast=cellfun(@(x) x(end),allTrials);

%%

for c=1:numel(allTrials)
    if trialswhereEventisfirst(c)==1 
        adjustlogical{c}=[0 ones(1,numel(eventTimesCorrected{c}(2:end)))];
    else 
        adjustlogical{c}=ones(1,numel(eventTimesCorrected{c}));
    end 
end 


for c=1:numel(allTrials)
    if trialswhereEventislast(c)==1 
        adjustlogicalEnd{c}=[ones(1,numel(eventTimesCorrected{c}(1:end-1))) 0];
    else 
        adjustlogicalEnd{c}=ones(1,numel(eventTimesCorrected{c}));
    end 
end 

adjustlogical=logical([adjustlogical{:}]);
adjustlogicalEnd=logical([adjustlogicalEnd{:}]);

prevPortLeaveOutLogical=logical([prevPortLeaveOut{:}]);
nextPortLeaveOutLogical=logical([nextPortLeaveOut{:}]);


adjust=adjustlogical & adjustlogicalEnd & ~prevPortLeaveOutLogical & ~nextPortLeaveOutLogical; 


%%




    cPortTimes=[eventTimesCorrected{:}];
    cPortTimes= cPortTimes(adjust);
    pPortTimes=[eventTimesCorrectedPrevPortTimes{:}];
    pPortTimes= pPortTimes(adjust);
    nPortTimes=[eventTimesCorrectedNextPortTimes{:}];
    nPortTimes= nPortTimes(adjust);
    cReward = [cRewarded{:}];
    cReward=cReward(adjust);
    pReward = [eventTimesCorrectedPrevPortR{:}];
    pReward= pReward(adjust);
    nReward = [eventTimesCorrectedNextPortR{:}];
    nReward= nReward(adjust);
    nPid=[nextPort{:}];
    nPid=nPid(adjust);
    nPid=[nPid{:}];
    pPid=[prevPort{:}];
    pPid=pPid(adjust);
    pPid=[pPid{:}];
    chirpOccur=[chirpOccur{:}];
    chirpOccur=chirpOccur(adjust);

    
    

end 
