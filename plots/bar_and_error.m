function h = bar_and_error(data, nGroups)

% This function will plot the error bars for data on the bar graph and return the figure handle to the error bar.
%
%Example call: h = bar_and_error(data, nGroups)
%
%INPUT: 
%    data - a matrix of data where the columns are variables and the rows are observations
%    nGroups - an optional integer specifying how the data will be reshaped for group bar plots.
%    This number must be a factor of the number of columns in your data.
%    For example, if your data matrix has R rows and 20 columns, you could call the function as 
%    bar_and_error(data, 5) to split the columns into 5 groups of 4.
%OUTPUT:
%    h - a handle to the errorbar plot

meanResult = mean(data, 1);
SEM = std(data, 1)./sqrt(size(data, 1));

if nargin == 1
    bar(meanResult)
    x = 1:length(meanResult);
    hold on
    errorbar(x, meanResult, SEM, 'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1.5);

elseif nargin == 2
    nVars = size(data, 2);
    shapeVec = [nVars/nGroups, nGroups];
    meanResult = reshape(meanResult, shapeVec)';
    SEM = reshape(SEM, shapeVec)';
    
    nGroups = size(SEM, 1);
    nBars = size(SEM, 2);
    
    groupwidth = min(0.8, nBars/(nBars + 1.5));
    bar(meanResult)
    hold on
    for i = 1:nBars
        x = (1:nGroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nBars);
        errorbar(x, meanResult(:, i), SEM(:, i), 'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1.5);
    end
end