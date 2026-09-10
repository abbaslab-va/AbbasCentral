
function tsStruct = get_bpod_analog_timestamps(bpodData)
    timestamps = cell(1, 3);
    for i = 1:3
        dataStream = bpodData(i, :);    
        timestamps{i} = find(diff(dataStream) > 1000 & dataStream(1:end-1) < 300);
    end 
    %{
        7 combinations of wire signaling: 1, 2, 3, 1+2, 1+3, 2+3, 1+2+3
        binary: 
        [0 0 1](1)
        [0 1 0](2)
        [0 1 1](1+2)
        [1 0 0](3)
        [1 0 1](1+3)
        [1 1 0](2+3)
        [1 1 1](1+2+3)
    %}
    digitalTS = cell(1, 7);

    % work backwards to eliminate shared timestamps
    tsTolerance = 30; %how many samples apart timestamps can be
    for i = [7, 6, 5, 3]
        binaryNum = dec2bin(i, 3);
        % flip logical array to represent in little endian so it aligns
        % with ts cell array
        streamIdx = flip(arrayfun(@(x) logical(str2num(x)), binaryNum));
        numStreams = sum(streamIdx);
        currentTS = timestamps(streamIdx);
        firstTS = currentTS{1};
        % convert first cell's timestamps into a range of tolerances and
        % compare the other cells
        tsRange = num2cell([-tsTolerance tsTolerance] + firstTS', 2);
        tsDiscretized = cellfun(@(x) cellfun(@(y) discretize(x, y), tsRange, 'uni', 0), currentTS, 'uni', 0);
        sharedTS = cellfun(@(x) cellfun(@(y) ~isnan(y), x, 'uni', 0), tsDiscretized, 'uni', 0);
        withinTol = cellfun(@(x) cellfun(@(y) any(~isnan(y)), x), tsDiscretized, 'uni', 0);
        withinTol = cat(2, withinTol{:});
        sharedIdx = all(withinTol, 2);
        numTS = numel(sharedIdx);
        % loop backwards through timestamps, eliminating shared ones
        for ts = numTS:-1:1
            if sharedIdx(ts)
                digitalTS{i}(end+1) = firstTS(ts);
                for chan = 1:numStreams
                    tsIdx = sharedTS{chan}{ts};
                    timestamps{chan}(tsIdx) = [];
                end
            end
        end
    end
    % remaining single wire timestamps 
    for i = [4, 2, 1]
        binaryNum = dec2bin(i, 3);        
        streamIdx = flip(arrayfun(@(x) logical(str2num(x)), binaryNum));
        digitalTS{i} = timestamps{streamIdx};
    end
    
    codes = cell(1, 7);
    for i = 1:7
        if ~isempty(digitalTS{i})
            codes{i} = zeros(1, numel(digitalTS{i})) + i;
        end
    end
    timestamps = cat(2, digitalTS{:});
    codes = cat(2, codes{:});
    tsStruct.times = timestamps;
    tsStruct.codes = codes';

end
