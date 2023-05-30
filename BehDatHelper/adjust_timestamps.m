function tsStruct = adjust_timestamps(nev, numTrials)

%Returns adjusted timestamps from the Bpod V0.7 state machine interfacing
%with the Cereplex Direct. Wire signals sent from Bpod are routed through a
%DB37 breakout board that plugs into the digital IO port on the Cereplex.
%This function filters out erroneously generated timestamps, under the
%assumption that there are no two consecutive states with different wire
%signals in the Bpod script. Furthermore, the 'Wire1' timestamp should be
%used to mark the start of a new trial.

if isempty(nev.Data.SerialDigitalIO.TimeStamp)
    tsStruct.times = [];
    tsStruct.codes = [];
    return
end
adjustedTimestamps(1,:) = double(nev.Data.SerialDigitalIO.TimeStamp);
adjustedTimestamps(2,:) = double(nev.Data.SerialDigitalIO.UnparsedData');


diffs = diff(adjustedTimestamps(1, :)); 
takeOut1 = find(diffs ~= 1);

adjustedTimestamps = adjustedTimestamps(:, takeOut1);
adjustedTimestamps(1,:) = double((adjustedTimestamps(1, :)));

Check_length = find(adjustedTimestamps(2, :) == 65529);
try
    if length(Check_length) - numTrials == 1
       adjustedTimestamps=adjustedTimestamps(:, 1:Check_length(end) - 2);
    
%     elseif length(Check_length) - numTrials ~= 0
%          ME = MException('BehDat:BadTS', ...
%         'Trial start timestamps have a length mismatch with the Bpod Session file');
%         throw(ME);
    end 
    

catch
    tsStruct.times = [];
    tsStruct.codes = [];
    return
end
tsStruct.times = adjustedTimestamps(1, :);
tsStruct.codes = adjustedTimestamps(2, :);
