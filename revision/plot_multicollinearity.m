flag = config;
load(flag.pre_model_output);
scope = all_results{1}.scope;

flag = config;
pre_or_post = "pre";
load(append(flag.plot_cache, pre_or_post, "_corrmtx",".mat"),'R','P','corr_mtx');

figure('Position', [30,40,900,1100]);
corr_mtx.R(scope.all_bias, :) = [];
corr_mtx.R(:, scope.all_bias) = [];
%corr_mtx.R(:, scope.samplexmatch) = [];
%corr_mtx.R(scope.samplexmatch, :) = [];

tmpMat = abs(corr_mtx.R(:,:));
%tmpMat(corr_mtx.P(:,:)>(0.05)) = nan;
labels = 1:length(tmpMat);
h = heatmap(labels, labels, round(tmpMat,2));
set(gca,'FontName','Helvetica','FontSize',12,'CellLabelFormat','%.2g',...
    'ColorLimits',[0 0.5],'MissingDataLabel','n.s.');
set(h.NodeChildren(3),  'FontSize',10, 'XTickLabelRotation', 45);
set(h.NodeChildren(2),  'FontSize',14);
set(h.NodeChildren(1),  'FontSize',14);
set(gcf,'color','w')
set(gcf, 'position', [   55.0000   34.3333  742.6667  604.0000])

pre_cm = tmpMat;
flag = config;
pre_or_post = "post";
load(append(flag.plot_cache, pre_or_post, "_corrmtx",".mat"),'R','P','corr_mtx');

corr_mtx.R(scope.all_bias, :) = [];
corr_mtx.R(:, scope.all_bias) = [];
%corr_mtx.R(:, scope.samplexmatch) = [];
%corr_mtx.R(scope.samplexmatch, :) = [];

figure('Position', [30,40,900,1100]);
tmpMat = abs(corr_mtx.R(:,:));
%tmpMat(corr_mtx.P(:,:)>(0.05)) = nan;
h = heatmap(labels, labels, round(tmpMat,2));
set(gca,'FontName','Helvetica','FontSize',12,'CellLabelFormat','%.2g',...
    'ColorLimits',[0 0.5],'MissingDataLabel','n.s.');
set(h.NodeChildren(3),  'FontSize',10, 'XTickLabelRotation', 45);
set(h.NodeChildren(2),  'FontSize',14);
set(h.NodeChildren(1),  'FontSize',14);
set(gcf,'color','w')
set(gcf, 'position', [   55.0000   34.3333  742.6667  604.0000])

post_cm = tmpMat;