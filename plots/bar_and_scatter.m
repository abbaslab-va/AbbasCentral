function bar_and_scatter(data)

if ~iscell(data)
    dataSize = size(data);
    dataDim = find(dataSize == max(dataSize));
    data = num2cell(data, dataDim);
    % dataMeans = mean(data);
    % dataSEM = std(data)/sqrt(numel(data));
end
dataMeans = cellfun(@(x) mean(x, 'omitnan'), data);
dataSEM = cellfun(@(x) std(x, 0, 'omitnan')/sqrt(numel(x(~isnan(x)))), data);
figure
hold on
bar(dataMeans, 'FaceColor', 'k', 'FaceAlpha', .5, 'EdgeColor', 'k', 'EdgeAlpha', 1)
for s = 1:numel(dataMeans)
    jitterVec = (zeros(1, numel(data{s})) + rand(1, numel(data{s})) - .5).*.5;
    scatter(zeros(1, numel(data{s})) + s + jitterVec, data{s}, 20, 'filled', 'r')
end
errorbar(dataMeans, dataSEM, 'vertical', 'Color','k', 'LineWidth', 1.5, 'LineStyle', 'none');
set(gca, 'Color', 'w')