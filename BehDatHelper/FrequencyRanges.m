classdef FrequencyRanges

    properties
        edges
    end

    methods
        function f = FrequencyRanges(fRange)
            f.edges = fRange;
        end
    end

    enumeration
        delta([1 4]),
        theta([4 8]),
        alpha([8 12]),
        beta([12 30]),
        gamma([30 100]),
        all([1 120])
    end

end