% load data tables for pre and post, and subset timescales based on
% inclusion criterion
flag = config();

pre = load(flag.pre_plot_input, 'nt');
post = load(flag.post_plot_input, 'nt');

nt_pre = pre.nt;
nt_post = post.nt;

nt_pre = add_exclusions_full(nt_pre);
nt_post = add_exclusions_full(nt_post);

% plot parameters
pre_post_color = {'#999999', "#729fcf"};
post_color = repmat({pre_post_color{2}}, 1, 5);
pre_color = repmat({pre_post_color{1}}, 1, 5);

pre_tr_ntr_color = {'#B3B3B3','#333333'};
post_tr_ntr_color = {'#729fcf','#280000'};

% set labels
region_labels = string(unique(nt_pre.area))';

%%%% example model %%%%
plot_example_neuron;

%%%% supp, example acf %%%%
plot_example_acf;

%%%% pacf %%%%
plot_pacf;

%%%% pre vs post timescales plot %%%%
component_labels = ["intrinsic"];
[t_pre_is, n_pre] = convert_nt(nt_pre, "tau_exp", component_labels);
[t_post_is, n_post] = convert_nt(nt_post, "tau_exp", component_labels);

component_labels = ["seasonal"];
[t_pre_s, n_pre] = convert_nt(nt_pre, "tau", component_labels);
[t_post_s, n_post] = convert_nt(nt_post, "tau", component_labels);

component_labels = ["intrinsic", "seasonal"];
t_pre = {t_pre_is{1}, t_pre_s{1}};
t_post = {t_post_is{1}, t_post_s{1}};

plot_timescales_comparison(t_pre, t_post, n_pre, n_post, pre_post_color, region_labels, component_labels, ["pre-training","post-training"], true);
set(gcf, 'position', [   487   222   800   538]);

%%%% proportions %%%% 
component_labels = ["intrinsic","seasonal", "cue", "sample", "match", "samplexmatch"];
[t_pre, n_pre] = convert_nt_prop(nt_pre, component_labels);
[t_post, n_post] = convert_nt_prop(nt_post, component_labels);

plot_grouped_proportion_comparison(t_pre, t_post, n_pre, n_post, pre_post_color, region_labels, component_labels, ["pre-training","post-training"]);
set(gcf, 'position', [850   258   360   430]);

plot_grouped_proportion_difference(t_pre, t_post, n_pre, n_post, pre_post_color, region_labels, component_labels, ["pre-training","post-training"]);
set(gcf, 'position', [850   258   360   430]);

%%%% r2 comparisons %%%% 
component_labels = ["intrinsic","seasonal", "cue", "sample", "match", "samplexmatch"];
[t_pre, n_pre] = convert_nt_r(nt_pre, 'r2_delta', component_labels, 'prefix');
[t_post, n_post] = convert_nt_r(nt_post, 'r2_delta', component_labels, 'prefix');

plot_grouped_r2_comparison(t_pre, t_post, pre_post_color, component_labels, ["pre-training", "post-training"]);
set(gcf, 'position', [850   258   360   430]);

%%%% task relevant vs not task relevant neurons %%%% 
plot_grouped_timescales_by_exo(nt_pre, ["cue", "sample", "match",  "samplexmatch"], pre_tr_ntr_color);
plot_grouped_timescales_by_exo(nt_post, ["cue", "sample", "match",  "samplexmatch"], post_tr_ntr_color);

%%%% task relevant vs not task relevant neurons correlation %%%% 
plot_timescale_exogenous_corr;

%%% print mean cvR2
include_something = logical(nt_post{:, "include_seasonal"}) | logical(nt_post{:, "include_intrinsic"}) | logical(nt_post{:, "include_cue"}) | logical(nt_post{:, "include_sample"}) | logical(nt_post{:, "include_match"}) | logical(nt_post{:, "include_samplexmatch"});
disp("post mean cvr2 = " + mean(nt_post{include_something, "r2_full"}))
disp("post n=" + sum(include_something))

include_something = logical(nt_pre{:, "include_seasonal"}) | logical(nt_pre{:, "include_intrinsic"}) | logical(nt_pre{:, "include_cue"}) | logical(nt_pre{:, "include_sample"}) | logical(nt_pre{:, "include_match"}) | logical(nt_pre{:, "include_samplexmatch"});
mean(nt_pre{include_something, "r2_full"})
disp("pre mean cvr2 = " + mean(nt_pre{include_something, "r2_full"}))
disp("pre n=" + sum(include_something))