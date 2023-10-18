function plot_timescale_group_bar(timescales, neuron_totals, x_start_idx, color, ebar)
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
    percent_neurons(idx) = length(timescales{idx})/neuron_totals(idx);    
    x = [x; idx+x_start_idx-1];
end
bar(x, percent_neurons, .3, 'facecolor', color, 'edgecolor', color);
hold on;
if ebar
    margin_of_error = 1.96*sqrt(percent_neurons.*(1-percent_neurons)./neuron_totals);
    h = errorbar(x, percent_neurons, margin_of_error, '.','linewidth', 2, 'capsize', 4,'Color', 'k'); 
    set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
end