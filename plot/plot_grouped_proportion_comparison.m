function plot_grouped_proportion_comparison(pre_timescales, post_timescales, pre_neuron_totals, post_neuron_totals, pre_post_color, region_labels, pre_component_labels, legend_label)
for i = 1:length(pre_timescales)
    all_pre_timescales{i} = [];
    all_post_timescales{i} = [];
    for j = 1:length(pre_timescales{i})
        all_pre_timescales{i} = [all_pre_timescales{i}; pre_timescales{i}{j}];
        all_post_timescales{i} = [all_post_timescales{i}; post_timescales{i}{j}];
    end
    all_pre_neuron_totals(i) = sum(pre_neuron_totals);
    all_post_neuron_totals(i)  = sum(post_neuron_totals);
end
    figure;
    hold on;
    plot_timescale_group_bar_comparison(all_pre_timescales,all_post_timescales,...
        all_pre_neuron_totals, all_post_neuron_totals,1,pre_post_color, pre_component_labels,pre_component_labels(i) + " " + legend_label(1) + " vs " + legend_label(2), true);
xlim([0.5, length(pre_timescales) + .5]);
ylim([0,1]);
set_axis_defaults();
set(gca, 'xtick', 1:length(pre_timescales), 'xticklabel', pre_component_labels);
ylabel("% of neurons");
end