function adjust_vip_trialTypes_tri(obj)

% This function is for the VIP switch experiment only: it will adjust the
% SessionPerformance field in the object's bpod structure to reflect left
% trials vs right trials. 1 corresponds to large reward on the left, 2 on
% the right. 

% Even numbered mice were recorded in the blackrock system, odd mice in the
% whitematter. At the time of recording, up to 6/5/24, the blackrock ports
% increased as you go CCW, whitematter increased clockwise. As of 6/5/24,
% all ports go CCW.

subName = obj.config.name;
subNoIdx = regexp(subName, '[0-9]');
subNo = str2double(subName(subNoIdx));
isOdd = logical(mod(subNo, 2));
centerPort1 = all(cellfun(@(x) ~isempty(x), obj.event_times('event', 'Port1In', 'withinState', 'RewardDelay')));
centerPort2 = all(cellfun(@(x) ~isempty(x), obj.event_times('event', 'Port2In', 'withinState', 'RewardDelay')));
centerPort3 = all(cellfun(@(x) ~isempty(x), obj.event_times('event', 'Port3In', 'withinState', 'RewardDelay')));

if centerPort1
    if isOdd
        leftPort = 'Port3In';
        rightPort = 'Port2In';
    else
        leftPort = 'Port2In';
        rightPort = 'Port3In';
    end
    ttAdd = 0;
elseif centerPort2
    if isOdd
        leftPort = 'Port1In';
        rightPort = 'Port3In';
    else
        leftPort = 'Port3In';
        rightPort = 'Port1In';
    end
    ttAdd = 4;
elseif centerPort3
    if isOdd
        leftPort = 'Port2In';
        rightPort = 'Port1In';
    else
        leftPort = 'Port1In';
        rightPort = 'Port2In';
    end
    ttAdd = 8;
else
    warning('No center port found -- aborting operation')
    return
end

leftPunish = obj.event_times('event', leftPort, 'withinState', 'SmallReward');
rightPunish = obj.event_times('event', rightPort, 'withinState', 'SmallReward');
for t = 1:obj.session.nTrials
    outcome = obj.session.SessionPerformance(t);
    states = obj.session.RawEvents.Trial{t}.States;
    events = obj.session.RawEvents.Trial{t}.Events;
    %If both ports are poked in a trial
    if isfield(events, leftPort) && isfield(events, rightPort)
        lastL = events.(leftPort)(end);
        lastR = events.(rightPort)(end);
        switch outcome
            case 1
                rewardTime = states.LargeReward(1);
                if rewardTime - lastL < rewardTime - lastR
                    obj.session.TrialTypes(t) = 1;
                else
                    obj.session.TrialTypes(t) = 2;
                end
            case 0
                if ~isempty(leftPunish{t}) && isempty(rightPunish{t})
                    obj.session.TrialTypes(t) = 2;
                elseif ~isempty(rightPunish{t}) && isempty(leftPunish{t})
                    obj.session.TrialTypes(t) = 1;
                else
                    if leftPunish{t}(1) < rightPunish{t}(1)
                        obj.session.TrialTypes(t) = 2;
                    else
                        obj.session.TrialTypes(t) = 1;
                    end
                end
        end
        continue
    end
    % Large reward
    switch outcome
        case 1
            if isfield(events, leftPort)
                obj.session.TrialTypes(t) = 1;
            elseif isfield(events, rightPort)
                obj.session.TrialTypes(t) = 2;
            end
        case 0
            if isfield(events, leftPort)
                obj.session.TrialTypes(t) = 2;
            elseif isfield(events, rightPort)
                obj.session.TrialTypes(t) = 1;
            end
    end
end
ttDiff = diff(obj.session.TrialTypes);
obj.session.TrialTypes(find(ttDiff == -1) + 1) = 3;
obj.session.TrialTypes(find(ttDiff == 1) + 1) = 4;
obj.session.TrialTypes = obj.session.TrialTypes + ttAdd;