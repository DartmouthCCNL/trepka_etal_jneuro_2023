function analyze_multicollinearity(pre_or_post)
flag = config();
R = [];
P = [];

if pre_or_post == "pre"
    loadFolder = flag.pre_model_input;
    load(flag.pre_saved_neurons);
else
    loadFolder = flag.post_model_input;
    load(flag.post_saved_neurons);
end

neuron_addresses = savedNeurons.address;

for neu_idx = 1:length(neuron_addresses)
    fprintf(append('neu num <a href="">',num2str(neu_idx),'</a>\n'));

    output = get_design_matrix(neuron_addresses{neu_idx}, loadFolder);
    X = output.x;
    corr_lbls = 1:size(X,2);
    corr_mtx = struct;
    for cntII = 1:length(corr_lbls)
        for cntJJ = 1:length(corr_lbls)
            tempData1 = X(:,cntII);
            tempData2 = X(:,cntJJ);

            sharedIdx = ~isnan(tempData1) & ~isnan(tempData2);
            [corr_mtx.R(cntII,cntJJ) , corr_mtx.P(cntII,cntJJ)] = ...
                corr(tempData1(sharedIdx), tempData2(sharedIdx));
        end
    end
    R(:,:,neu_idx) = corr_mtx.R;
    P(:,:,neu_idx) = corr_mtx.P;
end

% average R and P over all neurons
corr_mtx = struct;
corr_mtx.R = nanmean(R, 3);
corr_mtx.P = nanmean(P, 3);

save(append(flag.plot_cache, pre_or_post, "_corrmtx",".mat"),'R','P','corr_mtx');
end


function output = get_design_matrix(neuron_address, loadFolder)
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
    output.scope = scope;
    output.x = x;
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