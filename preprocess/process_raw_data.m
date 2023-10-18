% This script transforms the raw data into the model input data format, neuronData.
% The raw data format is described in note.txt and readme.txt in
% data/file_descriptions.
% 
% Copyright 2019 Mehran Spitmaan.
%           2023 Ethan Trepka.

function process_raw_data(pre_or_post)
% saves processed data in data/model_input directory
% input: pre_or_post is "pre" if pre_training and "post" if post_training

disp(['processing raw ', char(pre_or_post), '-training data to construct model input']);

flag = config();

% load the list of neurons, instantiate save and load paths
if pre_or_post == "pre"
    load('data/raw_data/NeuronList_Pre.mat', 'NeuronList_Pre');
    NeuronList = NeuronList_Pre;
    saveFolder = flag.pre_model_input;
    loadFolder = flag.pre_raw_data;    
elseif pre_or_post == "post"
    load('data/raw_data/NeuronList_Post.mat', 'NeuronList');
    saveFolder = flag.post_model_input;
    loadFolder = flag.post_raw_data;
else
    error(pre_or_post + " is not valid, should be 'pre' or 'post'");
end

% get the list of neuron addresses 
allneuronAddress = NeuronList.address;

% get list of neuron areas
allneuronArea = string(zeros(length(allneuronAddress), 1));
allneuronArea(logical(NeuronList{1:end, "Posterior_Dorsal"})) = "posterior dorsal";
allneuronArea(logical(NeuronList{1:end, "Mid_Dorsal"})) = "mid dorsal";
allneuronArea(logical(NeuronList{1:end, "Anterior_Dorsal"})) = "anterior dorsal";
allneuronArea(logical(NeuronList{1:end, "Posterior_Ventral"})) = "posterior ventral";
allneuronArea(logical(NeuronList{1:end, "Anterior_Ventral"})) = "anterior ventral";

% if save directory doesn't exists, create it
if ~exist(saveFolder, 'dir')
    mkdir(saveFolder);
end

% instantiate variables for intersection of correct/error trials
intersectList = {};
intersectListNeuron = {};
intersectFlag = [];

% instantiate variables for saving processed data
savedNeurons.address = {};
savedNeurons.id = [];
savedNeurons.area = string([]);

% instantiate variables for saving missing data for correct trials
corrMissingData.target_noreward.neuronID = {};
corrMissingData.notarget_reward.neuronID = {};
corrMissingData.notarget_noreward.neuronID = {};
corrMissingData.largetrialNum.neuronID = {};
corrMissingData.noFixOnT.neuronID = {};
corrMissingData.noFixOffT.neuronID = {};
corrMissingData.noEOTOnT.neuronID = {};
corrMissingData.duplicate.neuronID = {};
corrMissingData.noIsMatch.neuronID = {};
corrMissingData.noReward.neuronID = {};
corrMissingData.noTS.neuronID = {};
corrMissingData.wrongCueNum.neuronID = {};

corrMissingData.target_noreward.trialNum = {};
corrMissingData.notarget_reward.trialNum = {};
corrMissingData.notarget_noreward.trialNum = {};
corrMissingData.largetrialNum.trialNum = {};
corrMissingData.noFixOnT.trialNum = {};
corrMissingData.duplicate.trialNum = {};
corrMissingData.noFixOffT.trialNum = {};
corrMissingData.noEOTOnT.trialNum = {};
corrMissingData.noIsMatch.trialNum = {};
corrMissingData.noReward.trialNum = {};
corrMissingData.noTS.trialNum = {};
corrMissingData.wrongCueNum.trialNum = {};

% instantiate variables for saving missing data for error trials
errMissingData.target_noreward.neuronID = {};
errMissingData.notarget_reward.neuronID = {};
errMissingData.notarget_noreward.neuronID = {};
errMissingData.largetrialNum.neuronID = {};
errMissingData.duplicate.neuronID = {};
errMissingData.noFixOnT.neuronID = {};
errMissingData.noFixOffT.neuronID = {};
errMissingData.noEOTOnT.neuronID = {};
errMissingData.noIsMatch.neuronID = {};
errMissingData.noReward.neuronID = {};
errMissingData.noTS.neuronID = {};
errMissingData.wrongCueNum.neuronID = {};

errMissingData.target_noreward.trialNum = {};
errMissingData.notarget_reward.trialNum = {};
errMissingData.notarget_noreward.trialNum = {};
errMissingData.largetrialNum.trialNum = {};
errMissingData.duplicate.trialNum = {};
errMissingData.noFixOnT.trialNum = {};
errMissingData.noFixOffT.trialNum = {};
errMissingData.noEOTOnT.trialNum = {};
errMissingData.noIsMatch.trialNum = {};
errMissingData.noReward.trialNum = {};
errMissingData.noTS.trialNum = {};
errMissingData.wrongCueNum.trialNum = {};

% progress indicator length
progress_length = 0;

dup_cnt = 0;
ndups = [];
dup_adds = [];

% iterate over all neuron addresses
for cntII = 1:length(allneuronAddress)
    neuronAdd = char(allneuronAddress(cntII));
    neuronAdd = neuronAdd(1:end-4);
    %testing
    %neuronAdd = 'nin068_1_2202';
    trialAdd = (neuronAdd(1:8));
    
    % load the neuron data and session data
    if ~exist([loadFolder,neuronAdd,'.mat'])
        neuronAdd = lower(neuronAdd);
        if ~exist([loadFolder,neuronAdd,'.mat'])
            % skip neurons that we do not have data for
            continue;
        end
    end
    
    if ~exist([loadFolder,trialAdd,'.mat'])
        trialAdd = lower(trialAdd);
        if ~exist([loadFolder,trialAdd,'.mat'])
            % skip trials that we do not have data for
            continue;
        end
    end
    
    load([loadFolder,neuronAdd,'.mat'])
    load([loadFolder,trialAdd,'.mat'])
    
    % if pre, check if alldata exists, if not create it
    if pre_or_post == "pre"
        if ~isfield(AllData,'trials')
            % skip neurons that we do not have trial data for
            continue;
        end
        
        AllDataTrials = [];
        alldata_fieldnames = fieldnames(AllData.trials);
        for cntF = 1:length(alldata_fieldnames)
            if ~strcmp(alldata_fieldnames{cntF}, 'EyeData') & ~strcmp(alldata_fieldnames{cntF}, 'Reward')
                AllDataTrials.(alldata_fieldnames{cntF}) = [AllData.trials.(alldata_fieldnames{cntF})];
            end
        end
        
        rewStTemp = {AllData.trials.Reward};
        rewStTempF = {};
        for cntIU = 1:length(rewStTemp)
            if ~isempty(rewStTemp{cntIU})
                rewStTempF{end+1} = rewStTemp{cntIU};
            end
        end
        
        AllDataTrialsTot = [];
        for cntIY = 1:length(AllDataTrials.time)
            alldata_fieldnames = fieldnames(AllDataTrials);
            for cntF = 1:length(alldata_fieldnames)
                AllDataTrialsTot(cntIY).(alldata_fieldnames{cntF}) = AllDataTrials.(alldata_fieldnames{cntF})(cntIY);
            end
            
            AllDataTrialsTot(cntIY).('Reward') = rewStTempF{cntIY};
        end
        
        
        AllData.trials = AllDataTrialsTot;
    end
    

    cntTotal = 0;
    MyData = [];
    [MyData, corrMissingData, trialData_corr, cntTotal, skipFlag, duplicateFlag] = compute_mydata(MatData, AllData, MyData, corrMissingData, cntTotal, neuronAdd);
    if skipFlag
        corrMissingData.wrongCueNum.neuronID{end+1} = neuronAdd;
        corrMissingData.wrongCueNum.trialNum = {1};
        continue;
    end
    if duplicateFlag
        corrMissingData.duplicate.neuronID{end+1} = neuronAdd;
        corrMissingData.duplicate.trialNum = {1};
    end
    % if pre_or_post is post, repeat the same process for error trials 
    % there are no pre error trials
    if pre_or_post == "post"
        neuronAdd = char(allneuronAddress(cntII));
        neuronAdd = neuronAdd(1:end-4);
        trialAdd = (neuronAdd(1:8));

        if ~exist([loadFolder,neuronAdd,'_err.mat'])
            neuronAdd = lower(neuronAdd);
            if ~exist([loadFolder,neuronAdd,'_err.mat'])
                continue;
            end
        end

        if ~exist([loadFolder,trialAdd,'.mat'])
            trialAdd = lower(trialAdd);
            if ~exist([loadFolder,trialAdd,'.mat'])
                continue;
            end
        end

        load([loadFolder,neuronAdd,'_err.mat'])
        load([loadFolder,trialAdd,'.mat'])

        trialData_err = [];

        [MyData, errMissingData, trialData_err, cntTotal, skipFlag, duplicateFlagErr] = compute_mydata(MatData, AllData, MyData, errMissingData, cntTotal, neuronAdd);
        if skipFlag
            errMissingData.wrongCueNum.neuronID{end+1} = neuronAdd;
            errMissingData.wrongCueNum.trialNum = {1};
        end
        intersectFlag(end+1) = ~isempty(intersect(trialData_err,trialData_corr));
        
        if duplicateFlagErr
            errMissingData.duplicate.neuronID{end+1} = neuronAdd;
            errMissingData.duplicate.trialNum = {1};
        end
        if intersectFlag(end)
            intersectList{end+1} = intersect(trialData_err,trialData_corr);
            intersectListNeuron{end+1} = neuronAdd;
        end
    end
    
    % sort data by trial and save output
    MyData.totalN = cntTotal;
    
    % for each trial
    for cntT = 1:length(MyData.trialNum)
        % count number of spikes between cue onset and sample onset, and
        % divide by time between cue and sample onset
        MyData.CueProfile(cntT) = sum((MyData.TS{cntT}>=(MyData.Cue_onT(cntT))) & (MyData.TS{cntT}<=(MyData.Sample_onT(cntT)))) / (MyData.Sample_onT(cntT) - MyData.Cue_onT(cntT));
        % count number of spikes between sample onset and 2 s after sample onset and 
        % divide by 2 s 
        MyData.SampleProfile(cntT) = sum((MyData.TS{cntT}>=MyData.Sample_onT(cntT)) & (MyData.TS{cntT}<MyData.Sample_onT(cntT)+2)) / 2;
    end
    
    % grid of values: 
    % 4  3  2
    % 5  9  1
    % 6  7  8
    %
    % sample location = cue location, unless ~isMatch, in which case
    % sample location = cue location + 4 if cue location < 5
    % sample location = cue location - 4 if cue location >= 5
    % note that when cue location is the center and ~ismatch, 
    % the sample value could either 1 or 5, but it is not stored so we 
    % default to 5
    MyData.Sample_signal = MyData.Cue_signal;
        
    MyData.Sample_signal(MyData.Cue_signal<5 & ~MyData.isMatch) = MyData.Cue_signal(MyData.Cue_signal<5 & ~MyData.isMatch)+4;
    MyData.Sample_signal(MyData.Cue_signal>=5 & ~MyData.isMatch) = MyData.Cue_signal(MyData.Cue_signal>=5 & ~MyData.isMatch)-4;
    
    % compute average response to cue and sample in each of the nine
    % locations
    for cntL = 1:9
        MyData.CueProfile_avg(cntL) = nanmean(MyData.CueProfile(MyData.Cue_signal==cntL));
        MyData.SampleProfile_avg(cntL) = nanmean(MyData.SampleProfile(MyData.Sample_signal==cntL));
    end
    
    % sort these to construct binary signal
    [~, I] = sort(MyData.CueProfile_avg);
    MyData.Cue_signal_new.firstHalf = find(MyData.CueProfile_avg < nanmean(MyData.CueProfile_avg));
    MyData.Cue_signal_new.secondHalf = setdiff(1:9, MyData.Cue_signal_new.firstHalf);
    
    [~, I] = sort(MyData.SampleProfile_avg);
    MyData.Sample_signal_new.firstHalf = find(MyData.SampleProfile_avg < nanmean(MyData.SampleProfile_avg));
    MyData.Sample_signal_new.secondHalf = setdiff(1:9, MyData.Sample_signal_new.firstHalf);
    
    % instantiate new binary cue and sample signals
    MyData.Cue_signal_new.total = zeros(1,length(MyData.Cue_signal));
    MyData.Sample_signal_new.total = zeros(1,length(MyData.Sample_signal));
   
    % if cue signal is in secondhalf (most responsive), set cue signal new to 1
    for cntL = MyData.Cue_signal_new.secondHalf
        MyData.Cue_signal_new.total = MyData.Cue_signal_new.total | MyData.Cue_signal==cntL;
    end
    
    % if sample signal is in secondhalf (most responsive), set sample signal new to 1
    for cntL = MyData.Sample_signal_new.secondHalf
        MyData.Sample_signal_new.total = MyData.Sample_signal_new.total | MyData.Sample_signal==cntL;
    end
    
    % choice is xor of match and reward signals
    MyData.Choice_signal = ~xor(MyData.isMatch,MyData.rewarded);
    
    % order data by trial number
    if cntTotal>0
        [~, I] = sort(MyData.trialNum);
        MyData.sorted.TS = {MyData.TS{I}};
        MyData.sorted.TS = [MyData.sorted.TS{:}];
        MyData.sorted.trialNum = MyData.trialNum(I);
        MyData.sorted.Cue_signal = MyData.Cue_signal(I);
        MyData.sorted.Sample_signal = MyData.Sample_signal(I);
        
        MyData.sorted.CueProfile = MyData.CueProfile(I);
        MyData.sorted.SampleProfile = MyData.SampleProfile(I);
        
        MyData.sorted.Cue_signal_new = MyData.Cue_signal_new.total(I);
        MyData.sorted.Sample_signal_new = MyData.Sample_signal_new.total(I);
        
        MyData.sorted.Cue_onT = MyData.Cue_onT(I);
        MyData.sorted.Sample_onT = MyData.Sample_onT(I);
        MyData.sorted.Target_onT = MyData.Target_onT(I);
        MyData.sorted.Reward_onT = MyData.Reward_onT(I);
        MyData.sorted.Fix_onT = MyData.Fix_onT(I);
        MyData.sorted.Fix_offT = MyData.Fix_offT(I);
        MyData.sorted.EndofTrialtime = MyData.EndofTrialtime(I);
        MyData.sorted.isMatch = MyData.isMatch(I);
        MyData.sorted.rewarded = MyData.rewarded(I);
        MyData.sorted.Choice_signal = MyData.Choice_signal(I);
        
        MyData.sorted.idx = I;
        
        savedNeurons.address{end+1} = lower(neuronAdd);
        savedNeurons.id(end+1) = cntII;
        savedNeurons.area(end+1) = allneuronArea(cntII);

        if length(MyData.trialNum) ~= length(unique(MyData.trialNum))
            dup_cnt = dup_cnt + 1;
            ndups = [ndups; length(MyData.trialNum)-length(unique(MyData.trialNum))];
            dup_adds = [dup_adds; neuronAdd];
        end
        save([saveFolder,lower(neuronAdd)],'MyData');
    end
    
    fprintf(repmat('\b',1,progress_length))
    progress_length = fprintf(['progress: ',num2str(cntII), ' | ',num2str(length(allneuronAddress)), ' | ', num2str(100*round(cntII/length(allneuronAddress),2)),'%%']);
end

disp(dup_cnt);
disp(mean(ndups));
disp(dup_adds);

if pre_or_post == "post"
    save(flag.post_saved_neurons,'savedNeurons');
elseif pre_or_post == "pre"
    save(flag.pre_saved_neurons,'savedNeurons');
end

fieldNames = fieldnames(corrMissingData);
for cntF = 1:length(fieldNames)
    corrMissingData.(fieldNames{cntF}).uniqueNeuronID = unique(corrMissingData.(fieldNames{cntF}).neuronID);
    errMissingData.(fieldNames{cntF}).uniqueNeuronID = unique(errMissingData.(fieldNames{cntF}).neuronID);
end

if pre_or_post == "post"
    save([saveFolder,'missingInfo_Post.mat'],'corrMissingData','errMissingData','intersectList', 'intersectListNeuron');
elseif pre_or_post == "pre"
    save([saveFolder,'missingInfo_Pre.mat'],'corrMissingData','errMissingData','intersectList', 'intersectListNeuron');
end

reportMissingData(corrMissingData, 'correct');
reportMissingData(errMissingData, 'error');

disp('-------------done!----------------');

end

function reportMissingData(missingData, missType)
    fprintf('\n\n');
    disp("---------------------Generating missing data report for " + missType + " trials...-----------------------")
    fields = fieldnames(missingData);
    for field = 1:length(fields)
        uq_neu = length(unique(missingData.(fields{field}).neuronID));
        uq_trials = length((missingData.(fields{field}).trialNum + ""));
        disp(string(uq_neu) + " neurons and " + string(uq_trials) + " trials had missing data for " + fields{field});
    end
end

function [MyData, missingData, trialData, cntTotal, skipFlag, duplicateFlag] = compute_mydata(MatData, AllData, MyData, missingData, cntTotal, neuronAdd)
trialData = [];
skipFlag = false;
duplicateFlag = false;
if ~isempty(MatData)
    % iterate over classes of stimulus (should be 9, if not we'll skip the neuron (shape task)) 
    if size(MatData.class, 2) ~= 9
        skipFlag = true;
    end
    
    for cntC = 1:size(MatData.class,2)
        % iterate over trials for each class
        init_t = -1;
        for cntT = 1:size(MatData.class(cntC).ntr,2)
            if isfield(MatData.class(cntC).ntr(cntT),'trialnum')
                trialNum =  MatData.class(cntC).ntr(cntT).trialnum;
            elseif isfield(MatData.class(cntC).ntr(cntT),'Trial_Num')
                trialNum =  MatData.class(cntC).ntr(cntT).Trial_Num;
            else
                continue;
            end

            % occasionally, session restarted and additional trials were
            % appended to original trials
            if trialNum < init_t
                duplicateFlag = true;
                break;
            end
            init_t = trialNum;
            
            if trialNum > length(AllData.trials)
                missingData.largetrialNum.neuronID{end+1} = neuronAdd;
                missingData.largetrialNum.trialNum{end+1} = trialNum;
                continue;
            end
            
            % Set target onset time to 'Target_onT', or if that doesn't
            % exist, Reward_onT-1
            if isfield(MatData.class(cntC).ntr(cntT),'Target_onT') && ~isempty(MatData.class(cntC).ntr(cntT).Target_onT)
                Target_onT = MatData.class(cntC).ntr(cntT).Target_onT + AllData.trials(trialNum).time;
            elseif isfield(MatData.class(cntC).ntr(cntT),'Reward_onT') && ~isempty(MatData.class(cntC).ntr(cntT).Reward_onT)
                Target_onT = MatData.class(cntC).ntr(cntT).Reward_onT - 1 + AllData.trials(trialNum).time;
                missingData.notarget_reward.neuronID{end+1} = neuronAdd;
                missingData.notarget_reward.trialNum{end+1} = trialNum;
            else
                missingData.notarget_noreward.neuronID{end+1} = neuronAdd;
                missingData.notarget_noreward.trialNum{end+1} = trialNum;
                continue;
            end
            
            % Set reward onset time to 'Reward_onT', or if that doesn't
            % exist, Target_onT+1
            if isfield(MatData.class(cntC).ntr(cntT),'Reward_onT') && ~isempty(MatData.class(cntC).ntr(cntT).Reward_onT)
                Reward_onT = MatData.class(cntC).ntr(cntT).Reward_onT + AllData.trials(trialNum).time;
            elseif isfield(MatData.class(cntC).ntr(cntT),'Target_onT') && ~isempty(MatData.class(cntC).ntr(cntT).Target_onT)
                Reward_onT = MatData.class(cntC).ntr(cntT).Target_onT + 1 + AllData.trials(trialNum).time;
                missingData.target_noreward.neuronID{end+1} = neuronAdd;
                missingData.target_noreward.trialNum{end+1} = trialNum;
            else
                continue;
            end
            
            trialData(end+1) = trialNum;
            
            % increment trial counter
            cntTotal = cntTotal + 1;

            % set spike times for current trial
            % equal to spike time from cue onset + cue onset from
            % 'trial start' + trial start time
            if isfield(MatData.class(cntC).ntr(cntT),'TS')
                MyData.TS{cntTotal} = MatData.class(cntC).ntr(cntT).TS + AllData.trials(trialNum).time; % MatData.class(cntC).ntr(cntT).Cue_onT 
            else
                missingData.noTS.neuronID{end+1} = neuronAdd;
                missingData.noTS.trialNum{end+1} = trialNum;
            end
            MyData.trialNum(cntTotal) = trialNum;            

            %%% assertions to check that alignment of spike data to
            %%% cue/sample periods is correct
            if isfield(MatData.class(cntC).ntr(cntT), 'TS')
                ts = MatData.class(cntC).ntr(cntT).TS;
                cue_on =  MatData.class(cntC).ntr(cntT).Cue_onT;
                sample_on =  MatData.class(cntC).ntr(cntT).Sample_onT;

                if numel(ts) > 0
                    % check that firing rate computed in cue period is
                    % matches stored firing rate
                    cue_fr_cond = [sum(ts <= cue_on & ts > cue_on-1),sum(ts < cue_on & ts > cue_on-1),sum(ts < cue_on & ts >= cue_on-1),sum(ts <= cue_on & ts >= cue_on-1)];
                    if ~isempty(MatData.class(cntC).ntr(cntT).fix)
                        assert(ismember(MatData.class(cntC).ntr(cntT).fix, cue_fr_cond));
                    end
                    
                    % check that firing rate computed in first delay period
                    % matches stored firing rate
                    delay_fr_cond = [sum(ts > cue_on+.5 & ts< cue_on+2), sum(ts > cue_on+.5 & ts<= cue_on+2), sum(ts >= cue_on+.5 & ts< cue_on+2), sum(ts >= cue_on+.5 & ts<= cue_on+2)]/1.5;                    
                    delay_time = (MatData.class(cntC).ntr(cntT).Sample_onT - MatData.class(cntC).ntr(cntT).Cue_onT - .5);
                    delay_fr_cond1 = [sum(ts > cue_on+.5 & ts< sample_on), sum(ts > cue_on+.5 & ts<= sample_on), sum(ts >= cue_on+.5 & ts< sample_on), sum(ts >= cue_on+.5 & ts<= sample_on)]/delay_time;
                    delay_fr_cond = [delay_fr_cond, delay_fr_cond1];
                    if ~isempty(MatData.class(cntC).ntr(cntT).cuedelay)
                        assert(ismember(MatData.class(cntC).ntr(cntT).cuedelay, delay_fr_cond));
                    end
                end
            end

            % set cue signal to the 'class count'
            MyData.Cue_signal(cntTotal) = cntC;
            
            % set cue onset time and sample onset time
            MyData.Cue_onT(cntTotal) = MatData.class(cntC).ntr(cntT).Cue_onT + AllData.trials(trialNum).time;
            MyData.Sample_onT(cntTotal) = MatData.class(cntC).ntr(cntT).Sample_onT + AllData.trials(trialNum).time;
            
            % set target onset time and reward onset time
            MyData.Target_onT(cntTotal) = Target_onT;
            MyData.Reward_onT(cntTotal) = Reward_onT;
            
            % set fixation onset and offset time
            if isfield(AllData.trials(trialNum),'FixOn') && ~isempty(AllData.trials(trialNum).FixOn)
                MyData.Fix_onT(cntTotal) = AllData.trials(trialNum).FixOn;
            else
                MyData.Fix_onT(cntTotal) = AllData.trials(trialNum).time;
                missingData.noFixOnT.neuronID{end+1} = neuronAdd;
                missingData.noFixOnT.trialNum{end+1} = trialNum;
            end
            
            if isfield(AllData.trials(trialNum),'FixOff') && ~isempty(AllData.trials(trialNum).FixOff)
                MyData.Fix_offT(cntTotal) = AllData.trials(trialNum).FixOff;
            else
                MyData.Fix_offT(cntTotal) = AllData.trials(trialNum).time;
                missingData.noFixOffT.neuronID{end+1} = neuronAdd;
                missingData.noFixOffT.trialNum{end+1} = trialNum;
            end
            
            % set end of trial time
            if isfield(AllData.trials(trialNum),'EndofTrialtime') && ~isempty(AllData.trials(trialNum).EndofTrialtime)
                MyData.EndofTrialtime(cntTotal) = AllData.trials(trialNum).EndofTrialtime;
            else
                if trialNum < length(AllData.trials)
                    MyData.EndofTrialtime(cntTotal) = AllData.trials(trialNum+1).time;
                else
                    MyData.EndofTrialtime(cntTotal) = Reward_onT + 1;
                end
                missingData.noEOTOnT.neuronID{end+1} = neuronAdd;
                missingData.noEOTOnT.trialNum{end+1} = trialNum;
            end
            
            % set isMatch, = 1 if cue and sample position matched, 0 if
            % cue and sample position did not match
            if isfield(MatData.class(cntC).ntr(cntT),'IsMatch') && ~isempty(MatData.class(cntC).ntr(cntT).IsMatch)
                MyData.isMatch(cntTotal) = MatData.class(cntC).ntr(cntT).IsMatch;
            else
                MyData.isMatch(cntTotal) = 0;
                missingData.noIsMatch.neuronID{end+1} = neuronAdd;
                missingData.noIsMatch.trialNum{end+1} = trialNum;
            end
            
            % set isReward = 1 if .Reward is 'Yes'
            if isfield(AllData.trials(trialNum),'Reward') && ~isempty(AllData.trials(trialNum).Reward)
                MyData.rewarded(cntTotal) =  strcmp(AllData.trials(trialNum).Reward,'Yes');
            else
                MyData.rewarded(cntTotal) = 0;
                missingData.noReward.neuronID{end+1} = neuronAdd;
                missingData.noReward.trialNum{end+1} = trialNum;
            end
        end
    end
end
end