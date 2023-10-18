function nt = postprocess_model_output(pre_or_post)
rng(5); % for reproducibility

flag = config();

for ce = ["corr", "err"]
% setup paths and load saved neurons and model output
if pre_or_post == "post"
    loadFolder = flag.post_model_input;
    load(flag.post_saved_neurons);
    load(flag.("post_" + ce + "_model_output"));
    savepath = flag.("post_" + ce + "_plot_input");
elseif pre_or_post == "pre"
    loadFolder = flag.pre_model_input;
    load(flag.pre_saved_neurons);
    load(flag.("pre_" + ce + "_model_output"));
    savepath = flag.("pre_" + ce + "_plot_input");
else
    error(pre_or_post + " is not valid, should be 'pre' or 'post'");
end

% construct table in matlab containing - neuron address, area, mean firing
% rate, column for vars, intrinsic taus, seasonal taus, 
% r2 for each component
if ce == "corr"
    all_results = all_results_corr;
else
    all_results = all_results_err;
end

n = length(all_results);
order = ["posterior dorsal", "mid dorsal", "anterior dorsal", "posterior ventral", "anterior ventral"];
areas = categorical(savedNeurons.area);
varTypes = ["categorical", "string", "categorical","double", "logical", "double", "double", "double", "double", "double", "double", "double"];
varNames = ["condition", "address","area", "tr_cnt", "fit_error", "mean_fr", "intrinsic_tau", "seasonal_tau", "intrinsic_tau_exp", "intrinsic_r2_exp", "intrinsic_mi_exp", "intrinsic_r2_lin"];
components = ["intrinsic", "seasonal", "cue", "sample", "match", "samplexmatch", "all_tr"];

r2_fields = fieldnames(all_results{1}.r2);
for i = 1:length(r2_fields)
    varTypes = [varTypes, "double"];
    varNames = [varNames, "r2_" + r2_fields{i}];
end

sz = [n length(varTypes)];

nt = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% add columns for var, cannot be instatiated in the same way
% because contains array data
nt.vars = zeros(n, flag.npr);
nt.scope = repmat([all_results{1}.scope], n, 1);
nt.int_rs = zeros(n, flag.intrinsic_order);
nt.sea_rs = zeros(n, flag.seasonal_order);
nt.intrinsic_bs = zeros(n, 1);
nt.intrinsic_decrease = zeros(n, 1);
nt.intrinsic_acf = zeros(n, flag.intrinsic_order);
nt.seasonal_acf = zeros(n, max(5, flag.seasonal_order));

for i = 1:length(components)
    nt.("p_" + components(i)) = zeros(n, length(all_results{1}.scope.(components(i))));
end

nt.r2_dist_full = zeros(n, flag.num_folds);
for i = 1:length(components)
    nt.("r2_dist_" + components(i)) = zeros(n, flag.num_folds);
end

ind_components = [components, "bias_only", "sample_match"];
for i = 1:length(ind_components)
    nt.("r2_individual_dist_" + ind_components(i)) = zeros(n, flag.num_folds);
end

a_sea = [];
progress_length = 0;
for neu_num = 1:length(all_results)
    r = all_results{neu_num};
    nt{neu_num, 'condition'} = categorical(pre_or_post + "-training");
    nt{neu_num, 'address'} = string(savedNeurons.address{neu_num});
    nt{neu_num, 'area'} = areas(neu_num);
    nt{neu_num, 'tr_cnt'} = r.("num_" + ce);
    if r.fitted
        nt{neu_num, 'fit_error'} = r.fit_error;
        nt{neu_num, 'mean_fr'} = r.mean_fr;
    
        int_vars = r.vars(r.scope.intrinsic)';
        sea_vars = r.vars(r.scope.seasonal)';
        
        nt{neu_num, 'intrinsic_acf'} = compute_acf_from_ars(int_vars);
        nt{neu_num, 'intrinsic_tau'} = compute_ar_tau(int_vars, flag.binsize);
    
        % if signs of refractoriness fit exponential from first decreasing bin onward
        % removing at most 1-3 bins
        times = flip(-flag.binsize*flag.intrinsic_order:flag.binsize:-flag.binsize);
        acf = nt{neu_num, 'intrinsic_acf'};
        mi = find((acf(1:end-1) - acf(2:end)) > 0, 1);
        if length(mi) == 0 || mi >= 4
            mi = 4;
        end
        acf = acf(mi:end);
        times = times(mi:end);
        mdl = fitlm(times, acf);
        nt{neu_num, 'intrinsic_r2_lin'} = mdl.Rsquared.Ordinary;
        nt{neu_num, 'intrinsic_mi_exp'} = mi;
    
        [nt{neu_num, 'intrinsic_r2_exp'}, nt{neu_num, 'intrinsic_tau_exp'}] = compute_tau_exp(acf, times, "intrinsic");
    
        nt{neu_num, 'seasonal_tau'} = compute_ar_tau(sea_vars, flag.triallen);
    
        nt{neu_num, 'int_rs'} = int_vars;
        nt{neu_num, 'sea_rs'} = sea_vars;
        nt{neu_num, 'scope'} = r.scope;
        nt{neu_num, 'vars'} = squeeze(r.vars');
    
        b = regress(int_vars', [(1:flag.intrinsic_order)', ones(flag.intrinsic_order,1)]);
        nt{neu_num, 'intrinsic_bs'} = b(1);
    
        for i = 1:length(r2_fields)
            nt{neu_num, "r2_" + r2_fields{i}} = r.r2.(r2_fields{i});
        end
    
        for i = 1:length(components)
            nt{neu_num, "r2_dist_" + components(i)} = r.models.(components(i) + "_dist")';
        end
        nt{neu_num, "r2_dist_full"} = r.models.full_dist';
    
        for i = 1:length(ind_components)
            nt{neu_num, "r2_individual_dist_" + ind_components(i)} = r.models.(ind_components(i) + "_individual_dist")';
        end
    
        for i = 1:length(components)
            nt{neu_num, "p_" + components(i)} = r.pvalues(r.scope.(components(i)))';
        end
    end 
    fprintf(repmat('\b',1,progress_length))
    progress_length = fprintf(['progress: ',num2str(neu_num), ' | ',num2str(length(all_results))]);
end

% format area labels
area_order = {'posterior dorsal', 'mid dorsal', 'anterior dorsal', 'posterior ventral', 'anterior ventral'};
nt.area = categorical(nt.area,area_order);

save(savepath, 'nt');
end
end

function tau = compute_ar_tau(ar_coeffs, lag)
    n = length(ar_coeffs);
    eigMat = [ar_coeffs;[eye(n-1) zeros(n-1,1)]];
    lamdas = eig(eigMat);
    tau = max((-lag./log(abs(lamdas))));
end

function [r2, tau] = compute_tau_exp(ar_coeffs, times, component)
    rs = ar_coeffs;
    [r2, tau] = fit_exp(times, rs, component);
end