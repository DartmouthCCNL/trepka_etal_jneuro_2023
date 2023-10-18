% load data tables for pre and post, and subset timescales based on
% inclusion criterion
flag = config();

pre = load(flag.pre_plot_input, 'nt');
post = load(flag.post_plot_input, 'nt');

nt_pre = pre.nt;
nt_post = post.nt;

nt_pre = add_exclusions_full(nt_pre);
nt_post = add_exclusions_full(nt_post);

nt_pre = nt_pre(nt_pre{:, "include_intrinsic"} | nt_pre{:, "include_seasonal"}, :);
nt_post = nt_post(nt_post{:, "include_intrinsic"} | nt_post{:, "include_seasonal"}, :);
%nt_pre = nt_pre(~nt_pre{:, "include_intrinsic"} & ~nt_pre{:, "include_seasonal"}, :);
%nt_post = nt_post(~nt_post{:, "include_intrinsic"} & ~nt_post{:, "include_seasonal"}, :);


% plot parameters
pre_post_color = {'#999999', "#729fcf"};
post_color = repmat({pre_post_color{2}}, 1, 5);
pre_color = repmat({pre_post_color{1}}, 1, 5);

pre_tr_ntr_color = {'#B3B3B3','#333333'};
post_tr_ntr_color = {'#729fcf','#280000'};

% set labels
region_labels = string(unique(nt_pre.area))';


%%%% r2 comparisons %%%% 
component_labels = ["cue", "sample", "match", "samplexmatch"];
[t_pre, n_pre] = convert_nt_rall(nt_pre, 'r2', component_labels, 'prefix');
[t_post, n_post] = convert_nt_rall(nt_post, 'r2', component_labels, 'prefix');

plot_grouped_r2_comparison_byregion(t_pre, t_post, pre_post_color, component_labels, ["pre-training", "post-training"], region_labels);
set(gcf, 'position',    [619   275   274   264])


function plot_grouped_r2_comparison_byregion(pre_timescales, post_timescales, pre_post_color, pre_component_labels, legend_label, region_labels)
for i = 1:length(pre_timescales)
    regions =  ["anterior", "posterior"]
    for k = 1:length(regions)
    all_pre_timescales{i, k} = [];
    all_post_timescales{i, k} = [];
    for j = 1:length(pre_timescales{i})
        if contains(region_labels(j), regions(k))
            all_pre_timescales{i, k} = [all_pre_timescales{i, k}; pre_timescales{i}{j}];
            all_post_timescales{i, k} = [all_post_timescales{i, k}; post_timescales{i}{j}];
        end
    end
    end
end
%all_pre_timescales = reshape(all_pre_timescales, 4, 1);
%all_post_timescales = reshape(all_post_timescales, 4, 1);
all_pret = all_pre_timescales;
all_post = all_post_timescales;
for ii = 1:2
    all_pre_timescales = all_pret(:, ii);
    all_post_timescales = all_post(:, ii);
    %pre_component_labels = [regions(1) + " " + pre_component_labels(1), regions(1) + " " + pre_component_labels(2), regions(2) + " " + pre_component_labels(1), regions(2) + " " + pre_component_labels(2)];
    figure('position',   [619   275   274   264]);
    plot_r2_group_bar_comparison(all_pre_timescales,all_post_timescales,1,pre_post_color, pre_component_labels,pre_component_labels(i) + " " + legend_label(1) + " vs " + legend_label(2), true);
    xlim([0.5, length(all_pre_timescales) + .5]);
    set_axis_defaults();
    set(gca, 'xtick', 1:length(all_pre_timescales), 'xticklabel', pre_component_labels);
    ylabel("cvR^2");
    title(regions(ii));
    set(gcf, 'position', [619   275   274   264]);
end
set(gcf, 'position', [619   275   274   264])
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
    [p, h, stats] = ranksum((pre_timescales{i}),(post_timescales{i}));
    if isfield(stats, 'zval')
    disp(xlabels(i) + "- "+comp_label+":n=" + (length(pre_timescales{i})+length(post_timescales{i})) + ", p=" + p + ", z=" + stats.zval);
    end
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

    disp(size(repmat(idx+x_start_idx-1, length(timescales{idx}), 1)));
    if length(timescales{idx}) < 5 && length(timescales{idx}) > 0 
        text(idx+x_start_idx-1, .003 + max(timescales{idx}), "" + length(timescales{idx}))
        scatter(repmat(idx+x_start_idx-1, length(timescales{idx})), timescales{idx}, 'filled', 'MarkerEdgeColor', color, 'MarkerFaceColor', color)
        medianr2(idx) = 0;
        errbarup(idx) = 0;
        errbardown(idx) = 0;
    end
    x = [x; idx+x_start_idx-1];
    bar(x(idx), medianr2(idx), .3, 'facecolor', color, 'edgecolor', color); hold on;
    text(idx+x_start_idx-1, 0.011, "" + length(timescales{idx}));
end
ylim([0, 0.013])
%bar(x, medianr2, .3, 'facecolor', color, 'edgecolor', color);
hold on;
if ebar
    h = errorbar(x, medianr2, errbardown, errbarup, '.','linewidth', 2, 'capsize', 4,'Color', 'k'); 
    set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
end
end