% compute fano_factor during cue-delay period

function nt = add_fano_factor(nt, pre_or_post)
fano_factor = [];
flag = config();
for i = 1:height(nt)
    nt_single = nt(i,:);
    neuron_address = char(nt_single.address);
    if pre_or_post == "pre"
        loadFolder = flag.pre_model_input;
    else
        loadFolder = flag.post_model_input;
    end
    load([loadFolder,neuron_address,'.mat'],'MyData'); % load neuronData
    
    flag = config();
    neuronData = constructNeuronData(MyData, flag);
    fr = neuronData.firingRateMat(:, 100:200);
    fr = (fr(:, 31:60))./20; % 2 s cue delay period period, previously, 31:60
    fr = (fr(:, 1:2:end) + fr(:, 2:2:end))/2;
    cue_vals = unique(neuronData.signalValue.cue);
    vars = [];
    means = [];
    ffs = [];
    for i = 1:length(cue_vals)
        cue_val = cue_vals(i);
        fr_cue = fr(neuronData.signalValue.cue == cue_val, :);
        vars = [vars; var(fr_cue, 0, 1)];
        means = [means; mean(fr_cue, 1)];
        ffs = [ffs; lscov(means, vars)];
    end
    fano_factor = [fano_factor; (ffs)];
end
nt.fano_factor = fano_factor;
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