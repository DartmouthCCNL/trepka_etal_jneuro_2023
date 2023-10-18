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

%%%% pre vs post timescales plot %%%%
component_labels = ["intrinsic"];
[t_pre_is, n_pre] = convert_nt(nt_pre, "tau_exp", component_labels);
[t_post_is, n_post] = convert_nt(nt_post, "tau_exp", component_labels);

component_labels = ["seasonal"];
[t_pre_s, n_pre] = convert_nt(nt_pre, "tau", component_labels);
[t_post_s, n_post] = convert_nt(nt_post, "tau", component_labels);

component_labels = ["intrinsic", "seasonal"];


t_pre_is = [t_pre_is{1}{1}; t_pre_is{1}{2}; t_pre_is{1}{3}; t_pre_is{1}{4}; t_pre_is{1}{5}];
t_post_is = [t_post_is{1}{1}; t_post_is{1}{2}; t_post_is{1}{3}; t_post_is{1}{4}; t_post_is{1}{5}];

t_pre_s = [t_pre_s{1}{1}; t_pre_s{1}{2}; t_pre_s{1}{3}; t_pre_s{1}{4}; t_pre_s{1}{5}];
t_post_s = [t_post_s{1}{1}; t_post_s{1}{2}; t_post_s{1}{3}; t_post_s{1}{4}; t_post_s{1}{5}];

pre_color = pre_post_color{1};
post_color = pre_post_color{2};
figure;
subplot(2,2,1);
histogram(t_pre_is, 15, 'facecolor', pre_color);
xlabel("\tau_{intrinsic} (ms)");
ylabel("neurons");
title("pre-training")
xlim([0,500]);
ylim([0, 250]);
set_axis_defaults();

subplot(2,2,2);
histogram(t_post_is, 15, 'facecolor', post_color);
title("post-training")
xlabel("\tau_{intrinsic} (ms)");
ylabel("neurons");
xlim([0,500]);
ylim([0, 250]);
set_axis_defaults();

subplot(2,2,3);
histogram(t_pre_s, 15, 'facecolor', pre_color);
title("pre-training")
xlabel("\tau_{seasonal} (s)");
ylabel("neurons");
set_axis_defaults();
xlim([1,5]);
ylim([0,50]);

subplot(2,2,4);
histogram(t_post_s, 15, 'facecolor', post_color);
title("post-training")
xlabel("\tau_{seasonal} (s)");
ylabel("neurons");
set_axis_defaults();
xlim([1,5]);
ylim([0,50]);

set(gcf, 'position', [488   170   821   592]);
