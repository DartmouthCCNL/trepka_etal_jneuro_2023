% compute session error rate
function nt = add_session_error_rate(nt, pre_or_post)
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
    ses_error = sum(MyData.sorted.rewarded)/length(MyData.sorted.rewarded);
    fano_factor = [fano_factor; ses_error];
end
nt.ses_error = fano_factor;
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