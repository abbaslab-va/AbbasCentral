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

ts = double(nev.Data.SerialDigitalIO.TimeStamp);
codes = double(nev.Data.SerialDigitalIO.UnparsedData);
% Find 'off' timestamps
tsOff = codes == 65528;
offLocs = find(tsOff);
offSep = diff(offLocs);
% Should only be separated by one number
badSep = find(offSep ~= 2);
if badSep(end) == numel(offLocs)
    codes(offLocs(end):end) = [];
    badSep(end) = [];
end
edges = [offLocs(badSep), offLocs(badSep+1)];
edges = num2cell(edges, 2);
% Find the values between the offs with more than one that are not max and
% remove those indices
checkIdx = cellfun(@(x) x(1)+1:x(2)-1, edges, 'uni', 0);
checkCodes = cellfun(@(x) codes(x) ~= max(codes(x)), checkIdx, 'uni', 0);
badTS = cellfun(@(x, y) x(y), checkIdx, checkCodes, 'uni', 0);
badTS = cat(2, badTS{:});
ts(badTS) = [];
codes(badTS) = [];
% Compare number of trial starts to the number of bpod trial starts
checkLength = find(codes == 65529);
try
    if length(checkLength) - numTrials == 1
       ts = ts(1:checkLength(end) - 2);
       codes = codes(1:checkLength(end) - 2);

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
tsStruct.times = ts;
tsStruct.codes = codes';
