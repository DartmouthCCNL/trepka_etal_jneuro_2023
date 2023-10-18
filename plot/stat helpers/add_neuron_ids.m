flag = config();
rng(6); % for reproducibility

out_file = flag.decoder_output + "accuracy_over_single_neurons.mat";
load(out_file);

for ts = ["seasonal", "intrinsic"]
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

for pre_or_post = ["post", "pre"];
    for ls = ["long", "short"]
        disp(pre_or_post + " " + ls);
        if ls == "long"
            nt_pre_int = nt_pre(nt_pre{:, timescale} > median(nt_pre{:, timescale}),:);
            nt_post_int = nt_post(nt_post{:, timescale} > median(nt_post{:, timescale}), :);
        else
            nt_pre_int = nt_pre(nt_pre{:, timescale} <= median(nt_pre{:, timescale}),:);
            nt_post_int = nt_post(nt_post{:, timescale} <= median(nt_post{:, timescale}), :);
        end

        % setup paths and load saved neurons
        if pre_or_post == "post"
            loadFolder = flag.post_model_input;
            neuronAddresses = nt_post_int{:, "address"};
        elseif pre_or_post == "pre"
            loadFolder = flag.pre_model_input;
            neuronAddresses = nt_pre_int{:, "address"};
        end
    
        numNeurons = length(neuronAddresses);
    
        all_fr = [];
        all_cue_val = [];
        all_neu_id = [];
    
        % remove any neurons with fewer than 10 examples per condition
        rem_id = [];
    
        for neu_num = 1:numNeurons
            neuron_address = char(neuronAddresses{neu_num});
            load([loadFolder,neuron_address,'.mat'],'MyData'); % load neuronData
    
            flag = config();
            neuronData = constructNeuronData(MyData, flag);
    
            idxes = find(~isnan(neuronData.firingRateMat(1,:)));
            
            cue_val = neuronData.signalValue.cue;
    
            t = tabulate(cue_val);
            rem = false;
            if sum(t(:, 2) < 10) > 0
                rem_id = [rem_id, neuronAddresses{neu_num}];
                rem = true;
            end
            
            if ~rem
                trial_idxes = [];
                for i = 1:9
                    cue_idx = find(cue_val == i);
                    cue_ord = randperm(length(cue_idx));
                    cue_ord = cue_idx(cue_ord(1:10));
                    trial_idxes = [trial_idxes; cue_ord];
                end
    
                cue_val = cue_val(trial_idxes,:);
    
                all_neu_id = [all_neu_id; repmat(string(neuron_address), length(cue_val), 1)];
            end
    
        end
        neu_ids = unique(all_neu_id);
        acc.(ts).(pre_or_post).(ls).neu_ids = neu_ids;
    end
end
end

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