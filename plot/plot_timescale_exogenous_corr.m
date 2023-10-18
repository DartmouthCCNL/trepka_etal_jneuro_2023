for components = 1:2
exos = ["cue", "sample"]; % , "match", "samplexmatch"
exo_labels = exos;
if components == 2
    timescales = ["seasonal"]; %["intrinsic"];
    fields = ["seasonal_tau"]; %["intrinsic_tau_exp"];
    labels = ["\tau_{seasonal}"];% ["\tau_{intrinsic}"];
else
    timescales = ["intrinsic"]; %["intrinsic"];
    fields = ["intrinsic_tau_exp"]; %["intrinsic_tau_exp"];
    labels = ["\tau_{intrinsic}"];% ["\tau_{intrinsic}"];
end

r2s = ["r2"]; %_delta _delta
r2labels = ["cvR^2"]; %\Delta

flag = config();

nex = length(exos);
nts = 2;
i = 1;
for i = 1:length(timescales)
for jjj = 1:1
for k = 1:length(r2s)
for ii = 1:nts
    figure('position', [   431   0   1200   300]); 
    exos_use = exos;
    if ii == 1 || timescales(1) == "seasonal"
        exos_use = exos(1:2);
    end
    if ii == 1
       c = pre_tr_ntr_color;
    elseif ii == 2
       c = post_tr_ntr_color;
    end
    if ii == 1
        nt = nt_pre;
    else
        nt = nt_post;
    end
    for j = 1:length(exos_use)
        exo = exos(j);
        ts = timescales(i);
        f = fields(i);
        r2 = r2s(k);
        inc = (logical(nt{:, 'include_' + ts}));
        inc_both = (logical(nt{:, 'include_' + ts} & nt{:, 'include_' + exo}));
        inc_noexo = (logical(nt{:, 'include_' + ts} & ~nt{:, 'include_' + exo}));
        x = nt{:, f}(inc);
        y = nt{:, r2 + "_" + exo}(inc);
        x_both = nt{:, f}(inc_both);
        y_both = nt{:, r2 + "_" + exo}(inc_both);
        x_noexo = nt{:, f}(inc_noexo);
        y_noexo = nt{:, r2 + "_" + exo}(inc_noexo);
        
        inc = ~isnan(x) & ~isnan(y) & y > 0; % pos r2
        inc_both = ~isnan(x_both) & ~isnan(y_both) & y_both > 0; % pos r2
        inc_noexo = ~isnan(x_noexo) & ~isnan(y_noexo) & y_noexo > 0; % pos r2

        x_both = x_both(inc_both);
        y_both = y_both(inc_both);
        x_noexo = x_noexo(inc_noexo);
        y_noexo = y_noexo(inc_noexo);
        x = x(inc);
        y = y(inc);

        subplot(1,4, j);
        
        if jjj == 1
        loglog(x_noexo,y_noexo,  "o",'MarkerFaceColor',c{2}, 'markeredgecolor', c{2}, 'markersize', 3); hold on;
        loglog(x_both,y_both,  "o",'MarkerFaceColor',c{1}, 'markeredgecolor', c{1}, 'markersize', 3); hold on;
        elseif jjj == 2
        loglog(x_noexo,y_noexo,  "o",'MarkerFaceColor',c{2}, 'markeredgecolor', c{2}, 'markersize', 3); hold on;
        y = y_noexo;
        x = x_noexo;
        elseif jjj == 3
        semilogx(x_both,y_both,  "o",'MarkerFaceColor',c{1}, 'markeredgecolor', c{1}, 'markersize', 3); hold on;
        y = y_both;
        x = x_both;
        end
        set_axis_defaults();
        xlabel(labels(i));  
        ylabel(exo_labels(j) + " " + r2labels(k))
        
        if (j > 1 | ii > 1)
            %xlim(xli);
            %ylim(yli);
        else
            xli = xlim;
            if ts == "intrinsic"
                %xlim([xli(1), 10^3]);
            else 
                %xlim([xli(1), 10]);
            end
        end
        yli = ylim;

        %mdl = fitlm(log(x),log(y));
        %xl = xlim;
        %yl = exp(mdl.predict(log(xl)'));
        %plot((xl), (yl), 'linewidth', 2);
        
        [r, p] = corr(x, y, 'Type', 'spearman');
        
        axis square;

        text(.6, .9, "r_s = " + num2str(round(r,2)), 'units', 'normalized', 'fontsize', 12)
        text(.6, .8, "p_s = " + num2str(round(p,8)), 'units', 'normalized', 'fontsize', 12)
        text(.6, .7, "n = " + length(x), 'units', 'normalized', 'fontsize', 12)
        if ts == "intrinsic"
            %xticks([10^2, 10^3]);
        end
        %yticks([10^(-3), 10^(-2)]);
    end
end
end
end
end
end