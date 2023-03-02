function adjust_vip_trialTypes(obj)

% This function is for the VIP switch experiment only: it will adjust the
% SessionPerformance field in the object's bpod structure to reflect left
% trials vs right trials. 1 corresponds to large reward on the left, 2 on
% the right. 

for t = 1:obj.bpod.nTrials
    outcome = obj.bpod.SessionPerformance(t);
    states = obj.bpod.RawEvents.Trial{t}.States;
    events = obj.bpod.RawEvents.Trial{t}.Events;
    %If both ports are poked in a trial
    if isfield(events, 'Port1In') && isfield(events, 'Port5In')
        lastL = events.Port1In(end);
        lastR = events.Port5In(end);
        switch outcome
            case 0
                rewardTime = states.LargeReward(1);
                if rewardTime - lastL < rewardTime - lastR
                    obj.bpod.TrialTypes(t) = 1;
                else
                    obj.bpod.TrialTypes(t) = 2;
                end
            case 1
                punishTime = states.SmallReward(1);
                if punishTime - lastL < punishTime - lastR
                    obj.bpod.TrialTypes(t) = 2;
                else
                    obj.bpod.TrialTypes(t) = 1;
                end
        end
        continue
    end
    % Large reward
    switch outcome
        case 0
            if isfield(events, 'Port1In')
                obj.bpod.TrialTypes(t) = 1;
            elseif isfield(events, 'Port5In')
                obj.bpod.TrialTypes(t) = 2;
            end
        case 1
            if isfield(events, 'Port1In')
                obj.bpod.TrialTypes(t) = 2;
            elseif isfield(events, 'Port5In')
                obj.bpod.TrialTypes(t) = 1;
            end
    end
end
ttDiff = diff(obj.bpod.TrialTypes);
obj.bpod.TrialTypes(find(ttDiff == -1) + 1) = 3;
obj.bpod.TrialTypes(find(ttDiff == 1) + 1) = 4;