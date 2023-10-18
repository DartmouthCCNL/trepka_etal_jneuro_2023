nt_pre = nt_pre(logical(nt_pre{:, "include_seasonal"}),:);
nt_post = nt_post(logical(nt_post{:, "include_seasonal"}),:);
nt_pre = add_fano_factor_qc(nt_pre, "pre");
nt_post = add_fano_factor_qc(nt_post, "post");

nt = [nt_pre; nt_post];
timescale = "seasonal_tau";
pre_is_long = (nt_pre{:, timescale} > median(nt{:, timescale}));
post_is_long = (nt_post{:, timescale} > median(nt{:, timescale}));
nt_pre_long = nt_pre(pre_is_long, :);
nt_pre_short = nt_pre(~pre_is_long,:);
nt_post_long = nt_post(post_is_long, :);
nt_post_short = nt_post(~post_is_long,:);

disp(height(nt_pre_short));
disp(height(nt_pre_long));
disp(height(nt_post_short));
disp(height(nt_post_long));

disp("pre long");
mean(nt_pre_long{:, "fano_factor"})
disp("pre short");
mean(nt_pre_short{:, "fano_factor"})
disp("post long");
mean(nt_post_long{:, "fano_factor"})
disp("post short");
mean(nt_post_short{:, "fano_factor"})
disp("pre t-test p value");
[h, p, ci, stats]= ttest2(nt_pre_short{:, "fano_factor"}, nt_pre_long{:, "fano_factor"});
disp("t(" + stats.df + ")=" + stats.tstat + ", p =" + p);
disp("post t-test p value");
[h, p, ci, stats]= ttest2(nt_post_short{:, "fano_factor"}, nt_post_long{:, "fano_factor"});
disp("t(" + stats.df + ")=" + stats.tstat + ", p =" + p);

disp("pre-training correlation between seasonal timescales and fano factor:")
[r, p] = corr(nt_pre{:, "fano_factor"}, nt_pre{:, "seasonal_tau"}, 'type', 'spearman');
disp("n = " + height(nt_pre) + "r = " + r + ", p=" + p);
disp("post-training correlation between seasonal timescales and fano factor:")
[r, p] = corr(nt_post{:, "fano_factor"}, nt_post{:, "seasonal_tau"}, 'type', 'spearman');
disp("n = " + height(nt_post) + "r = " + r + ", p=" + p);
