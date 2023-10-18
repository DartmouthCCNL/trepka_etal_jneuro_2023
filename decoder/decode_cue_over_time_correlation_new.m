% load data tables for pre and post, and subset timescales based on
% inclusion criterion
flag = config();

rng(9); % for reproducibility

acc.intrinsic = struct;
acc.seasonal = struct;

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

    if ts == "intrinsic"
        timescale = "intrinsic_tau_exp";
    else
        timescale = "seasonal_tau";
    end

    acc.(ts).pre.long.cue_shuff_acc = [];
    acc.(ts).pre.long.length_shuff_acc = [];
    acc.(ts).pre.long.task_shuff_acc = [];
    acc.(ts).pre.long.acc = [];

    acc.(ts).pre.short.cue_shuff_acc = [];
    acc.(ts).pre.short.length_shuff_acc = [];
    acc.(ts).pre.short.task_shuff_acc = [];
    acc.(ts).pre.short.acc = [];

    acc.(ts).post.long.cue_shuff_acc = [];
    acc.(ts).post.long.length_shuff_acc = [];
    acc.(ts).post.long.task_shuff_acc = [];
    acc.(ts).post.long.acc = [];

    acc.(ts).post.short.cue_shuff_acc = [];
    acc.(ts).post.short.length_shuff_acc = [];
    acc.(ts).post.short.task_shuff_acc = [];
    acc.(ts).post.short.acc = [];

    nt_pre.condition = repmat("pre", height(nt_pre), 1);
    nt_post.condition = repmat("post", height(nt_post), 1);

    nt = [nt_pre; nt_post];
    is_long = (nt{:, timescale} > median(nt{:, timescale})) + 1;
    lengths = ["short", "long"];
    nt.length = lengths(is_long)';

    neuronAddresses = nt{:, "address"};

    numNeurons = length(neuronAddresses);

    all_fr = [];
    all_cue_val = [];
    all_neu_id = [];
    all_lengths = [];
    all_conditions = [];

    % remove any neurons with fewer than 10 examples per condition
    for neu_num = 1:numNeurons
        neuron_address = char(neuronAddresses{neu_num});

        if nt.condition(neu_num) == "post"
            loadFolder = flag.post_model_input;
        elseif nt.condition(neu_num)  == "pre"
            loadFolder = flag.pre_model_input;  
        end

        load([loadFolder,neuron_address,'.mat'],'MyData'); % load neuronData

        flag = config();
        neuronData = constructNeuronData(MyData, flag);

        idxes = find(~isnan(neuronData.firingRateMat(1,:)));

        cue_val = neuronData.signalValue.cue;
        fr = neuronData.firingRateMat(:, idxes);
        fr = fr(:, 1:100); % 5 s trial period

        t = tabulate(cue_val);
        rem = false;
        if sum(t(:, 2) < 10) > 0
            rem = true;
        end

        if ~rem
            trial_idxes = [];
            for i = 1:9
                cue_idx = find(cue_val == i);
                trial_idxes = [trial_idxes; cue_idx]; % including all trials for every neuron
            end

            cue_val = cue_val(trial_idxes,:);
            fr = fr(trial_idxes,:);

            all_neu_id = [all_neu_id; repmat(string(neuron_address), length(cue_val), 1)];
            all_lengths = [all_lengths; repmat(nt.length(neu_num), length(cue_val), 1)];
            all_conditions = [all_conditions; repmat(nt.condition(neu_num), length(cue_val), 1)];
            all_cue_val = [all_cue_val; cue_val];
            all_fr = [all_fr; fr];
        end
    end


    for pre_or_post = ["pre", "post"];
        for ls = ["long", "short"]
            disp(pre_or_post + " " + ls);

            % now we want to get subpopulations of neurons of fixed size, reshape FR
            % matrix and align trials with same cue value, then train decoder
            neu_ids_subset = all_neu_id(all_conditions == pre_or_post & ls == all_lengths);

            neu_ids = unique(neu_ids_subset);
            accuracy = [];
            shuf_accuracy = [];

            % sample 50 neurons at random
            subpop_size = 50;
            max_iters = 200;
            for iters = 1:max_iters
                disp(iters);
                inc_idxs = randperm(length(neu_ids));
                inc_ids = neu_ids(inc_idxs(1:subpop_size));
                inc_rows = ismember(all_neu_id, inc_ids);

                curr_id = all_neu_id(inc_rows,:);
                curr_cue = all_cue_val(inc_rows,:);
                curr_fr = all_fr(inc_rows,:);
                uids = unique(curr_id);

                ridx = randperm(length(curr_cue));
                curr_fr = curr_fr(ridx,:);
                curr_id = curr_id(ridx,:);
                curr_cue = curr_cue(ridx,:);

                X_fr = zeros(90, length(uids), 100);
                y = zeros(90,1);
                cnt = 1;
                for i = 1:10
                    for j = 1:9
                        for k = 1:length(uids)
                            neu_idx = find(curr_cue == j & curr_id == uids(k));
                            X_fr(cnt, k, :) = curr_fr(neu_idx(i),:);
                        end
                        y(cnt) = j;
                        cnt = cnt + 1;
                    end
                end

                for tps = 1:51
                    X = mean(X_fr(:, :, (tps):(9+tps)), 3); % get fr during cue period

                    k = 10;
                    norm = true;

                    accuracy(tps, iters) = getKFoldCorrLoss(X, y, k, norm);

                    shuff_y = y(randperm(length(y)));
                    shuff_accuracy(tps, iters) = getKFoldCorrLoss(X, shuff_y, k, norm);
                end
            end
            acc.(ts).(pre_or_post).(ls).acc = accuracy;
            acc.(ts).(pre_or_post).(ls).cue_shuff_acc = shuff_accuracy;
        end
    end

    for pre_or_post = ["pre", "post"];
        disp(pre_or_post);
        % now we want to get subpopulations of neurons of fixed size, reshape FR
        % matrix and align trials with same cue value, then train decoder
        neu_ids_subset = all_neu_id(pre_or_post == all_conditions);

        neu_ids = unique(neu_ids_subset);
        accuracy = [];
        shuf_accuracy = [];

        % sample 50 neurons at random
        subpop_size = 50;
        for iters = 1:max_iters
            disp("pt2: " + iters);
            inc_idxs = randperm(length(neu_ids));
            for jjj = 1:2
                inc_ids = neu_ids(inc_idxs(1 + (jjj-1)*subpop_size:(jjj)*subpop_size));
                inc_rows = ismember(all_neu_id, inc_ids);

                curr_id = all_neu_id(inc_rows,:);
                curr_cue = all_cue_val(inc_rows,:);
                curr_fr = all_fr(inc_rows,:);
                uids = unique(curr_id);

                ridx = randperm(length(curr_cue));
                curr_fr = curr_fr(ridx,:);
                curr_id = curr_id(ridx,:);
                curr_cue = curr_cue(ridx,:);

                X_fr = zeros(90, length(uids), 100);
                y = zeros(90,1);
                cnt = 1;
                for i = 1:10
                    for j = 1:9
                        for k = 1:length(uids)
                            neu_idx = find(curr_cue == j & curr_id == uids(k));
                            X_fr(cnt, k, :) = curr_fr(neu_idx(i),:);
                        end
                        y(cnt) = j;
                        cnt = cnt + 1;
                    end
                end

                for tps = 1:51
                    X = mean(X_fr(:, :, (tps):(9+tps)), 3); % get fr during cue period

                    k = 10;
                    norm = true;

                    if jjj == 1
                        long_accuracy(tps, iters) = getKFoldCorrLoss(X, y, k, norm);
                    else
                        short_accuracy(tps, iters) = getKFoldCorrLoss(X, y, k, norm);
                    end
                end
            end
        end
        acc.(ts).(pre_or_post).long.length_shuff_acc = long_accuracy;
        acc.(ts).(pre_or_post).short.length_shuff_acc = short_accuracy;
    end

    for ls = ["long", "short"];
    
        disp(ls);
        % now we want to get subpopulations of neurons of fixed size, reshape FR
        % matrix and align trials with same cue value, then train decoder
        neu_ids_subset = all_neu_id(ls == all_lengths);

        neu_ids = unique(neu_ids_subset);
        accuracy = [];
        shuf_accuracy = [];

        % sample 50 neurons at random
        subpop_size = 50;
        for iters = 1:max_iters
            disp("pt3: " + iters);
            inc_idxs = randperm(length(neu_ids));
            for jjj = 1:2
                inc_ids = neu_ids(inc_idxs(1 + (jjj-1)*subpop_size:(jjj)*subpop_size));
                inc_rows = ismember(all_neu_id, inc_ids);

                curr_id = all_neu_id(inc_rows,:);
                curr_cue = all_cue_val(inc_rows,:);
                curr_fr = all_fr(inc_rows,:);
                uids = unique(curr_id);

                ridx = randperm(length(curr_cue));
                curr_fr = curr_fr(ridx,:);
                curr_id = curr_id(ridx,:);
                curr_cue = curr_cue(ridx,:);

                X_fr = zeros(90, length(uids), 100);
                y = zeros(90,1);
                cnt = 1;
                for i = 1:10
                    for j = 1:9
                        for k = 1:length(uids)
                            neu_idx = find(curr_cue == j & curr_id == uids(k));
                            X_fr(cnt, k, :) = curr_fr(neu_idx(i),:);
                        end
                        y(cnt) = j;
                        cnt = cnt + 1;
                    end
                end

                for tps = 1:51
                    X = mean(X_fr(:, :, (tps):(9+tps)), 3); % get fr during cue period

                    k = 10;
                    norm = true;

                    if jjj == 1
                        pre_accuracy(tps, iters) = getKFoldCorrLoss(X, y, k, norm);
                    else
                        post_accuracy(tps, iters) = getKFoldCorrLoss(X, y, k, norm);
                    end
                end
            end
        end
        acc.(ts).pre.(ls).task_shuff_acc = pre_accuracy;
        acc.(ts).post.(ls).task_shuff_acc = post_accuracy;
    end

end

out_file = flag.decoder_output + "corr_accuracy_over_time_new.mat";
save(out_file, 'acc');

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

function loss = getKFoldCorrLoss(X, y, k, norm, nrepeats)
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
