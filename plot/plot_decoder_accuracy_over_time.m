flag = config();
rng(1);
load(flag.decoder_output + "corr_accuracy_over_time_new_shuf.mat"); 
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
    
    fill([1, 1, 1.5, 1.5], [1,0, 0, 1], [.9, .9, .9], 'FaceAlpha', .5, 'EdgeAlpha', 0); hold on;
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
                    d = acc.(component).(pre_or_post).(sl).acc;
                    ticklabs = [ticklabs, pre_or_post];
                    
                else
                    d = acc.(component).(pre_or_post).(sl).cue_shuff_acc;
                    ticklabs = [ticklabs, pre_or_post + " shuf."];
                end

                err = sem(d, 2, acc.(component).(pre_or_post).(sl).n/50);
                me = mean(d, 2);
        
                x = .25:.05:2.75;
                ax = shaded_error(.25:.05:2.75, me, err, color);
                legs = [legs, ax];
                hold on;

                if jj == 1

            disp(component + " " + pre_or_post + " " + sl + " stim period: " + round(me(x == 1.25), 2) + "+-" + + round(err(x == 1.25, :),2));
                end
            end



            % testing hypothesis that post long (short) and pre long (short
            % ) are different
            if pre_or_post == "pre"
            x1 = acc.(component).post.(sl).acc - acc.(component).pre.(sl).acc;
            y1 =  acc.(component).post.(sl).task_shuff_acc - acc.(component).pre.(sl).task_shuff_acc;
            nsamp = min(acc.(component).post.(sl).n/50, acc.(component).pre.(sl).n/50);

            nboot = 1000;
            stim_tp = 21;
            delay_tp = [31, 41, 51];
            p1 = bootstrap(x1(stim_tp,:), y1(stim_tp,:), nboot, nsamp);
            p2 = bootstrap(reshape(x1(delay_tp,:), [], 1), reshape(y1(delay_tp,:), [], 1), nboot, nsamp);
            %disp(component + " pre vs post " + sl + " stim period: " + p1);
            %disp(component + " pre vs post " + sl + " delay period: " + p2);
            end
            

            % testing hypothesis that post (pre) long and post (pre) short
            % are different
            if sl == "long"
            x1 = acc.(component).(pre_or_post).long.acc - acc.(component).(pre_or_post).short.acc;
            y1 =  acc.(component).(pre_or_post).long.length_shuff_acc - acc.(component).(pre_or_post).short.length_shuff_acc;
            nsamp = min(acc.(component).(pre_or_post).long.n/50, acc.(component).(pre_or_post).short.n/50);

            if component == "seasonal"
                x1 = -x1;
                y1 = -y1;
            end

            p1 = bootstrap(x1(stim_tp,:), y1(stim_tp,:), nboot, nsamp);
            p2 = bootstrap(reshape(x1(delay_tp,:), [], 1), reshape(y1(delay_tp,:), [], 1), nboot, nsamp);
            %disp(component + " " + pre_or_post + " long vs short stim period: " + p1);
            %disp(component + " " + pre_or_post + " long vs short delay period: " + p1);
            end
% 
%             x1 = acc.(component).(pre_or_post).(sl).acc;
%             y1 = acc.(component).(pre_or_post).(sl).cue_shuff_acc;
% 
%             [clusters, p_values, t_sums, permutation_distribution] = permutest(x1, y1, true, .05, 1000, false);
%             sig_clusts = clusters(p_values <= .05);
%             sig_idxes = [];
%             for iii = 1:length(sig_clusts)
%                 sig_clust = sig_clusts{iii};
%                 if pre_or_post == "pre"
%                     color =[153,153,153]./255;
%                     idxes = 1;
%                 else
%                     color = [114,159,207]./255;
%                     idxes = 2;
%                 end
%                 sig_idxes = [sig_idxes, sig_clust];
%                 f = fill([x(sig_clust), flip(x(sig_clust))], [(0.4 + (idxes/100)) * ones(length(sig_clust)), (0.41 + (idxes/100))*ones(length(sig_clust))], color, 'EdgeColor', [1, 1, 1]);
%             end
% 
%             x1 = acc.(component).post.(sl).acc - acc.(component).pre.(sl).acc;
%             y1 =  acc.(component).post.(sl).task_shuff_acc - acc.(component).pre.(sl).task_shuff_acc;
% 
%             [clusters, p_values, t_sums, permutation_distribution] = permutest(x1, y1, false, .05, 1000, true);
% 
%             sig_clusts = clusters(p_values <= .05);
%             for iii = 1:length(sig_clusts)
%                 sig_clust = sig_clusts{iii};
%                 sig_clust = sig_clust(ismember(sig_clust, sig_idxes));
%                 if length(sig_clust) > 0
%                     f = fill([x(sig_clust), flip(x(sig_clust))], [0.43 * ones(length(sig_clust)), 0.44*ones(length(sig_clust))], 'k', 'EdgeColor', [1, 1, 1]);
%                 end
%             end
    end
    set_axis_defaults();
    xlabel("time (sec)");
    ylabel("test accuracy");
    legend(legs, ticklabs,  'AutoUpdate','off', 'fontsize', 10, 'box', 'off');
    title(sl + " " + ts_labels(i));
    legend off;
    xtickangle(0);
    ylim([0, 0.45]);
    end
    
    set(gcf, 'position', [705   286   664   403])
end


function sem = sem(x, dim,n)
sem = std(x, [], 2)/sqrt(n); %n); %size(x, 2);
end

function ax = shaded_error(x, y, sem, color)
ax = plot(x, y, 'linewidth', 1.5, 'color', color); hold on;
if color == "#999999"
    color = [153, 153, 153]./256;
elseif color == "#729fcf"
    color = [114,159,207]./256;
elseif color == "#646464"
    color = [100, 100, 100]./256;
end
fill([x, flip(x)], [y+sem; flip(y-sem)]', color, 'EdgeColor', color, 'FaceAlpha', .5, 'EdgeAlpha', .5);
end

function p = bootstrap(real_dist, null_dist, nboot, nsamp)
real_mean = mean(real_dist);
null_means = [];
for i = 1:nboot
    null_means(i) = mean(datasample(null_dist, round(nsamp)));
end
p = sum(real_mean  < null_means)/nboot;
end