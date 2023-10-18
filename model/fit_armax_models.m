function output = fit_armax_models(pre_or_post)

flag = config();

% setup paths and load saved neurons
if pre_or_post == "post"
    loadFolder = flag.post_model_input;
    savingFile = flag.post_model_output;
    load(flag.post_saved_neurons);
elseif pre_or_post == "pre"
    loadFolder = flag.pre_model_input;
    savingFile = flag.pre_model_output;
    load(flag.pre_saved_neurons);
else
    error(pre_or_post + " is not valid, should be 'pre' or 'post'");
end

% create output dir if it doesn't exist
[saveFolder, ~, ~] = fileparts(savingFile);
if ~exist(saveFolder, 'dir')
    mkdir(saveFolder);
end

neuronAddresses = savedNeurons.address;
numNeurons = length(savedNeurons.address);

% progress indicator length
progress_length = 0;
isparallel = true;

fe_cnt = 0;
rd_cnt = 0;

disp("fitting " + numNeurons + " neurons...");
all_results = {};
parfor neu_num = 1:numNeurons % change to parfor for cluster
    rng(neu_num); % seed rng for reproducibility of fitting results (e.g., CV splits)
    neuron_address = char(neuronAddresses{neu_num});
    output = fit_single_neuron(neuron_address, loadFolder);
    all_results{neu_num} = output;

    fe_cnt = fe_cnt + output.fit_error;
    rd_cnt = rd_cnt + output.rank_def;
    
    if isparallel
        disp(neu_num);
    else
        fprintf(repmat('\b',1,progress_length))
        progress_length = fprintf(['progress: ',num2str(neu_num), ' | ',num2str(numNeurons), ' | ', num2str(100*round(neu_num/numNeurons,2)),'%%']);
    end
end

% report any potential fitting errors
disp("fit report for " + numNeurons + " neurons:")
disp(numNeurons-fe_cnt-rd_cnt + " fitted without modification");
disp(fe_cnt + " neurons had too few samples for fitting");
disp(rd_cnt + " had predictor matrices that were rank deficient, likely due to exogenous interaction terms");

save(savingFile,'all_results','-v7');
end

function output = fit_single_neuron(neuron_address, loadFolder)
    flag = config();

    load([loadFolder,neuron_address,'.mat'],'MyData'); % load MyData
        
    neuronData = constructNeuronData(MyData, flag); %construct neuronData from MyData
    
    % number of trials and bins
    ntr = size(neuronData.firingRateMat, 1);
    nbn = size(neuronData.firingRateMat, 2);

    % subtract psth from firing rate mat
    fr = neuronData.firingRateMat;
    fr_ctr = fr - repmat(neuronData.firingRateMatMean, ntr, 1);

    % construct variable to predict, y
    y = reshape(fr_ctr', [], 1);

    % construct design matrix
    npr = flag.npr; % number of predictors
    x = nan(ntr, nbn, npr);

    % construct intrinsic predictor matrix
    x_intrinsic = zeros(ntr, nbn, flag.intrinsic_order);
    for i = 1:flag.intrinsic_order
        x_intrinsic(:, 1+i:end, i) = fr_ctr(:, 1:end-i);
    end
    x_intrinsic(isnan(x_intrinsic)) = 0; % replace nan with 0 to avoid excluding first flag.intrinsic_order*flag.binsize ms of fixation period

    % construct seasonal predictor matrix
    x_seasonal = zeros(ntr, nbn, flag.seasonal_order);
    for i = 1:flag.seasonal_order
        x_seasonal(1+i:end, :, i) = movmean(fr_ctr(1:end-i, :), flag.seasonal_window, 2);
    end
    x_seasonal(isnan(x_seasonal)) = 0; % replace nan with 0 to avoid excluding the first trial

    % construct exogenous predictor matrix
    x_exo = struct;

    x_exo.cue = repmat(x2fx(neuronData.signalValue.cue, [1], [1]), 1, 1, nbn, flag.num_cue);
    x_exo.sample = repmat(x2fx(neuronData.signalValue.sample, [1], [1]), 1, 1, nbn, flag.num_sample);
    x_exo.match = repmat(x2fx(neuronData.signalValue.match, [1], [1]), 1, 1, nbn, flag.num_match);

    % we have to do an interesting transformation here because a sample
    % value of 9 is never nonmatch (otherwise -> rank deficient)
    % so in trials where sample value is 9, we fill the interaction matrix
    % with zeros
    samplexmatch = zeros(ntr, flag.npos-2);

    sample_x = neuronData.signalValue.sample;
    match_x = neuronData.signalValue.match;
    center_idx = find(sample_x == 9);
    include_idx = setdiff(1:ntr, center_idx);
    sample_x(center_idx) = [];
    match_x(center_idx) = [];
    samplexmatch(include_idx, :) = x2fx([sample_x, match_x], [1, 1], [1, 2]);

    x_exo.samplexmatch = repmat(samplexmatch, 1, 1, nbn, flag.num_samplexmatch);
   
    exo_names = ["cue", "sample", "match", "samplexmatch"];
    for i = 1:length(exo_names)
        x_exo.(exo_names(i)) = permute(x_exo.(exo_names(i)), [1, 3, 2, 4]);
    end

    % filter based on time in trial, we use 4 filters 
    % cue - cue + 500 ms; cue + 500 ms - sample; sample - sample + 500 ms;
    % sample + 500 ms - sample + 2000 ms;
    % the interval filters are ntr x nbn logical filters for the particular
    % time interval expressed in time bins
    before_cue = repmat(neuronData.signalTime.cue, 1, nbn) > neuronData.timeIntervalsAbsolute(:, 1:end-1);
    before_delay1 = repmat(neuronData.signalTime.cue + 500, 1, nbn) > neuronData.timeIntervalsAbsolute(:, 1:end-1);
    before_sample = repmat(neuronData.signalTime.sample, 1, nbn) > neuronData.timeIntervalsAbsolute(:, 1:end-1);
    before_delay2 = repmat(neuronData.signalTime.sample + 500, 1, nbn) > neuronData.timeIntervalsAbsolute(:, 1:end-1);
    before_end = repmat(neuronData.signalTime.sample + 2000, 1, nbn) > neuronData.timeIntervalsAbsolute(:, 1:end-1);

    intervals = {};
    intervals{1} = before_delay1 & ~before_cue;
    intervals{2} = before_sample & ~before_delay1;
    intervals{3} = before_delay2 & ~before_sample;
    intervals{4} = before_end & ~before_delay2;

    exo_names = ["cue", "sample", "match", "samplexmatch"]; 
    start = [0, 2, 2, 2];
    for i = 1:length(exo_names)
        for j = 1:flag.("num_" + exo_names(i))
           x_exo.(exo_names(i))(:, :, :, j) = x_exo.(exo_names(i))(:, :, :, j) .* intervals{j + start(i)};
        end
    end

    % reshape so num trials x num bins x num predictors
    for i = 1:length(exo_names);
        x_exo.(exo_names(i)) = reshape(x_exo.(exo_names(i)), ntr, nbn, []);
    end

    % construct bias terms for each task interval
    x_bias = struct;
    x_bias.b1 = before_cue;
    x_bias.b2 = before_delay1 & ~before_cue;
    x_bias.b3 = before_sample & ~before_delay1;
    x_bias.b4 = before_delay2 & ~before_sample;
    x_bias.b5 = before_end & ~before_delay2;

    % put x together
    components = ["intrinsic", "seasonal", exo_names];
    scope = struct;

    sz = 1;
    
    scope.intrinsic = sz:flag.intrinsic_order;
    x(:, :, scope.intrinsic) = x_intrinsic;
    sz=sz+flag.intrinsic_order;

    scope.seasonal = sz:sz+flag.seasonal_order-1;
    x(:, :, scope.seasonal) = x_seasonal;
    sz=sz+flag.seasonal_order;    

    for i = 1:length(exo_names)
        exo = exo_names(i);
        exo_sz = size(x_exo.(exo), 3);
        scope.(exo) = sz:sz + exo_sz -1;
        x(:, :, scope.(exo)) = x_exo.(exo);
        sz=sz+exo_sz;  
    end

    for i = 1:flag.num_bias
        name = "b" + i;
        scope.(name) = sz;
        x(:, :, scope.(name)) = x_bias.(name);
        sz=sz+1;  
    end
        
    % add a component for 'all_exogenous' predictors so we can measure the
    % combined effect of all exogenous terms
    all_tr = [];
    for i = 1:length(exo_names)
        exo = exo_names(i);
        all_tr = [all_tr, scope.(exo)];
    end
    scope.all_tr = all_tr;
    components = [components, "all_tr"];

    % add a single group of 'bias' predictors to scope
    all_bias = [];
    for i = 1:flag.num_bias
        name = "b" + i;
        all_bias = [all_bias, scope.(name)];
    end
    scope.all_bias = all_bias;

    % reshape x so it is 2d
    x = reshape(permute(x, [2, 1, 3]), nbn*ntr, []);

    % now we remove all points where any x is nan or y is nan
    x_nan = sum(isnan(x), 2) > 0;
    y_nan = isnan(y);
    x(x_nan | y_nan, :) = [];
    y(x_nan | y_nan) = [];
    y = squeeze(y);

    % handle rare neurons where x/y has fewer than 2 observations, fill with
    % random numbers and mark as a fit error
    fit_error = false;
    if size(x, 1) < 2
        x = rand(100, size(x,2));
        y = rand(100, 1);
        fit_error = true;
    end

    % now we are ready to fit the full model, single-component models, and
    % the full model with components removed

    % define a cv partition that we will use for fitting all the models
    partition = cvpartition(length(y), 'KFold', flag.num_folds);

    % first, we fit the full model using cv linear regression
    models = struct;
    r2 = struct;
    comp_vars = struct;

    mse = crossval('mse',x,y,'Predfun',@regf, 'Partition', partition);
    mse_dist = crossval(@regf_all, x,y, 'Partition', partition);
    r2.full = 1 - (mse * length(y))/sum((y-mean(y)).^2);
    models.full_dist = mse_dist;
    
    % next we fit models composed of each individual component with bias
    % terms
    ind_components = [components, "bias_only", "sample_match"];
    for component = ind_components
        if component == "samplexmatch"
            x_sub = [scope.sample, scope.match, scope.(component), scope.all_bias];    
        elseif component == "bias_only"
            x_sub = [scope.all_bias];
        elseif component == "sample_match"
            x_sub = [scope.sample, scope.match, scope.all_bias];
        else
            x_sub = [scope.(component), scope.all_bias];
        end
        mse = crossval('mse',x(:, x_sub), y,'Predfun',@regf, 'Partition', partition);
        mse_dist = crossval(@regf_all, x(:, x_sub), y, 'Partition', partition);
        r2.(component) = 1 - (mse * length(y))/sum((y-mean(y)).^2);
        comp_vars.("vars_" + component) = regress(y, x(:, x_sub));
        models.(component + "_individual_dist") = mse_dist;
    end

    % finally we fit models composed of everything except the component
    for component = components
        x_scope = setdiff(1:size(x,2), scope.(component));

        % if sample or match component, also remove the interaction term 
        if component == "sample" || component == "match"
            x_scope = setdiff(x_scope, scope.samplexmatch);
        end

        mse = crossval('mse',x(:, x_scope),y,'Predfun',@regf, 'Partition', partition);
        mse_dist = crossval(@regf_all, x(:, x_scope), y, 'Partition', partition);
        r2.("delta_" + component) = r2.full - (1 - (mse * length(y))/sum((y-mean(y)).^2));
        models.(component + "_dist") = mse_dist;
    end

    mdl = fitlm(x,y, 'intercept', false);

    output = struct;
    output.comp_vars = comp_vars;
    output.r2 = r2;
    output.models = models;
    output.mean_fr = nanmean(neuronData.firingRateMat, 'all');
    output.scope = scope;
    output.vars = mdl.Coefficients.Estimate;
    output.pvalues = mdl.Coefficients.pValue; 
    output.fit_error = fit_error;
    output.rank_def = rank(x) < size(x, 2); % if x is still rank deficient, report it
end

function yfit = regf(Xtrain,ytrain,Xtest)
    b = regress(ytrain,Xtrain);
    yfit = Xtest*b;
end

function r2 = regf_all(Xtrain,ytrain,Xtest, ytest)
    b = regress(ytrain,Xtrain);
    yfit = Xtest*b;
    mse = nanmean((yfit-ytest).^2);
    r2 = 1 - (mse * length(ytest))/sum((ytest-mean(ytest)).^2);
end

function neuronData = constructNeuronData(MyData, flag)
% set up the neural data structure for model input
% we convert spikes and signal times to ms
% and encode exogenous predictors as +1 and -1 binary variables
neuronData = NeuronData(MyData.sorted.TS'*1000, flag.binsize);

neuronData.addTrialBeginEndSignal('fix_on', 'end_trial');
neuronData.addSignalTime('fix_on', MyData.sorted.Fix_onT'*1000);
neuronData.addSignalTime('end_trial', MyData.sorted.EndofTrialtime'*1000);
neuronData.addAlignTrialSignal('cue', 6000, 10000);
neuronData.addSignalTime('cue', MyData.sorted.Cue_onT'*1000);
neuronData.addSignalTime('sample', MyData.sorted.Sample_onT'*1000);
neuronData.addSignalValue('match', (MyData.sorted.isMatch*2-1)');
neuronData.addSignalValue('cue', (MyData.sorted.Cue_signal)');
neuronData.addSignalValue('sample', (MyData.sorted.Sample_signal)');

neuronData.binData();
end