function plot_sankey_diagram(table, panel)

options.color_map = 'parula';      
options.flow_transparency = 0.2;   % opacity of the flow paths
options.bar_width = 120;            % width of the category blocks
options.show_perc = false;          % show percentage over the blocks
options.text_color = [0 0 0];      % text color for the percentages
options.show_layer_labels = true;  % show layer names under the chart
options.show_cat_labels = true;   % show categories over the blocks.
options.show_legend = false;    
if isempty(table)
    return
end
if isempty(panel)
    plotSankeyFlowChart(table, options);
else
    h = plotSankeyFlowChart(table, options);
    h.Visible = 'off';
    copyobj(h.Children, panel)
    close(h)
end

