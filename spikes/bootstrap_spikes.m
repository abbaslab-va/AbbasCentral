function bsTrains = bootstrap_spikes(spikeTrain, samples, iters)

%This function will return a matrix that contains rows of bootstrapped spike trains.
%The number of rows depends on the number of iterations specified, and the length of the rows
%will be determined by the initial spike train input length and the optional samples parameter.
%
%Example call: bsTrain = bootstrap_spikes(spike_train, iters, samples)
%
%INPUT: 
%    spikeTrain - a 1xN logical array of binned spikes. Can be made using
%    the function bin_spikes
%    iters - an integer specifying the number of iterations to calculate.
%    The default value is 1000 if no input is given.
%    samples - an optional integer parameter that specifies the number of
%    sample points to subsample from the original spike train
%OUTPUT:
%    bsTrains - an IxS array of bootstrapped spike trains, where I is equal
%    to iters and S is equal to samples (or to the length of the original
%    spike_train if samples is not specified


numSpikeTrainSamples = numel(spikeTrain); 
if ~exist('samples', 'var')
    samples = numSpikeTrainSamples;
end
if ~exist('iters', 'var')
    iters = 1000;
end
bsTrains = zeros(iters, samples);
for i = 1:iters
    bsTrains(i, :) = spikeTrain(:, randsample(size(spikeTrain, 2), samples, true));
end