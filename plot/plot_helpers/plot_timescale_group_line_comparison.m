function plot_timescale_group_line_comparison(pre_timescales,post_timescales, x_start_idx, colors, label, xlabels, comp_label, grouped)
% INPUTS: 
%   timescales - cell array of regions 
%   x_start_idx - position to begin plotting from on x axis
%   color - color for this group of lines

if ~exist( 'grouped', 'var')
    grouped = false;
end

[sigreg, text_handle] = plot_timescale_group_line(pre_timescales, x_start_idx, colors{1}, "pre-training", xlabels, true, grouped);
[sigreg, text_handle] = plot_timescale_group_line(post_timescales, x_start_idx+.3, colors{2}, "post-training", xlabels, true, grouped);


% additional significance tests 
for i = 1:length(pre_timescales)
    try
    [p, h, stats] = ranksum(pre_timescales{i}, post_timescales{i});
    disp(xlabels(i) + "- "+comp_label+":" + ...
          " ranksum=" + stats.ranksum + ", p=" + p);
    if ~isempty(p_criterion(p))
        pre_quant = quantile(pre_timescales{i}, [.25, .5, .75]);
        pre_iqr_val = iqr(pre_timescales{i});
        pre_upper_bound = pre_quant(3);
        post_quant = quantile(post_timescales{i}, [.25, .5, .75]);
        post_iqr_val = iqr(post_timescales{i});
        post_upper_bound = post_quant(3);
        ylim_val = ylim;
        ylim_range = ylim_val(2)-ylim_val(1);
        x_text = i+x_start_idx-1;
        y_text = max(pre_upper_bound, post_upper_bound) + ylim_range*.01;
        text(x_text,y_text,p_criterion(p), 'Color', "#808080", 'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
    catch
        stats = nan;
    end
end