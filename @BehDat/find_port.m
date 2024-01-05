function [cPortTimes,cReward,pPortTimes,pReward,pPid,nPortTimes,nReward,nPid,adjust,chirpOccur] = find_port(obj,varargin)


% This method produces port times and reward times in the sampling rate of
% the neural acquisition system. 
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

presets = PresetManager(varargin{:});

event = presets.event;
offset = round(presets.offset * obj.info.baud);
outcomeField = presets.outcome;
trialTypeField = presets.trialType;
trials = presets.trials;
presets.trialized = true;
rawEvents = obj.bpod.RawEvents.Trial;
rawData = obj.bpod.RawData;
excludeEventsByState = presets.excludeState;
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


goodTrials = obj.trial_intersection(eventTrials, presets);

trialStartTimes = num2cell(trialStartTimes(goodTrials));
rawEvents2Check = rawEvents(goodTrials);
rawData2Check = structfun(@(x) x(goodTrials), rawData, 'uni', 0);
eventTimes2Check = eventTimes(goodTrials);
goodEventTimes = cellfun(@(x) [x{:}], eventTimes2Check, 'uni', 0);


% Find bpod intra-trial times for Trial Start timestamp
bpodStartTimes = cellfun(@(x) x.States.(obj.info.startState)(1), rawEvents2Check, 'uni', 0);
% bpodEventTimes = cellfun(@(x) x.Events.(event)(1, :), rawEvents2Check, 'uni', 0);
% Calculate differences between bpod event times and trial start times and
% convert to sampling rate of acquisition system
eventOffset = cellfun(@(x, y) (x - y) * obj.info.baud, goodEventTimes, bpodStartTimes, 'uni', 0);
% subtract the factor by which bpod outpaces the blackrock system
averageOffset = num2cell(obj.sampling_diff(presets));
eventOffsetCorrected = cellfun(@(x,y) round(x - x.*y), eventOffset,averageOffset, 'uni', 0);

eventTimesCorrected = obj.find_bpod_event('preset', presets);

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

    portTimes = struct('previous', pPortTimes, 'current', cPortTimes, 'next', nPortTimes);
    portRewards = struct('previous', pReward, 'current', cReward, 'next', nReward);
    portID = struct('previous', pPid, 'next', nPid);
    outputStruct = struct('times', portTimes, 'reward', portRewards, 'identity', portID, 'chirp', chirpOccur);

end 
