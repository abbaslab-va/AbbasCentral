function [time_seq, spatial_seq]=behavior_sequencer(SessionData,states,events)

for trial=1:length(SessionData.RawEvents.Trial)
    %find states of interest
    for s=1:length(states)
        if states{s}=="t_start"
            stateTrial{s}=num2cell(SessionData.RawEvents.Trial{trial}.States.ITI(:,2))';
        elseif states{s}=="chirp"
            if SessionData.TrialTypes(trial)==13 || SessionData.TrialTypes(trial)==14 || SessionData.TrialTypes(trial)==15 || SessionData.TrialTypes(trial)==16
                stateTrial{s}={[NaN]};
            else 
                stateTrial{s}=num2cell(SessionData.RawEvents.Trial{trial}.States.ChirpPlay(:,1))';
            end
        elseif states{s}=="Reward"
            if SessionData.TrialTypes(trial)==13 || SessionData.TrialTypes(trial)==14 || SessionData.TrialTypes(trial)==15 || SessionData.TrialTypes(trial)==16
                stateTrial{s}={[NaN]};
            else 
                stateTrial{s}=num2cell(SessionData.RawEvents.Trial{trial}.States.Reward(:,1))';
            end
        else
            stateTrial{s}=num2cell(SessionData.RawEvents.Trial{trial}.States.(states{s})(:,1))'; 
        end 
        s_len=length(stateTrial{s});
        stateTrial_pos_temp{s}=repelem({states{s}},s_len);
    end 
    s_pos=[stateTrial_pos_temp{:}];
    s_time=[stateTrial{:}];

    %find events of interest
   
    for e=1:length(events)
        if events{e}=="backIn"
            if isfield(SessionData.RawEvents.Trial{trial}.Events,'Port7In')
                eventTrial{e}=num2cell(SessionData.RawEvents.Trial{trial}.Events.Port7In);
            else
                eventTrial{e}=[];
            end
        else
            if isfield(SessionData.RawEvents.Trial{trial}.Events,events{e})
                eventTrial{e}=num2cell(SessionData.RawEvents.Trial{trial}.Events.(events{e}));
            else
                eventTrial{e}=[];
            end
        end 
    e_len=length(eventTrial{e});
    eventTrial_pos_temp{e}=repelem({events{e}},e_len);
    end 
    e_pos=[eventTrial_pos_temp{:}];
    e_time=[eventTrial{:}];


    spatial_seq_temp=[s_pos e_pos];
    time_seq_temp=[s_time e_time];
    
    [time_seq_sorted_temp, time_idx]=sort(cell2num(time_seq_temp));
    time_seq{trial}=rmmissing(time_seq_sorted_temp);
    clip_end=length(rmmissing(time_seq_sorted_temp));
    
    spatial_seq_sorted_temp=spatial_seq_temp(time_idx);
    spatial_seq{trial}=spatial_seq_sorted_temp(1:clip_end);


end 