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

% plot parameters
pre_post_color = {'#999999', "#729fcf"};
post_color = repmat({pre_post_color{2}}, 1, 5);
pre_color = repmat({pre_post_color{1}}, 1, 5);

pre_tr_ntr_color = {'#B3B3B3','#333333'};
post_tr_ntr_color = {'#729fcf','#280000'};

% set labels
region_labels = string(unique(nt_pre.area))';

%%%% proportions %%%% 
component_labels = ["cue", "sample", "match", "samplexmatch"];

areas = unique(nt_pre.area);
areas = ["posterior dorsal", "posterior ventral", "anterior dorsal", "anterior ventral"]
region_labels = ["posterior", "anterior"]
for i = 1:2
    nt_pre_use = nt_pre(nt_pre.area == areas(2*(i-1) + 1) | nt_pre.area == areas(2*(i-1) + 2), :);
    nt_post_use = nt_post(nt_post.area == areas(2*(i-1) + 1) | nt_post.area == areas(2*(i-1) + 2), :);
    [t_pre, n_pre] = convert_nt_prop(nt_pre_use, component_labels);
    [t_post, n_post] = convert_nt_prop(nt_post_use, component_labels);
    plot_grouped_proportion_comparison(t_pre, t_post, n_pre, n_post, pre_post_color, region_labels, component_labels, ["pre-training","post-training"]);
    set(gcf, 'position', [   619   275   274   264]);
    title(region_labels(i));
    ylim([0, 0.1])
    ylabel("prop. of neurons");
end