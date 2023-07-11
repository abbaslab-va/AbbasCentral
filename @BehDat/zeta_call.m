function sigs=zeta_call(obj, event, varargin) 

% OUTPUT:'lineStyle','--'
% INPUT:
%     event -  an event character vector from the bpod SessionData
% optional name/value pairs:
%     'offset' - a number that defines the offset from the alignment you wish to center around.
%     'outcome' - an outcome character array found in config.ini
%     'trialType' - a trial type found in config.ini

p = parse_BehDat('event', 'offset', 'outcome', 'trialType', 'trials','bpod');
addParameter(p,'length', 0.5, @isnumeric);
addParameter(p, 'excludeEventsByState', [], @ischar);

parse(p, event, varargin{:});
a = p.Results;
event = a.event;
offset = a.offset;
outcomeField = a.outcome;
trialTypeField = a.trialType;
useBpod = a.bpod;

if useBpod
    events = obj.find_bpod_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset,'excludeEventsByState',a.excludeEventsByState);
    events=uniquetol(events,0.5*30000,'DataScale',1);
else
    events = obj.find_event(a.event, 'trialType', a.trialType, 'outcome', a.outcome, 'offset', a.offset);
end

%events=obj.find_event(a.event,'trialType', trialTypeField, 'offset', offset);

vecStimulusStartTimes=events(:)/obj.info.baud;
vecStimulusStopTimes=vecStimulusStartTimes+a.length;

for neuron=1:numel(obj.spikes)

vecSpikeTimes = obj.spikes(neuron).times/obj.info.baud;


 matEventTimes = cat(2,vecStimulusStartTimes,vecStimulusStopTimes);

% [vecTime,vecRate,sIFR] = getIFR(vecSpikeTimes,vecStimulusStartTimes);


 sigs{neuron} = zetatest(vecSpikeTimes,vecStimulusStartTimes);
end 