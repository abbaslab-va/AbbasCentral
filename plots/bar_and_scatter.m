function figH = bar_and_scatter(data, varargin)

if ~iscell(data)
    dataSize = size(data);
    dataDim = find(dataSize == max(dataSize));
    data = num2cell(data, dataDim);
    % dataMeans = mean(data);
    % dataSEM = std(data)/sqrt(numel(data));
end
p = inputParser;
addParameter(p, 'color', 'k')
addParameter(p, 'alpha', .6)
parse(p, varargin{:});
a = p.Results;
dataMeans = cellfun(@(x) mean(x, 'omitnan'), data);
dataSEM = cellfun(@(x) std(x, 0, 'omitnan')/sqrt(numel(x(~isnan(x)))), data);
figH = figure;
hold on
if ~iscell(a.color)
    bar(dataMeans, 'FaceColor', a.color, 'FaceAlpha', a.alpha, 'EdgeColor', a.color, 'EdgeAlpha', a.alpha)
else
    for c = 1:numel(a.color)
        bar(c, dataMeans(c), 'FaceColor', a.color{c}, 'FaceAlpha', a.alpha, 'EdgeColor', a.color{c}, 'EdgeAlpha', a.alpha)
    end
end
for s = 1:numel(dataMeans)
    jitterVec = (zeros(1, numel(data{s})) + rand(1, numel(data{s})) - .5).*.5;
    scatter(zeros(1, numel(data{s})) + s + jitterVec, data{s}, 20, 'filled', 'k')
end
errorbar(dataMeans, dataSEM, 'vertical', 'Color','k', 'LineWidth', 3, 'LineStyle', 'none');
set(gca, 'Color', 'w')