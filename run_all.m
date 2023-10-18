% add paths
addpath(genpath(pwd));

% preprocess the raw data to convert it to model input
process_raw_data("pre");
process_raw_data("post");

% fit models
fit_armax_models("pre");
fit_armax_models("post");

% postprocess model output
nt_pre = postprocess_model_output("pre");
nt_post = postprocess_model_output("post");

% make figures
make_figures;