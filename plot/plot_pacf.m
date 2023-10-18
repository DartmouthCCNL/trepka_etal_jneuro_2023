% visualize PACF of the data
flag = config();

if ~exist(flag.plot_cache, 'dir')
    mkdir(flag.plot_cache);
end

out_file = flag.plot_cache + "pacf.mat";

sem = @(x) nanstd(x)./sqrt(size(x, 1));

if exist(out_file, 'file')
    load(out_file);
else
    all_cf = struct;
    
    
    for pre_or_post = ["pre", "post"];
        all_cf.(pre_or_post) = struct;
    
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
    
        all_results = {};
    
        for comp = ["intrinsic", "seasonal"];
            all_cf.(pre_or_post).(comp) = struct;
            all_cf.(pre_or_post).(comp).cf = [];
            all_cf.(pre_or_post).(comp).bd = [];
        end
    
        % change to parfor for cluster
        for neu_num = 1:numNeurons
            neuron_address = char(neuronAddresses{neu_num});
            load([loadFolder,neuron_address,'.mat'],'MyData'); % load neuronData
    
            flag = config();
            neuronData = constructNeuronData(MyData, flag);
    
            ntr = size(neuronData.firingRateMat, 1);
            nbn = size(neuronData.firingRateMat, 2);
    
            % subtract time mean from firing rate mat
            fr =  neuronData.firingRateMat;
            fr_ctr = neuronData.firingRateMat - repmat(neuronData.firingRateMatMean, ntr, 1);
    
            for comp = ["intrinsic", "seasonal"];
                if comp == "intrinsic"
                    y = reshape(fr_ctr', [], 1);
                else
                    y = reshape(fr_ctr, [], 1);
                end
                ex = isnan(y);
                y(ex) = [];
    
                if comp == "intrinsic"
                    nl = 20;
                else
                    nl = 10;
                end
                [pcf, lags, bounds] = parcorr(y, NumLags=nl);
    
                all_cf.(pre_or_post).(comp).cf = [all_cf.(pre_or_post).(comp).cf; pcf'];
                all_cf.(pre_or_post).(comp).bd = [all_cf.(pre_or_post).(comp).bd; bounds'];
            end
    
            disp("progress: " + num2str(neu_num) + "/" + num2str(numNeurons));
        end
    end
    save(out_file, 'all_cf');
end

figure('position', [488   107   808   655]);
cnt = 1;
for comp = ["intrinsic", "seasonal"];
    for pre_or_post = ["pre", "post"];
        subplot(2,2,cnt);
        cnt = cnt + 1;
        y = nanmean(all_cf.(pre_or_post).(comp).cf(:, 2:end)./all_cf.(pre_or_post).(comp).bd(:, 1),1);
        y_sem = sem(all_cf.(pre_or_post).(comp).cf(:, 2:end)./all_cf.(pre_or_post).(comp).bd(:, 1));

        bound = 1; %nanmean(all_cf.(pre_or_post).(comp).bd(:, 1));
        if comp == "intrinsic"
            x = flip(-flag.binsize*length(y):flag.binsize:-flag.binsize);
            xlab = "\tau (ms)";
            xl = [-1000, 0];
            yl = [-0.05, 10];
        else
            x = flip(-length(y):1:-1);
            xlab = "\tau (trials)";
            xl = [-length(y), 0];
            yl = [-0.05, 2];
        end
        plot(x,y, 'k.-', 'linewidth', 2); hold on;

        %errorbar(x, y, y_sem, 'Color', 'k', 'linewidth', 2); hold on;
        shaded_error_bar(x, y, y_sem);
        yline(bound, 'k--', 'linewidth', 2);
        ylabel("norm. " + comp + " PACF");
        xlabel(xlab);
        xlim(xl);
        ylim(yl);
        title(pre_or_post + "-training");
        set ( gca, 'xdir', 'reverse' )
        set_axis_defaults();
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