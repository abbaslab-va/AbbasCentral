function [sequence, times]=event_state_seq(obj, varargin)

% This function outputs a sankey plot showing the transitions between bpod
% states. By default, it displays all state transitions from all trial
% types, but users can use name-value pairs to only analyze certain
% combinations of trial types and outcomes, as well as only transitions to
% or from a certain state.
% 
% optional name/value pairs:
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini
%     'inputStates' - a string or cell array of strings of desired input
%     states to visualize
%     'outputStates' - a string or cell array of strings of desired output
%     states to visualize

session = obj.bpod;
defaultEvents = {'Port1In', 'Port2In', 'Port3In',...
    'Port4In', 'Port5In', 'Port6In',...
    'Port7In', 'Port8In'};              % all input events
                              % all output events
defaultStates={'Reward1_1','Reward2_1','Reward3_1','Reward4_1','Reward5_1','ChirpPlay','Reward'};

validField = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);
validState = @(x) isempty(x) || ischar(x) || isstring(x) || iscell(x);


defaultPlot=0;
p = parse_BehDat('outcome', 'trialType', 'trials');
addParameter(p, 'events', defaultEvents, validField);
addParameter(p, 'states', defaultStates, validState);
addParameter(p, 'plot', defaultPlot, @(x) isnumeric(x));

parse(p, varargin{:});
a = p.Results;
eventTrialTypes = session.TrialTypes;
eventOutcomes = session.SessionPerformance;
goodTT = true(1, session.nTrials);
goodOutcomes = true(1, session.nTrials);

if ~isempty(a.trialType)
    trialTypeField = regexprep(a.trialType, " ", "_");
    try
        trialTypes = obj.info.trialTypes.(trialTypeField);
        goodTT = ismember(eventTrialTypes, trialTypes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No TrialType %s found. Please edit config file and recreate object', trialTypeField));
        throw(mv)
    end
end

if ~isempty(a.outcome)
    outcomeField = regexprep(a.outcome, " ", "_");
    try
        outcomes = obj.info.outcomes.(outcomeField);
        goodOutcomes = ismember(eventOutcomes, outcomes);
    catch
        mv = MException('BehDat:MissingVar', sprintf('No Outcome %s found. Please edit config file and recreate object', outcomeField));
        throw(mv)
    end
end
trialsToInclude = find(goodTT & goodOutcomes);
rawEvents2Check = obj.bpod.RawEvents.Trial(trialsToInclude);
startEvent = cell(0);
endEvent = cell(0);

%%
for trial = trialsToInclude
    clearvars State
    trialEvents = session.RawData.OriginalEventData{trial};
    [eventNames, eventInds] = map_bpod_events(trialEvents);
    eventTimes = session.RawData.OriginalEventTimestamps{trial}(eventInds);
    
    stateNames = session.RawData.OriginalStateNamesByNumber{trial};
    trialStates = session.RawData.OriginalStateData{trial};
    numStates = numel(trialStates);
    stateTimes = num2cell(session.RawData.OriginalStateTimestamps{trial});


    for state = 1:numStates
        if any(strcmp(a.states, stateNames{trialStates(state)}))
            State{state} = stateNames{trialStates(state)};
        end
    end

    if exist("State",'var')
        addStateTimes=[stateTimes{~cellfun(@isempty, State)}];
        seq=[eventNames {State{~cellfun(@isempty, State)}}];
        allTimes=[eventTimes addStateTimes];
    else 
        allTimes=eventTimes;
        seq=eventNames;
    end 


  

    [sortedTime,idx]=sort(allTimes); 

    seqSorted=seq(idx);

    sequence{trial}=seqSorted;
    times{trial}=sortedTime;
end 
%%

if a.plot

dict=[a.events a.states];
dictCoord=[1 2 3 4 5 6 7 8 1.5 2.5 3.5 4.5 5.5 10 7.5];
for trial=1:numel(trialsToInclude)
    coordY=zeros(1,numel(sequence{trial}));
    for d=1:numel(dict)
        coordY(strcmp(dict{d},sequence{trial}))=dictCoord(d); 
    end
    takeIdx=coordY==0;
    coordY(coordY==0)=NaN;
    coordYtrial{trial}=coordY;
    times{trial}(takeIdx)=NaN;
    figure()
    times_out=rmmissing(times{trial});
    coord_out=rmmissing(coordYtrial{trial});
    plot(times_out,coord_out,'-o')
end
end 






