function plot_timescale_group_bar_comparison(pre_timescales,post_timescales,pre_neuron_totals, post_neuron_totals, x_start_idx, colors, xlabels, comp_label, ebar)
% INPUTS: 
%   pre_timescales - cell array of preneuron timescales
%   post_timescales - cell array of postneuron timescales
%   x_start_idx - position to begin plotting from on x axis
%   color - color for this group of lines

if ~exist('ebar', 'var')
    ebar = false;
end

plot_timescale_group_bar(pre_timescales, pre_neuron_totals, x_start_idx-.3/2, colors{1}, ebar);
hold on;
plot_timescale_group_bar(post_timescales, post_neuron_totals, x_start_idx+.3/2, colors{2}, ebar);

% additional significance tests 
for i = 1:length(pre_timescales)
    [h, p, ~, test_string] = chi_squared_test(length(pre_timescales{i}), pre_neuron_totals(i), length(post_timescales{i}), post_neuron_totals(i));
    disp(xlabels(i) + "- "+comp_label+":" + test_string);
    if ~isempty(p_criterion(p))
        x_text = i+x_start_idx-1;
        y_text = max(length(pre_timescales{i})/pre_neuron_totals(i), length(post_timescales{i})/post_neuron_totals(i)) + .1;
        text(x_text,.95,p_criterion(p), 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
end
ylim([0,1]);