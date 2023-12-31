# trepka_etal_jneuro_2023
## Overview
This repository contains code for fitting AR models to estimate timescales and for generating the figures for the following paper:

Trepka et al. (2023) *Training-dependent gradients of timescales of neural dynamics in the primate prefrontal cortex and their contributions to working memory.* The Journal of Neuroscience. 
## Data format
We include intermediate data files in the `data/plot_input` directory that can be used for replicating most figures in the paper. The intermediate files contain tables of neurons along with model parameters estimated for each neuron. 
## Reproducing figures
To reproduce all figures, clone the repo and run `make_figures.m`, `plot_corr_vs_err_timescales.m`, `plot_decoder_accuracy_over_time.m` and `plot_decoder_accuracy_over_neurons.m`.
## Reproducing all analyses
To reproduce all analyses from raw data, run the analysis scripts in the order illustrated in `run_all.m`.
## Code organization 
The remaining scripts in the main directory are organized as follows:
* config.m contains constants and parameters for model fitting and postprocessing data
* preprocess/ contains functions for preprocessing the raw data
* model/ contains functions for fitting the AR model
* postprocess/ contains functions for postprocessing the model output
* plot/ contains helper functions for plotting figures
* decoder/ contains functions for training and testing decoders
* revisions/ contains functions related to additional analyses associated with the revisions of the paper

