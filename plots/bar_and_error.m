function [f, b, e] = bar_and_error(data, nGroups)

% This function will plot the error bars for data on the bar graph and return the handle to the bar and error bar.
%
%Example call: [f, b, e] = bar_and_error(data, nGroups)
%
%INPUT: 
%    data - a matrix of data where the columns are variables and the rows are observations
%    nGroups - an optional integer specifying how the data will be reshaped for group bar plots.
%    This number must be a factor of the number of columns in your data.
%    For example, if your data matrix has R rows and 20 columns, you could call the function as 
%    bar_and_error(data, 5) to split the columns into 5 groups of 4.
%OUTPUT:
%    f - a handle to the figure
%    b - a handle to the bar plot
%    e - a handle to the error bars, or null if data is one dimensional

meanResult = mean(data, 1);
if size(data, 1) == 1
    SEM = zeros(1, size(data, 2));
else
    SEM = std(data, 1)./sqrt(size(data, 1));
end
f = figure;
if nargin == 1
    b = bar(meanResult);
    b.FaceColor = 'flat';
    x = 1:length(meanResult);
    
    if any(SEM)    
        hold on
        e = errorbar(x, meanResult, SEM, 'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1.5);
    else
        e = [];
    end
    
elseif nargin == 2
    nVars = size(data, 2);
    shapeVec = [nVars/nGroups, nGroups];
    meanResult = reshape(meanResult, shapeVec)';
    SEM = reshape(SEM, shapeVec)';
    
    nGroups = size(SEM, 1);
    nBars = size(SEM, 2);
    
    groupwidth = min(0.8, nBars/(nBars + 1.5));
    b = bar(meanResult);
    if any(SEM)
        hold on
        for i = 1:nBars
            x = (1:nGroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nBars);
            e(i) = errorbar(x, meanResult(:, i), SEM(:, i), 'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1.5);
        end
    else
        e = [];
    end
end