function plot_timescales(all_timescales, all_neuron_totals, colors, xlabels, ylabels, label)
%INPUT
%   all_timescales - cell array w/ num timescales cells, each cell has num
%       regions cells inside of it w timescales
%   all_neuron_totals - cell array w/ num timescales cells, each cell has
%       array of length num regions inside of it w/ neuron totals
%   colors - colors for each timescale
%   xlabels - ant. post. etc.
%   ylabels - timescale names in array
%   label - description of plot

%line plots
all_timescales_bar = all_timescales;

figure;
rect    = [0.15, 0.4, 0.775, 0.4];
axis_pos = change_subplot_position(length(all_timescales),1, rect);
for i=1:length(all_timescales)
    disp(ylabels(i));
    axes('Position', axis_pos(i,:));
    %plot dorsal
    plot_timescale_group_line(all_timescales{i}(1:3), 1, colors{i}, label, xlabels(1:3));
    %plot ventral
    plot_timescale_group_line(all_timescales{i}(4:5), 4.7, colors{i}, label, xlabels(4:5));
    title("\bf\it\tau_{"+ylabels(i)+"}", 'fontsize', 18);
    set(gca, 'Xtick', [0, 1, 2, 3, 4.7, 5.7, 6.7], 'xticklabel',['',xlabels,''], 'xlim', [0,6.7]);
    set(gca, 'xcolor', 'none');
    set_axis_defaults();
    if i==1
        ylabel("timescale (sec)");
    end
end

rect    = [0.15, 0.27, 0.775, 0.2];
axis_pos = change_subplot_position(length(all_timescales),2, rect);
%bar plots
for i=1:length(all_timescales)
    %subplot(2,length(all_timescales_bar),i + length(all_timescales_bar));
    axes('Position', axis_pos(length(all_timescales) + i,:));
    %plot dorsal
    plot_timescale_group_bar(all_timescales_bar{i}(1:3), all_neuron_totals(1:3),1,colors{i});
    hold on;
    %plot ventral
    plot_timescale_group_bar(all_timescales_bar{i}(4:5), all_neuron_totals(4:5),4.7,colors{i});
    set(gca, 'Xtick', [0, 1, 2, 3, 4.7, 5.7, 6.7], 'xticklabel',['',xlabels,''], 'xlim', [0,6.7]);
    set(gca, 'ytick', [0, .5, 1], 'yticklabel', ["0", "50", "100"]);
    xtickangle(45);
    set_axis_defaults();
    ylim([0,1]);
    if i==1
        ylabel("% neu.");
    end
    break_plot(axis_pos(i,:));
end
end
