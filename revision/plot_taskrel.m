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

%%%% task relevant vs not task relevant neurons %%%% 
timescales = ["intrinsic_tau_exp", "seasonal_tau"];%"intrinsic_tau_exp"];
components = ["intrinsic", "seasonal"]; %["intrinsic"];
ts_labels = ["\tau_{intrinsic}", "\tau_{seasonal}"];%["\tau_{intrinsic}"];

nt_pre.task = ones(height(nt_pre), 1);
nt_post.task = ones(height(nt_post),1)*2;
nt = [nt_pre; nt_post];

exo_components = ["cue", "sample"];

figure;
for i = 1:length(components)
    subplot(1,2,i);
    timescale = timescales(i);
    component = components(i);
    
    nt_sub = nt(logical(nt{:,"include_" + component}),:);
    x_start_idx = 1;
    xts = [];

    for exo_component = exo_components

        include_pre = logical(nt_sub{:, "include_" + exo_component} & nt_sub{:, "task"} == 1);
        include_post = logical(nt_sub{:, "include_" + exo_component} & nt_sub{:, "task"} == 2);
        nt_exo = nt_sub(include_pre, :);
        nt_no_exo = nt_sub(include_post, :);
        ts_exo = nt_exo{:, timescale};
        ts_no_exo = nt_no_exo{:, timescale};
        
        if component == "seasonal"
            ts_exo = ts_exo*1000;
            ts_no_exo = ts_no_exo*1000;
        end

        tss = {ts_exo, ts_no_exo};

        % plot median an iqr 
        for ii = 1:2
            if ii == 1
                color = pre_tr_ntr_color{1};
            else
                color = post_tr_ntr_color{1};
            end
            quant = quantile(tss{ii}, [.25, .5, .75]);
            iqr_val = iqr(tss{ii});
            median = quant(2);
            lower_bound = quant(1);
            upper_bound = quant(3);
            xaxis_idx = ii + x_start_idx - 1;
            
            linestyl = '-';
            if length(tss{ii}) > 25
                plot([xaxis_idx, xaxis_idx], [lower_bound, upper_bound], linestyl, 'Color', color, 'lineWidth', 2, 'markersize', .01);
            else
                scatter(repmat(xaxis_idx, length(tss{ii})), tss{ii}, 50, '.', 'MarkerFaceColor', color, 'MarkerEdgeColor', color)
            end
            hold on;      
            linestyl = '.';
            plot(xaxis_idx, median, linestyl, 'Color', color, 'lineWidth', 2, 'markersize',30);
        end

        % rank sum test and asterix
        if sum(isnan(ts_exo)) == length(ts_exo) || sum(isnan(ts_no_exo)) == length(ts_no_exo)
            p = 1;
        else
        [p, h, stats] = ranksum(ts_exo, ts_no_exo);
        disp("include " + exo_component + " vs not:" + ...
              " ranksum=" + stats.ranksum + ", p=" + p);
        end
        disp(p);
        if ~isempty(p_criterion(p))
            pre_quant = quantile(ts_exo, [.25, .5, .75]);
            pre_iqr_val = iqr(ts_exo);
            pre_upper_bound = pre_quant(3);
            post_quant = quantile(ts_no_exo, [.25, .5, .75]);
            post_iqr_val = iqr(ts_no_exo);
            post_upper_bound = post_quant(3);
            ylim_val = ylim;
            ylim_range = ylim_val(2)-ylim_val(1);
            x_text = x_start_idx+.5;
            y_text = max(pre_upper_bound, post_upper_bound) + ylim_range*.01;
            text(x_text,y_text,p_criterion(p), 'Color', 'k', 'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        end
        xts = [xts, x_start_idx + .5];
        x_start_idx = x_start_idx + 2.5;
    end
    set_axis_defaults();
    xticks(xts);
    xticklabels(exo_components);
    title(ts_labels(i));


    if i == 1
        ylabel("\tau  (ms)")
    end

    if i == 1
        ylim([0, 400]);
        legend(["pre includes component"], "", ["post includes component"])
        legend box off;
    elseif i == 2
        ylim([1500, 3200]);
    end
    
end
set(gcf, 'position', [371   394   600   375])