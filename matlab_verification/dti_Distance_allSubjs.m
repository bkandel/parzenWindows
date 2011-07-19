% This mfile uses the function "Distance 110504KirbyBrainMaskBenEFun.m" to
% calculate the parametric (Mahalanobis and MCD) and nonparametric norm

clear; close all; clc

folderNames{1} = '~/Dropbox/MVSEG/dti_distance_project/kirby/subj_113'; 
subjName{1} = 'subj_113';

% folderNames{2} = 'kirby\subj_127'; 
% subjName{2} = 'subj_127';
% 
% folderNames{3} = 'kirby\subj_142'; 
% subjName{3} = 'subj_142'; 

h = waitbar(0, 'Subject Progress'); 
tic
for i = 1:length(folderNames)
    dti_distance(folderNames{i}, subjName{i}); 
    waitbar(i / length(folderNames)); 
end
toc
close(h)