flag = config();
rng(3);
load(flag.decoder_output + "corr_accuracy_over_neurons_new.mat");
colors = string(["#999999", "#646464", "#729fcf", "#646464"]);
components = ["intrinsic", "seasonal"];
ts_labels = ["\tau_{intrinsic}", "\tau_{seasonal}"];

acc.intrinsic.pre.short.n = 416;
acc.intrinsic.pre.long.n = 363;
acc.seasonal.pre.short.n = 98;
acc.seasonal.pre.long.n = 92;
acc.intrinsic.post.short.n = 328;
acc.intrinsic.post.long.n = 393;
acc.seasonal.post.short.n = 116;
acc.seasonal.post.long.n = 102;

for i  = 1:length(components)
    figure;
    for ii = 1:2
    col_cnt = 1;

    subplot(1,2,ii);
    ts_label = ts_labels(i);
    component = components(i);

    x_start_idx = 1;
    xts = [];
    
    ticklabs = [];
    legs = [];
    for pre_or_post = ["pre", "post"]
        % plot mean  + sem
        d_short = acc.(component).(pre_or_post).short;
        d_long = acc.(component).(pre_or_post).long;
        color = 'k';
        sls = ["short", "long"];

            sl = sls(ii);
            for jj = 1:2
                color = colors(col_cnt);
                col_cnt = col_cnt + 1;
                if jj == 1
                    d = acc.(component).(pre_or_post).(sl).acc(1:14, :);
                else
                    d = acc.(component).(pre_or_post).(sl).cue_shuff_acc(1:14, :);
                end

                x = [1:5, 10:10:90];

                err = nansem(d, 2, acc.(component).(pre_or_post).(sl).n, x);
                me = nanmean(d, 2);
        
                y = me;
                
                for iii = 1:length(x)
                    plot([x(iii), x(iii)], [y(iii)-err(iii), y(iii)+err(iii)], '-', 'Color', color, 'lineWidth', 2, 'markersize', .01);
                end                
                g = fittype('a-b*exp(-c*x)');
                f = fit(x',y, g, 'Lower', [0, -1, 0], 'Upper', [1, 1, 1], 'StartPoint', [.5, 0, .5]);
                
                plat = coeffvalues(f);
                plat = plat(1);
                ci = confint(f);
                ci = ci(:, 1);
                
                sf = f;
                f1 = subs(str2sym(formula(sf)),coeffnames(sf),num2cell(coeffvalues(sf).'));
                g = finverse(f1);
                ht = matlabFunction(g);
                if jj == 1
                    dims = round(ht(.95*plat));
                    disp(component + " dimensionality " + pre_or_post + " " + sl + ": " + dims);
                end

                if string(component) == "seasonal" && string(sl) == "long"
                    dims = "undef."
                end

                fp = plot(f, x', y);
                fp(1).Color = color;
                fp(1).MarkerSize = 8;
                fp(2).LineWidth = 1.5;

                fp(2).Color = color;
                drawnow;
                legs = [legs, fp(2)];
                hold on;
                ylim([0, 0.4]);

                if jj == 1
                    d = acc.(component).(pre_or_post).(sl).acc(1:14, :);
                    ticklabs = [ticklabs, pre_or_post + " dim = " + dims];
                else
                    d = acc.(component).(pre_or_post).(sl).cue_shuff_acc(1:14, :);
                    ticklabs = [ticklabs, pre_or_post + " shuf."];
                end
            end

            % bootstrapping for calculating error on estimate, 200
            % bootstrap iters, didn't include in paper because unclear how
            % should be defined
%             for iii = 1:200
%                 jj = 1;
%                 ds = acc.(component).(pre_or_post).(sl).acc(1:14, :);
% 
%                 x = [1:5, 10:10:90];
%                 y = ds(size(ds,2), acc.(component).(pre_or_post).(sl).n/45);
% 
%                 g = fittype('a-b*exp(-c*x)');
%                 f = fit(x',y, g, 'Lower', [0, 0, 0], 'Upper', [1, 1, 1], 'StartPoint', [.5, 0, .5]);
% 
%                 plat = coeffvalues(f);
%                 plat = plat(1);
%                 ci = confint(f);
%                 ci = ci(:, 1);
% 
%                 sf = f;
%                 f1 = subs(str2sym(formula(sf)),coeffnames(sf),num2cell(coeffvalues(sf).'));
%                 g = finverse(f1);
%                 ht = matlabFunction(g);
%                 dims_err(iii) = round(ht(.95*plat));
% 
%                 if (dims_err(iii)) > 1000
%                     pahe = 0;
%                 end
%             end
%             disp(std(dims_err));
    end
    set_axis_defaults();
    legend(legs, ticklabs,  'AutoUpdate','off', 'fontsize', 10);
    legend box off;
    yline(1/9, 'k--', 'linewidth', 1);
    title(sl + " " + ts_labels(i));

    xlabel("number of neurons");
    ylabel("test accuracy");

    xtickangle(0);
    if i == 1
        %ylabel("\tau  (ms)")
    end
ylim([0, 0.45]);
xlim([0, 90]);
    if i == 1
        %legend box off;
    elseif i == 2
        %ylim([1500, 3200]);
    end
end
set(gcf, 'position', [   705   286   664   403]);
        end

function sem = nansem(x, dim, n, sp_sizes)
sem = nanstd(x, [], 2)./sqrt(n./sp_sizes);
end