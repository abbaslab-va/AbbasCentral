function [closestMatch, valueChanged] = find_closest_match(inputStr, cellArray)
    % Remove non-alphanumeric characters from the input string
    inputStr = regexprep(inputStr, '[^a-zA-Z0-9]', '');

    % Initialize variables
    minDistance = Inf;
    closestMatch = '';

    % Iterate through each item in the cell array
    for i = 1:numel(cellArray)
        % Remove non-alphanumeric characters from the current cell array item
        currentItem = regexprep(cellArray{i}, '[^a-zA-Z0-9]', '');

        % Calculate Levenshtein distance between input string and current item
        distance = levenshtein_distance(inputStr, currentItem);

        % Update closest match if the current item is closer
        if distance < minDistance
            minDistance = distance;
            closestMatch = cellArray{i};
        end
    end
    if ~strcmp(closestMatch, inputStr)
        valueChanged = true;
    else
        valueChanged = false;
    end
end

function distance = levenshtein_distance(str1, str2)
    m = length(str1);
    n = length(str2);

    % Initialize matrix
    D = zeros(m + 1, n + 1);

    % Populate matrix
    for i = 1:m
        D(i + 1, 1) = i;
    end

    for j = 1:n
        D(1, j + 1) = j;
    end

    for i = 1:m
        for j = 1:n
            cost = ~(str1(i) == str2(j));
            D(i + 1, j + 1) = min([D(i, j + 1) + 1, D(i + 1, j) + 1, D(i, j) + cost]);
        end
    end

    % Levenshtein distance is the value in the bottom-right cell of the matrix
    distance = D(m + 1, n + 1);
end