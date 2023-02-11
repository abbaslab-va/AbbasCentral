function find_mono(obj)
tic
spikes = obj.bin_spikes([0 obj.info.samples], 1);
numSpikes = size(spikes, 1);
isMono = cell(numSpikes, 1);
corrs = cell(numSpikes, 1);
for ref = 1:numSpikes - 1
    refSpikes = spikes(ref, :);
    for target = ref + 1:numSpikes
        targetSpikes = spikes(target, :);
        basecorr = xcorr(refSpikes, targetSpikes, 50);
        basewidevals = [basecorr(1:40), basecorr(end-39:end)];
        basemean = mean(basewidevals);
        basestd = std(basewidevals);
        peakLeading = any([basecorr(48:50)] > basemean + 3*basestd);
        peakInMonoNeg = any(ismember(find(basecorr == max(basecorr)), [48:50]));
        peakTrailing = any([basecorr(52:54)] > basemean + 3*basestd);
        peakInMonoPos = any(ismember(find(basecorr == max(basecorr)), [52:54]));
        enoughSpikes = sum(basecorr) > 1000;
        lowJitter = basemean > 3*basestd;
        if ~enoughSpikes || ~lowjitter
            continue
        end
        if peakLeading && peakInMonoNeg
            isMono{ref}(end+1) = target;
            corrs{ref}(end+1, :) = basecorr;
        elseif peakTrailing && peakInMonoPos
            isMono{target}(end+1) = ref;
            corrs{target}(end+1, :) = basecorr;
        end
    end
end
[obj.spikes.exciteOutput] = isMono{:};
[obj.spikes.exciteXcorr] = corrs{:};
toc