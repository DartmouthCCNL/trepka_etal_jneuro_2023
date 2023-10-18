% load data tables for pre and post, and subset timescales based on
% inclusion criterion
flag = config();

rng(7); % for reproducibility

acc.intrinsic = struct;
acc.seasonal = struct;

ffs = {};
cnts = 0;
for ts = ["intrinsic", "seasonal"]
    pre = load(flag.pre_plot_input, 'nt');
    post = load(flag.post_plot_input, 'nt');

    nt_pre = pre.nt;
    nt_post = post.nt;

    nt_pre = add_exclusions_full(nt_pre);
    nt_post = add_exclusions_full(nt_post);

    % get subset of neurons that include intrinsic
    nt_pre = nt_pre(logical(nt_pre{:, "include_" + ts}),:);
    nt_post = nt_post(logical(nt_post{:, "include_" + ts}),:);
    
    nt_pre = add_fano_factor(nt_pre, "pre");
    nt_post = add_fano_factor(nt_post, "post");

    if ts == "intrinsic"
        timescale = "intrinsic_tau_exp";
    else
        timescale = "seasonal_tau";
    end

    acc.(ts).pre.long.shuff_acc = [];
    acc.(ts).pre.long.acc = [];
    acc.(ts).pre.short.shuff_acc = [];
    acc.(ts).pre.short.acc = [];
    acc.(ts).post.long.shuff_acc = [];
    acc.(ts).post.long.acc = [];
    acc.(ts).post.short.shuff_acc = [];
    acc.(ts).post.short.acc = [];

    for pre_or_post = ["pre", "post"];
        for ls = ["long", "short"]
            cnts = cnts + 1;
            disp(pre_or_post + " " + ls);
            med = median([nt_pre{:, timescale}; nt_post{:, timescale}]);
            disp(med);
            if ls == "long"
                nt_pre_int = nt_pre(nt_pre{:, timescale} > med,:);
                nt_post_int = nt_post(nt_post{:, timescale} > med, :);
            else
                nt_pre_int = nt_pre(nt_pre{:, timescale} <= med,:);
                nt_post_int = nt_post(nt_post{:, timescale} <= med, :);
            end

%             % setup paths and load saved neurons
%             if pre_or_post == "post"
%                 loadFolder = flag.post_model_input;
%                 neuronAddresses = nt_post_int{:, "address"};
%                 disp(mean(nt_post_int.fano_factor));
%                 ffs{cnts} = nt_post_int.fano_factor;
%             elseif pre_or_post == "pre"
%                 loadFolder = flag.pre_model_input;
%                 neuronAddresses = nt_pre_int{:, "address"};
%                 disp(mean(nt_pre_int.fano_factor))
%                 ffs{cnts} = nt_pre_int.fano_factor;
%             end
%             
%             numNeurons = length(neuronAddresses);
% 
%             all_fr = [];
%             all_cue_val = [];
%             all_neu_id = [];

%             % remove any neurons with fewer than 10 examples per condition
%             for neu_num = 1:numNeurons
%                 neuron_address = char(neuronAddresses{neu_num});
%                 load([loadFolder,neuron_address,'.mat'],'MyData'); % load neuronData
% 
%                 flag = config();
%                 neuronData = constructNeuronData(MyData, flag);
% 
%                 idxes = find(~isnan(neuronData.firingRateMat(1,:)));
% 
%                 cue_val = neuronData.signalValue.cue;
%                 fr = neuronData.firingRateMat(:, idxes);
%                 fr = fr(:, 1:100); % 5 s trial period
% 
%                 t = tabulate(cue_val);
%                 rem = false;
%                 if sum(t(:, 2) < 10) > 0
%                     rem = true;
%                 end
% 
% 
%                 if ~rem
%                     trial_idxes = [];
%                     for i = 1:9
%                         cue_idx = find(cue_val == i);
%                         cue_ord = randperm(length(cue_idx));
%                         cue_ord = cue_idx(cue_ord(1:10));
%                         trial_idxes = [trial_idxes; cue_ord];
%                     end
% 
%                     cue_val = cue_val(trial_idxes,:);
%                     fr = fr(trial_idxes,:);
% 
%                     all_neu_id = [all_neu_id; repmat(string(neuron_address), length(cue_val), 1)];
%                     all_cue_val = [all_cue_val; cue_val];
%                     all_fr = [all_fr; fr];
%                 end
% 
%             end
% 
%             % now we want to get subpopulations of neurons of fixed size, reshape FR
%             % matrix and align trials with same cue value, then train decoder
%     
%            disp(ts+ " " + pre_or_post+ " " + ls + " " + length(unique(all_neu_id)));
        end
    end
end


function neuronData = constructNeuronData(MyData, flag)
%% Setting up the sample neuralData Structure for model input
neuronData = NeuronData(MyData.sorted.TS'*1000, flag.binsize);
neuronData.addTrialBeginEndSignal('fix_on', 'end_trial');
neuronData.addAlignTrialSignal('cue', 6000, 10000);
neuronData.addSignalTime('cue', MyData.sorted.Cue_onT'*1000);
neuronData.addSignalTime('sample', MyData.sorted.Sample_onT'*1000);
neuronData.addSignalTime('fix_on', MyData.sorted.Fix_onT'*1000);
neuronData.addSignalTime('end_trial', MyData.sorted.EndofTrialtime'*1000);
neuronData.addSignalValue('match', (MyData.sorted.isMatch*2-1)');
neuronData.addSignalValue('cue', (MyData.sorted.Cue_signal)');
neuronData.addSignalValue('sample', (MyData.sorted.Sample_signal)');
neuronData.addSignalValue('cue_bin', (MyData.sorted.Cue_signal_new*2-1)');
neuronData.addSignalValue('sample_bin', (MyData.sorted.Sample_signal_new*2-1)');
neuronData.binData();
end

function loss = getKFoldCorrLoss(X, y, k, norm)
cv_part = cvpartition(categorical(y), 'KFold', k);

losses = [];
for ii = 1:k
    train_idx = cv_part.training(ii);
    test_idx = cv_part.test(ii);
    X_train = X(train_idx, :);
    y_train = y(train_idx);
    X_test = X(test_idx, :);
    y_test = y(test_idx);

    if norm
        train_mean = mean(X_train, 1);
        train_std = std(X_train, 1);
        X_train = ((X_train-train_mean)./train_std);
        X_test = ((X_test-train_mean)./train_std);
        X_train(isnan(X_train)) = 0;
        X_test(isnan(X_test)) = 0;
    end

    templates = [];
    for cue_idx = 1:9
        templates = [templates, mean(X_train(cue_idx == y_train, :), 1)'];
    end

    outs = corr(X_test', templates);
    [~, preds] = max(outs, [], 2);

    test_acc = sum(preds == y_test)/length(y_test);

    losses = [losses; test_acc];
end

loss = mean(losses);

end
