%{
This function will produce an array defining which trial and relative time
within that trial that a frame was captured in, as well as a cell array
with the equivalent information represented in a more trial-accessible
manner.

INPUT:
sessionfile - the behavior data from the Bpod
numFrames - number of frames in the video
firstTrial - the output FrameTrial from the function find_first_frame

OUTPUT:
alignedTrials - cell array (2xN), where N is the number of trials in a
session. Each cell contains a matrix (1xF), where F is the number of frames
in that trial. The first row in the cell array contains relative times
within that trial for each frame, and the second row contains absolute
frame numbers relative to the original recording. 
%}
function alignedTrials = align_frames_to_trials(sessionfile, numFrames, firstTrial)
EventCells = sessionfile.RawEvents.Trial;
alignedTrials = cell(2, numel(EventCells));
frameNo = 1;
timeLost = 0;
for trialno = firstTrial:numel(EventCells)
    if trialno ~= firstTrial
        try
            timeLost = sessionfile.TrialStartTimestamp(trialno) - sessionfile.TrialEndTimestamp(trialno-1);
        catch
            timeLost = 0;
        end
    end
    framesLost = timeLost*30;
    frameNo = frameNo + ceil(framesLost);
    trialEvents = EventCells{trialno}.Events;
    if isfield(trialEvents, 'BNC1High') && isfield(trialEvents, 'BNC1Low')
        switch numel(trialEvents.BNC1High) - numel(trialEvents.BNC1Low)
            case 1      %More high timestamps
                BNCwidth = trialEvents.BNC1Low-trialEvents.BNC1High(1:end-1);
            case 0      %Equal number
                BNCwidth = abs(trialEvents.BNC1High - trialEvents.BNC1Low);
            case -1     %More low timestamps
                BNCwidth = trialEvents.BNC1High-trialEvents.BNC1Low(1:end-1);
        end
        if any(BNCwidth > 0.0165) % 50% duty cycle width indicates start of video recording, .0166 seconds at 30 fps
            trialFrames = find(BNCwidth > .0165);
            FrameTimes = trialEvents.BNC1High(trialFrames);
            alignedTrials{1, trialno} = FrameTimes;
            alignedTrials{2, trialno} = frameNo:frameNo + numel(FrameTimes) - 1;
            frameNo = frameNo + numel(FrameTimes);
        end
    end
end