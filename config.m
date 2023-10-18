function flag = config()
% model fitting parameters
flag.num_folds = 10;

% model construction parameters
flag.binsize = 50;

flag.intrinsic_order = 10;

flag.seasonal_order = 1;

flag.seasonal_window = 5; % window for moving average in previous trial

% number of positions in wm task
flag.npos = 9;

% number of parameters/time bins for different terms in the model
flag.num_intrinsic = flag.intrinsic_order;
flag.num_seasonal = flag.seasonal_order;
flag.num_cue = 2; 
flag.num_sample = 2; 
flag.num_match = 2; 
flag.num_samplexmatch = 2;

flag.num_bias = 5;

flag.npr = flag.intrinsic_order + flag.seasonal_order + flag.num_cue*(flag.npos-1) + ...
        flag.num_sample*(flag.npos-1) + flag.num_match + flag.num_samplexmatch*(flag.npos-2) + flag.num_bias;    

flag.num_all_tr = flag.num_cue*(flag.npos-1) + ...
        flag.num_sample*(flag.npos-1) + flag.num_match + flag.num_samplexmatch*(flag.npos-2);

% parameters for postprocessing 
flag.triallen = 5;

% parameters for ensuring intrinsic autocorrelation decays and is well fit
% by exponential
flag.int_max_idx = 3;
flag.int_min_r2 = .5;
flag.max_acf_end = .3;

% flag for removing seasonal timesclaes with negative coefficients
flag.rem_negative_seasonal = false;

% define save and load paths
flag.pre_raw_data = 'data/raw_data/pre_training/';
flag.post_raw_data = 'data/raw_data/post_training/';

flag.post_model_input = 'data/model_input/post_training/';
flag.pre_model_input = 'data/model_input/pre_training/';
flag.post_saved_neurons = flag.post_model_input + "savedNeurons_Post.mat";
flag.pre_saved_neurons = flag.pre_model_input + "savedNeurons_Pre.mat";

flag.post_model_output = 'data/model_output/post_training/output.mat';
flag.pre_model_output = 'data/model_output/pre_training/output.mat';

flag.pre_plot_input = 'data/plot_input/pre.mat';
flag.post_plot_input = 'data/plot_input/post.mat';

flag.plot_cache = 'data/plot_cache/';

flag.decoder_output = 'data/decoder_output/';

flag.post_err_model_output = 'data/model_output/post_training/err_output.mat';
flag.post_corr_model_output = 'data/model_output/post_training/corr_output.mat';

flag.post_corr_plot_input = 'data/plot_input/post_corr.mat';
flag.post_err_plot_input = 'data/plot_input/post_err.mat';