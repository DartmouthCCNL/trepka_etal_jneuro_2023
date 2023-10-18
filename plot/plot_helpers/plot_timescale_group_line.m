function [sigreg,stats] = plot_timescale_group_line(timescales, x_start_idx, color, label, xlabels, sigreg, add_ylim)
% INPUTS: 
%   timescales - cell array of regions 
%   x_start_idx - position to begin plotting from on x axis
%   color - color for this group of lines
%
%   variables for regression

y = [];
x = [];

if ~exist("grouped", 'var')
    grouped = false;
end

% plotting 
for idx = 1:length(timescales)
    quant = quantile(timescales{idx}, [.25, .5, .75]);
    iqr_val = iqr(timescales{idx});
    median(idx) = quant(2);
    lower_bound(idx) = quant(1);
    upper_bound(idx) = quant(3);
    xaxis_idx = idx + x_start_idx - 1;
    if grouped
        linestyl = '.';
    else
        linestyl = '.-';
    end
    plot([xaxis_idx, xaxis_idx], [lower_bound(idx), upper_bound(idx)], linestyl, 'Color', color, 'lineWidth', 2, 'markersize', .01);
    hold on;
    
    y = [y; timescales{idx}];
    x = [x; idx*ones(length(timescales{idx}),1)];
    disp(xlabels(idx) + " median " + label + " timescale: " + median(idx));
end

yl = ylim;
if add_ylim && yl(2)> 6
    ylim([1.5, 3]);
end
x_end_idx = x_start_idx + length(timescales)-1;

plot(x_start_idx:x_end_idx,median(1:end),'.-', 'Color',color,'lineWidth',2,'markersize',30);

%regression 
mdl = fitlm(x,y);
ci = coefCI(mdl);
%display regression stats
disp(xlabels(1) + " " + label + " regression: b=" +mdl.Coefficients.Estimate(2) + ", t("+ mdl.NumObservations +")=" + mdl.Coefficients.tStat(2) + ", p= " + mdl.Coefficients.pValue(2));
disp("<strong>" + xlabels(1) + " " + label + " regression: b=" +mdl.Coefficients.Estimate(2) + ", [" + num2str(ci(2,1)) + ", " + num2str(ci(2,2)) + "]" + "</strong>");
%get axis ranges for errorbar positioning
ylim_val = ylim;
ylim_range = ylim_val(2)-ylim_val(1);

xlim_val = xlim;
xlim_range = xlim_val(2)-xlim_val(1);

if ylim_range>1
    ylim_range = 10;
else
    ylim_range = .2;
end

if ~grouped
if (~isempty(p_criterion(mdl.Coefficients.pValue(2))))
    p = mdl.Coefficients.pValue(2);
    sigreg = true;
    plot([x_end_idx+.6,x_end_idx+.6],[median(end)-ylim_range/5, median(end)+ylim_range/5],'Color',color,'lineWidth',2,'markersize',.01);
    h = text(x_end_idx + .7,median(end)+.1*median(end),p_criterion(p), 'Color','k', 'FontSize', 14, 'FontWeight', 'bold');
    set(h, 'rotation', 270);
end
end

%pairwise comparisons
pairs = nchoosek(1:length(timescales),2);
y_val_lines = max(upper_bound);
for idx=1:size(pairs,1)
    curr_pair = pairs(idx, :);
    try
    [p,h,stats] = ranksum(timescales{curr_pair(1)}, timescales{curr_pair(2)});
    if ~isempty(p_criterion(p))
        y_val_line = y_val_lines+.07*idx*ylim_range;
        plot(curr_pair+x_start_idx-1, [y_val_line, y_val_line], 'Color',color,'lineWidth',2,'markersize',.01);
        tips(curr_pair+x_start_idx-1, y_val_line,.0025*xlim_range, .02*ylim_range, color, 2);
        text(mean(curr_pair)+x_start_idx-1,y_val_line + ylim_range*.01,p_criterion(p), 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
    disp(xlabels(curr_pair(1)) + " vs. " + xlabels(curr_pair(2)) + ":" + ...
        " ranksum=" + stats.ranksum + ", p=" + p);
    catch
        stats = nan;
    end
end
end