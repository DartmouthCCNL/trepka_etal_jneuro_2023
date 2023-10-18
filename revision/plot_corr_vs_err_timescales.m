% load data tables for post_corr and post, and subset timescales based on
% inclusion criterion
flag = config();

post_corr = load(flag.post_corr_plot_input, 'nt');
post_err = load(flag.post_err_plot_input, 'nt');

nt_post_corr = post_corr.nt;
nt_post_err = post_err.nt;

nt_post_corr = add_exclusions_full(nt_post_corr);
nt_post_err = add_exclusions_full(nt_post_err);
only_paired = false;

if only_paired
 include_intrinsic = nt_post_corr{:, "include_intrinsic"} & nt_post_err{:, "include_intrinsic"};
 include_seasonal = nt_post_corr{:, "include_seasonal"} & nt_post_err{:, "include_seasonal"};
 nt_post_corr{:, "include_intrinsic"} = include_intrinsic;
 nt_post_err{:, "include_intrinsic"} = include_intrinsic;
 nt_post_corr{:, "include_seasonal"} = include_seasonal;
 nt_post_err{:, "include_seasonal"} = include_seasonal;
end

% plot parameters
post_corr_post_err_color = {'#aac5e2', "#506f91"};
post_err_color = repmat({post_corr_post_err_color{2}}, 1, 5);
post_corr_color = repmat({post_corr_post_err_color{1}}, 1, 5);

post_corr_tr_ntr_color = {'#B3B3B3','#333333'};
post_err_tr_ntr_color = {'#729fcf','#280000'};

% set labels
region_labels = string(unique(nt_post_corr.area))';

%%%% example model %%%%
% plot_example_neuron;

%%%% supp, example acf %%%%
% plot_example_acf;

%%%% pacf %%%%
% plot_pacf;

%%%% post_corr vs post_err timescales plot %%%%
component_labels = ["intrinsic"];
[t_post_corr_is, n_post_corr] = convert_nt(nt_post_corr, "tau_exp", component_labels);
[t_post_err_is, n_post_err] = convert_nt(nt_post_err, "tau_exp", component_labels);

component_labels = ["seasonal"];
[t_post_corr_s, n_post_corr] = convert_nt(nt_post_corr, "tau", component_labels);
[t_post_err_s, n_post_err] = convert_nt(nt_post_err, "tau", component_labels);

component_labels = ["intrinsic", "seasonal"];
t_post_corr = {t_post_corr_is{1}, t_post_corr_s{1}};
t_post_err = {t_post_err_is{1}, t_post_err_s{1}};

% timescales divided by subregion
plot_timescales_comparison(t_post_corr, t_post_err, n_post_corr, n_post_err, post_corr_post_err_color, region_labels, component_labels, ["post_corr-training","post_err-training"], true);

set(gcf, 'position', [   915   109   582   600])
% combined table
nt_post_corr.correct = repmat(["correct"], height(nt_post_corr), 1);
nt_post_err.correct = repmat(["error"], height(nt_post_corr), 1);
nt_comb = [nt_post_corr; nt_post_err];
nt_comb.include_correct = nt_comb.correct == "correct";
nt_comb.include_error = nt_comb.correct == "error";

plot_grouped_timescales_by_exo(nt_comb, ["correct"], post_corr_post_err_color);
xlim([0.5,2.5]);
xticks([1,2])
xticklabels(["correct", "error"])
legend off
set(gcf, 'position', [   519   370   399   246])