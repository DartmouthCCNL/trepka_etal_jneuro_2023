function plot_grouped_r2_comparison(pre_timescales, post_timescales, pre_post_color, pre_component_labels, legend_label)
for i = 1:length(pre_timescales)
    all_pre_timescales{i} = [];
    all_post_timescales{i} = [];
    for j = 1:length(pre_timescales{i})
        all_pre_timescales{i} = [all_pre_timescales{i}; pre_timescales{i}{j}];
        all_post_timescales{i} = [all_post_timescales{i}; post_timescales{i}{j}];
    end
end
    figure;
    hold on;
    plot_r2_group_bar_comparison(all_pre_timescales,all_post_timescales,1,pre_post_color, pre_component_labels,pre_component_labels(i) + " " + legend_label(1) + " vs " + legend_label(2), true);
    xlim([0.5, length(pre_timescales) + .5]);
    set_axis_defaults();
    set(gca, 'xtick', 1:length(pre_timescales), 'xticklabel', pre_component_labels);
    ylabel("\Delta cvR^2")
end

function plot_r2_group_bar_comparison(pre_timescales,post_timescales, x_start_idx, colors, xlabels, comp_label, ebar)
% INPUTS: 
%   pre_timescales - cell array of preneuron timescales
%   post_timescales - cell array of postneuron timescales
%   x_start_idx - position to begin plotting from on x axis
%   color - color for this group of lines

if ~exist('ebar', 'var')
    ebar = false;
end

plot_r2_group_bar(pre_timescales, x_start_idx-.3/2, colors{1}, ebar);
hold on;
plot_r2_group_bar(post_timescales, x_start_idx+.3/2, colors{2}, ebar);

% additional significance tests 
for i = 1:length(pre_timescales)
    if sum(isnan(pre_timescales{i})) == length(pre_timescales{i}) || sum(isnan(post_timescales{i})) == length(post_timescales{i})
    else
    [p, h] = ranksum((pre_timescales{i}),(post_timescales{i}));
    disp(xlabels(i) + "- "+comp_label+":" + p);
    if ~isempty(p_criterion(p))
        x_text = i+x_start_idx-1;
        yl = ylim;
        y_text = quantile(pre_timescales{i}, .75) + .1*yl(2);
        text(x_text,y_text,p_criterion(p), 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
    end
end
end


function plot_r2_group_bar(timescales, x_start_idx, color, ebar)
% INPUTS: 
%   timescales - cell array of regions 
%   neuron_totals - number of neurons recorded from in each region
%   x_start_idx - position to begin plotting from on x axis
%   color - color for this group of lines

if ~exist('ebar', 'var')
    ebar = false;
end

% plotting 
x = [];
for idx = 1:length(timescales)
    medianr2(idx) = median(timescales{idx});  
    errbarup(idx) = quantile(timescales{idx}, .75) - median(timescales{idx});
    errbardown(idx) = median(timescales{idx}) - quantile(timescales{idx}, .25);
    x = [x; idx+x_start_idx-1];
end
bar(x, medianr2, .3, 'facecolor', color, 'edgecolor', color);
hold on;
if ebar
    h = errorbar(x, medianr2, errbardown, errbarup, '.','linewidth', 2, 'capsize', 4,'Color', 'k'); 
    set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
end