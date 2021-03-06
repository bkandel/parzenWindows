% This mfile uses the function "Distance 110504KirbyBrainMaskBenEFun.m" to
% calculate the parametric (Mahalanobis and MCD) and nonparametric norm

clear; close all; clc

folderNames{1} = '~/Dropbox/MVSEG/dti_distance_project/kirby/subj_113'; 
subjName{1} = 'subj_113';
sigma = 3; 
numBins = 64; 

% folderNames{2} = 'kirby\subj_127'; 
% subjName{2} = 'subj_127';
% 
% folderNames{3} = 'kirby\subj_142'; 
% subjName{3} = 'subj_142'; 

progressbar('Subject Progress', 'Loading DTI Data', 'Probability Calculations'); 
tic
for i = 1:length(folderNames)
    dti_hists(folderNames{i}, subjName{i}, sigma, numBins); 
    progressbar(i / length(folderNames), [], []); 
end
toc
