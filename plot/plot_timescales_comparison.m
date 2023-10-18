function plot_timescales_comparison(all_g1_timescales, all_g2_timescales, all_g1_neuron_totals, all_g2_neuron_totals, colors, xlabels, ylabels, legend_label, grouped)
%INPUT
%   all_timescales - cell array w/ num timescales cells, each cell has num
%       regions cells inside of it w timescales
%   all_neuron_totals - cell array w/ num timescales cells, each cell has
%       array of length num regions inside of it w/ neuron totals
%   colors - colors for each timescale
%   xlabels - ant. post. etc.
%   ylabels - timescale names in array
%   label - description of plot
if ~exist( 'grouped', 'var')
    grouped = false;
end
all_g1_timescales_bar = all_g1_timescales;
all_g2_timescales_bar = all_g2_timescales;


if grouped
    groups = [false, false, true];
    use_group = true;
else
    use_group = false;
end

% main figure
figure;
rect    = [0.15, 0.4, 0.775, 0.4];
axis_pos = change_subplot_position(length(all_g1_timescales),1, rect);
for i=1:length(all_g1_timescales)
    if use_group
        grouped = groups(i);
    end
    disp(ylabels(i));
    axes('Position', axis_pos(i,:));
    %plot dorsal
    plot_timescale_group_line_comparison(all_g1_timescales{i}(1:3),all_g2_timescales{i}(1:3), 1, colors, legend_label(1) + " vs " + legend_label(2), xlabels(1:3), ylabels(i), grouped)
    %plot ventral
    if length(all_g1_timescales{i}) > 4
        plot_timescale_group_line_comparison(all_g1_timescales{i}(4:5),all_g2_timescales{i}(4:5), 4.7, colors, legend_label(1) + " vs " + legend_label(2), xlabels(4:5), ylabels(i), grouped)
    end
    title("\bf\it\tau_{"+ylabels(i)+"}", 'fontsize', 18);
    set(gca, 'xcolor', 'none');
    set_axis_defaults();
    set(gca, 'Xtick', [0, 1, 2, 3, 4.7, 5.7, 6.7], 'xticklabel',['',xlabels,''], 'xlim', [0,6.7]);
    if i==1
        ylabel("timescale (sec)");
    end
    ylim_range = ylim;
    %ylim([ylim_range(1), ylim_range(2)+.1*(ylim_range(2)-ylim_range(1))]);
    if i>1
        %ylim([0,20])
    else
        %ylim([0,.25]);
    end

% overall median comparison
ts_pre = [];
ts_post = [];
for ar_idx = 1:length(all_g1_timescales{i})
ts_pre = [ts_pre; all_g1_timescales{i}{ar_idx}];
ts_post = [ts_post; all_g2_timescales{i}{ar_idx}];
end
disp("overall median comparison:");
[p, h, stats] = ranksum(ts_pre, ts_post);
yline(median(ts_pre), 'color', colors{1});
yline(median(ts_post), 'color', colors{2});
disp(ylabels(i));
disp(p);
disp("z=" + stats.zval)
disp("n=" + (length(ts_pre) + length(ts_post)));
disp(median(ts_pre));
disp(median(ts_post));

end
%bar plots
rect    = [0.15, 0.27, 0.775, 0.2];
axis_pos = change_subplot_position(length(all_g1_timescales),2, rect);
for i=1:length(all_g1_timescales_bar)
    axes('Position', axis_pos(length(all_g1_timescales_bar) + i,:));
    %plot dorsal
    plot_timescale_group_bar_comparison(all_g1_timescales_bar{i}(1:3),all_g2_timescales_bar{i}(1:3),...
        all_g1_neuron_totals(1:3), all_g2_neuron_totals(1:3),1,colors, xlabels,ylabels(i));
    hold on;
    %plot ventral
    if length(all_g1_timescales{i}) > 4
    plot_timescale_group_bar_comparison(all_g1_timescales_bar{i}(4:5),all_g2_timescales_bar{i}(4:5),...
        all_g1_neuron_totals(4:5), all_g2_neuron_totals(4:5),4.7,colors, xlabels,ylabels(i));
    end
    set(gca, 'Xtick', [0, 1, 2, 3, 4.7, 5.7, 6.7], 'xticklabel',['',xlabels,''], 'xlim', [0,6.7]);
    set(gca, 'ytick', [0, .5, 1], 'yticklabel', ["0", "50", "100"]);
    xtickangle(45);
    set_axis_defaults();
    ylim([0,1]);
    if i==1
        ylabel("% of neu.");
    end
    if i==length(all_g1_timescales_bar)
        legend(legend_label, 'box', 'off', 'position', [0.77,0.72,0.12,0.070], 'fontsize', 12);
    end
    break_plot(axis_pos(i,:));
end


for i=1:length(all_g1_timescales)
% overall median comparison
ts_pre = [];
ts_post = [];
for ar_idx = 1:length(all_g1_timescales{i})
ts_pre = [ts_pre; all_g1_timescales{i}{ar_idx}];
ts_post = [ts_post; all_g2_timescales{i}{ar_idx}];
end
disp("overall variance comparison:");
[h, p, ci, stats] = vartest2(ts_pre, ts_post);
%yline(median(ts_pre), 'color', colors{1});
%yline(median(ts_post), 'color', colors{2});
disp(ylabels(i));
disp(p);
disp("F(" + stats.df1 +"," + stats.df2 + ") =" + stats.fstat)
disp("pre: " + num2str(std(ts_pre)) +  ", post: " + num2str(std(ts_post)));
% 
% figure;
% histogram(ts_pre,20,'facecolor',colors{1});
% set(gcf, 'position', [  360.0000  208.3333  311.6667  126.0000]);
% title(ylabels(i) + ", pre-training");
% set_axis_defaults();
% figure;
% histogram(ts_post,20,'facecolor',colors{2});
% set(gcf, 'position', [  360.0000  208.3333  311.6667  126.0000]);
% title(ylabels(i)+ ", post-training");
% set_axis_defaults();

end
end