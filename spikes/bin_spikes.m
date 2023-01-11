%{
Lowell Bartlett - 1/11/2023 - Abbas Lab
This function returns a vector with binned spike times for a certain 
epoch of the experiment. The user must define the start and end times that 
they wish to bin.

INPUT: 
    spikeTimes - 1xS vector where S is the number of spikes in the input
    edges - 1x2 vector [start_time, end_time], where each time is a
    reference time in seconds from member edgeRef
    edgeRef - a time-point in the original sampling frequency that you wish
    to align spikes in spikeTimes to
    res - original sampling resolution in hertz
    freq - desired output frequency in hertz

OUTPUT:
    binnedSpikes - 1xT vector where T = number of bins (time x frequency)
    Each value will be a one (spike) or a zero
%}

function binnedSpikes = bin_spikes(spikeTimes, edges, edgeRef, res, freq)
    edgeStart = edgeRef + edges(1)*res;
    edgeEnd = edgeRef + edges(2)*res;
    binEdges = edgeStart:1*res/freq:edgeEnd;  % bin steps are bin frequency
    binnedSpikes = histcounts(spikeTimes, 'BinEdges', binEdges);
end
