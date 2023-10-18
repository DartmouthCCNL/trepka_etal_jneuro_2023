function plot_grouped_proportion_difference(pre_timescales, post_timescales, pre_neuron_totals, post_neuron_totals, pre_post_color, region_labels, pre_component_labels, legend_label)
for i = 1:length(pre_timescales)
    all_pre_timescales{i} = [];
    all_post_timescales{i} = [];
    for j = 1:length(pre_timescales{i})
        all_pre_timescales{i} = [all_pre_timescales{i}; pre_timescales{i}{j}];
        all_post_timescales{i} = [all_post_timescales{i}; post_timescales{i}{j}];
    end
    timescales{i} = length(all_post_timescales{i})/sum(post_neuron_totals)-length(all_pre_timescales{i})/sum(pre_neuron_totals);
    
end
x_start_idx = 1;
    figure;
    hold on;

    % plotting 
    x = [];
    for idx = 1:length(timescales)
        percent_neurons(idx) = timescales{idx} 
        x = [x; idx+x_start_idx-1];
    end
    bar(x, percent_neurons, .3, 'facecolor', 'k', 'edgecolor', 'k');
    hold on;
xlim([0.5, length(pre_timescales) + .5]);
ylim([0,0.15]);
set_axis_defaults();
set(gca, 'xtick', 1:length(pre_timescales), 'xticklabel', pre_component_labels);
ylabel("\Delta % of neurons");
end