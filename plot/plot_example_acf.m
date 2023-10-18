% plot intrinsic timescales
figure('position', [488   107   808   655]);
subplot(2, 2, 1)
y = flip(nt_pre{1:end, "intrinsic_acf"}(logical(nt_pre{1:end, "include_intrinsic"}), :), 2);
disp("intrinsic pre: " + length(y));
lh = plot(-500:50:-50, y,  'Color', pre_post_color{1}, 'linewidth', 2); hold on;
plot(-500:50:-50, mean(y,1),  'Color', '#666666', 'linewidth', 2);
for i = 1:length(lh)
lh(i).Color = [lh(i).Color 0.1];
end
ylim([0, 1])
xlim([-500, -50]);
set_axis_defaults();
set ( gca, 'xdir', 'reverse' )
title("pre-training")
ylabel("intrinsic filter autocorr.")
xlabel("lag (ms)")

subplot(2, 2, 2)
y = flip(nt_post{1:end, "intrinsic_acf"}(logical(nt_post{1:end, "include_intrinsic"}), :), 2);
lh = plot(-500:50:-50, y, 'Color', pre_post_color{2}, 'linewidth', 2); hold on;
plot(-500:50:-50, mean(y,1),  'Color', '#666666', 'linewidth', 2);
for i = 1:length(lh)
lh(i).Color = [lh(i).Color 0.1];
end
ylim([0, 1]);
xlim([-500, -50]);
set_axis_defaults();
set ( gca, 'xdir', 'reverse' )
xlabel("lag (ms)")
title("post-training")
disp("intrinsic post: " + length(y));

% plot seasonal timescales
outs = [];
for i = 1:height(nt_pre)
if ((nt_pre{i, "include_seasonal"}))
outs = [outs; exp(-(5:1:25)/nt_pre{i, "seasonal_tau"})];
end
end

subplot(2, 2, 3)
lh = plot(-25:1:-5, flip(outs, 2),  'Color', pre_post_color{1}, 'linewidth', 2); hold on;
plot(-25:1:-5, mean(flip(outs, 2), 1),  'Color', '#666666', 'linewidth', 2);
for i = 1:length(lh)
lh(i).Color = [lh(i).Color 0.1];
end
ylim([0, 1]);
xlim([-25, -5]);
disp("seasonal pre: " + length(outs));

set_axis_defaults();
set ( gca, 'xdir', 'reverse' )
ylabel("seasonal filter autocorr.")
xlabel("lag (sec)")


outs = [];
for i = 1:height(nt_post)
if ((nt_post{i, "include_seasonal"}))
outs = [outs; exp(-(5:1:25)/nt_pre{i, "seasonal_tau"})];
end
end
disp("seasonal post: " + length(outs));

subplot(2, 2, 4)
lh = plot(-25:1:-5, flip(outs, 2), 'Color', pre_post_color{2}, 'linewidth', 2); hold on;
plot(-25:1:-5, mean(flip(outs, 2), 1),  'Color', '#666666', 'linewidth', 2);
for i = 1:length(lh)
lh(i).Color = [lh(i).Color 0.1];
end
ylim([0, 1]);
xlim([-25, -5]);
set_axis_defaults();
set ( gca, 'xdir', 'reverse' )
xlabel("lag (sec)")
