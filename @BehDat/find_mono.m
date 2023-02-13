function find_mono(obj)
tic
spikes = obj.bin_spikes([0 obj.info.samples], 1);
numSpikes = size(spikes, 1);
isMonoEx = cell(numSpikes, 1);
corrsEx = cell(numSpikes, 1);
weightsEx = cell(numSpikes, 1);
isMonoIn = cell(numSpikes, 1);
corrsIn = cell(numSpikes, 1);
weightsIn = cell(numSpikes, 1);
for ref = 1:numSpikes - 1
    refSpikes = spikes(ref, :);
    for target = ref + 1:numSpikes
        targetSpikes = spikes(target, :);
        basecorr = xcorr(refSpikes, targetSpikes, 50);
        basewidevals = [basecorr(1:40), basecorr(end-39:end)];
        basemean = mean(basewidevals);
        basestd = std(basewidevals);        
        enoughSpikes = sum(basecorr) > 1000;
        lowJitter = basemean > 3*basestd;
        if ~enoughSpikes || ~lowJitter
            continue
        end
        % Excitatory conditionals
        peakLeading = any([basecorr(48:50)] > basemean + 3*basestd);
        peakInMonoNeg = any(ismember(find(basecorr == max(basecorr)), 48:50));
        peakTrailing = any([basecorr(52:54)] > basemean + 3*basestd);
        peakInMonoPos = any(ismember(find(basecorr == max(basecorr)), 52:54));
        peakWeight = (max(basecorr) - basemean)/basestd;
        % Inhibitory conditionals
        valleyLeading = any([basecorr(48:50)] < basemean - 3*basestd);
        valleyInMonoNeg = any(ismember(find(basecorr == min(basecorr)), 48:50));
        valleyTrailing = any([basecorr(52:54)] < basemean - 3*basestd);
        valleyInMonoPos = any(ismember(find(basecorr == min(basecorr)), 52:54));
        valleyWeight = (basemean - min(basecorr))/basestd;
%         skip over pairs with shared excitatory upstream input for now
        if find(basecorr == max(basecorr)) == 51
            continue
        end
        if peakLeading && peakInMonoNeg
            isMonoEx{ref}(end+1) = target;
            corrsEx{ref}(end+1, :) = basecorr;
            weightsEx{ref}(end+1) = peakWeight;
        elseif peakTrailing && peakInMonoPos
            isMonoEx{target}(end+1) = ref;
            corrsEx{target}(end+1, :) = flip(basecorr);
            weightsEx{target}(end+1) = peakWeight;
        end
        if (valleyLeading && peakTrailing) || (valleyTrailing && peakLeading)
            continue
        end

        if valleyLeading && valleyInMonoNeg
            isMonoIn{ref}(end+1) = target;
            corrsIn{ref}(end+1, :) = basecorr;
            weightsIn{ref}(end+1) = valleyWeight;
        elseif valleyTrailing && valleyInMonoPos
            isMonoIn{target}(end+1) = ref;
            corrsIn{target}(end+1, :) = flip(basecorr);
            weightsIn{target}(end+1) = valleyWeight;
        end
    end
end
[obj.spikes.exciteOutput] = isMonoEx{:};
[obj.spikes.exciteXcorr] = corrsEx{:};
[obj.spikes.exciteWeight] = weightsEx{:};
[obj.spikes.inhibitOutput] = isMonoIn{:};
[obj.spikes.inhibitXcorr] = corrsIn{:};
[obj.spikes.inhibitWeight] = weightsIn{:};
toc