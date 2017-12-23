% Sample codes for the task-related component analysis (TRCA)-based steady
% -state visual evoked potential (SSVEP) detection method [1]. The filter
% bank analysis [2] can also be combined to the TRCA-based algorithm.
%
% Dataset (sample.mat):
%   A 40-target SSVEP dataset recorded from a single subject. The stimuli
%   were generated by the joint frequency-phase modulation (JFPM) [3]
%     - Stimulus frequencies    : 8.0 - 15.8 Hz with an interval of 0.2 Hz
%     - Stimulus phases         : 0pi, 0.5pi, 1.0pi, and 1.5pi
%     - # of channels           : 9 (1: Pz, 2: PO5,3:  PO3, 4: POz, 5: PO4,
%                                    6: PO6, 7: O1, 8: Oz, and 9: O2)
%     - # of recording blocks   : 6
%     - Data length of epochs   : 5 [seconds]
%     - Sampling rate           : 250 [Hz]
%
% See also:
%   train_trca.m
%   test_trca.m
%   filterbank.m
%   itr.m
%
% Reference:
%   [1] M. Nakanishi, Y. Wang, X. Chen, Y.-T. Wang, X. Gao, and T.-P. Jung,
%       "Enhancing detection of SSVEPs for a high-speed brain speller using
%        task-related component analysis", 
%       IEEE Trans. Biomed. Eng, 65(1): 104-112, 2018.
%   [2] X. Chen, Y. Wang, S. Gao, T. -P. Jung and X. Gao,
%       "Filter bank canonical correlation analysis for implementing a 
%        high-speed SSVEP-based brain-computer interface",
%       J. Neural Eng., 12: 046008, 2015.
%   [3] X. Chen, Y. Wang, M. Nakanishi, X. Gao, T. -P. Jung, S. Gao,
%       "High-speed spelling with a noninvasive brain-computer interface",
%       Proc. Int. Natl. Acad. Sci. U. S. A, 112(44): E6058-6067, 2015.
%
% Masaki Nakanishi, 22-Dec-2017
% Swartz Center for Computational Neuroscience, Institute for Neural
% Computation, University of California San Diego
% E-mail: masaki@sccn.ucsd.edu

%% Clear workspace
clear all
close all
clc
help tutorial_trca

%% Set paths

addpath('../src');

%% Parameter for analysis (Modify according to your analysis)

% Filename
filename = '../data/sample.mat';

% Data length for target identification [s]
len_gaze_s = 0.5;   

% Visual latency being considered in the analysis [s]
len_delay_s = 0.13;                  

% The number of sub-bands in filter bank analysis
num_fbs = 5;

% 1 -> The ensemble TRCA-based method, 0 -> The TRCA-based method
is_ensemble = 1;

% 100*(1-alpha_ci): confidence intervals
alpha_ci = 0.05;                 

%% Fixed parameter (Modify according to the experimental setting)

% Sampling rate [Hz]
fs = 250;                  

% Duration for gaze shifting [s]
len_shift_s = 0.5;                  

% List of stimulus frequencies
list_freqs = [8:1:15 8.2:1:15.2 8.4:1:15.4 8.6:1:15.6 8.8:1:15.8];
                                        
% The number of stimuli
num_targs = length(list_freqs);    

% Labels of data
labels = [1:1:num_targs];         

%% Preparing useful variables (DONT'T need to modify)

% Data length [samples]
len_gaze_smpl = round(len_gaze_s*fs);           

% Visual latency [samples]
len_delay_smpl = round(len_delay_s*fs);         

% Selection time [s]
len_sel_s = len_gaze_s + len_shift_s;

% Confidence interval
ci = 100*(1-alpha_ci);                  

%% Performing the TRCA-based SSVEP detection algorithm

fprintf('Results of the ensemble TRCA-based method.\n');

% Preparing data
load(filename);
[~, num_chans, ~, num_blocks] = size(eeg);
segment_data = len_delay_smpl+1:len_delay_smpl+len_gaze_smpl;
eeg = eeg(:, :, segment_data, :); 

% Estimate classification performance
for loocv_i = 1:1:num_blocks
    
    % Training stage 
    traindata = eeg;
    traindata(:, :, :, loocv_i) = [];
    model = train_trca(traindata, fs, num_fbs);
    
    % Test stage
    testdata = squeeze(eeg(:, :, :, loocv_i));
    estimated = test_trca(testdata, model, is_ensemble);
    
    % Evaluation 
    is_correct = (estimated==labels);
    accs(loocv_i) = mean(is_correct)*100;
    itrs(loocv_i) = itr(num_targs, mean(is_correct), len_sel_s);
    fprintf('Trial %d: Accuracy = %2.2f%%, ITR = %2.2f bpm\n',...
        loocv_i, accs(loocv_i), itrs(loocv_i));
    
end % loocv_i

% Summarize
[mu, ~, muci, ~] = normfit(accs, alpha_ci);
fprintf('Mean accuracy = %2.2f %% (%2d%% CI: %2.2f - %2.2f %%)\n',...
    mu, ci, muci(1), muci(2));

[mu, ~, muci, ~] = normfit(itrs, alpha_ci);
fprintf('Mean ITR = %2.2f bpm (%2d%% CI: %2.2f - %2.2f bpm)\n\n',...
    mu, ci, muci(1), muci(2));