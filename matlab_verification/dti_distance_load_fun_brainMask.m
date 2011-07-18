% Load tract images and save them in Matlab format. 
function [eigVectors, eigValues, Tensor, Names] = dti_distance_load_fun_brainMask(folder)

% This function is intended to load the different tracts in a given scan.
% The only input argument is the folder in which the scans are located; the
% function assumes that the only members of the folder are the scans.
% There are ten label masks, and one base scan.  There are two scans (and
% so 22 total files) in each folder, corresponding to two scans per
% patient. 

cd(folder); 
fileNames = ls; 
fileNames(1,:) = []; 
fileNames(1,:) = [];
fileNameCell = cellstr(fileNames); 
clear fileNames; 
fileNames = fileNameCell; 



%% Load Images and Tracts
%{
[ccEigVectors, ccEigValues, ccTensorMat] = dti_load('atlas_construction\adult_template\final_seg\tsa\cc\cc_binary.nii', ...
    'home\cbrun\TSA\atlas_construction\adult_template\mean_diffeomorphic_initial6.nii'); 

[cc2EigVectors, cc2EigValues, cc2TensorMat] = dti_load('atlas_construction\adult_template\final_seg\tsa\cc_2\cc_binary.nii',...
    'home\cbrun\TSA\atlas_construction\adult_template\mean_diffeomorphic_initial6.nii');

[cc3EigVectors, ccc3EigValues, c3TensorMat] = dti_load('atlas_construction\adult_template\final_seg\tsa\cc_3\cc_binary.nii',...
    'home\cbrun\TSA\atlas_construction\adult_template\mean_diffeomorphic_initial6.nii');

[cc4EigVectors, cc4EigValues, cc4TensorMat] = dti_load('atlas_construction\adult_template\final_seg\tsa\cc_4\cc_binary.nii',...
    'home\cbrun\TSA\atlas_construction\adult_template\mean_diffeomorphic_initial6.nii');

[cc5EigVectors, cc5EigValues,cc5TensorMat] = dti_load('atlas_construction\adult_template\final_seg\tsa\cc_5\cc_binary.nii',...
    'home\cbrun\TSA\atlas_construction\adult_template\mean_diffeomorphic_initial6.nii');

[cc6EigVectors, cc6EigValues, cc6TensorMat] = dti_load('atlas_construction\adult_template\final_seg\tsa\cc_6\cc_binary.nii',...
    'home\cbrun\TSA\atlas_construction\adult_template\mean_diffeomorphic_initial6.nii');

[cc7EigVectors, cc7EigValues, cc7TensorMat] = dti_load('atlas_construction\adult_template\final_seg\tsa\cc_7\cc_binary.nii',...
    'home\cbrun\TSA\atlas_construction\adult_template\mean_diffeomorphic_initial6.nii');
%}
h = waitbar(0, 'Loading DTI Data'); 
for i = 1:10
    [eigVectors{i}, eigValues{i}, Tensor{i}] = dti_load_brainMask(fileNames{i+1}, ...
        fileNames{1}); 
    waitbar(i/20)
end
for i = 11:20
     [eigVectors{i}, eigValues{i}, Tensor{i}] = dti_load_brainMask(fileNames{i+2}, ...
        fileNames{12}); 
    waitbar(i/20)
end

Names{1} = 'Left CST';
Names{2} = 'Left IFO';
Names{3} = 'Left ILF';
Names{4} = 'Left SLF';
Names{5} = 'Left Uncinate';
Names{6} = 'Right CST';
Names{7} = 'Right IFO';
Names{8} = 'Right ILF';
Names{9} = 'Right SLF';
Names{10} = 'Right Uncinate';

Names{11} = 'Left CST';
Names{12} = 'Left IFO';
Names{13} = 'Left ILF';
Names{14} = 'Left SLF';
Names{15} = 'Left Uncinate';
Names{16} = 'Right CST';
Names{17} = 'Right IFO';
Names{18} = 'Right ILF';
Names{19} = 'Right SLF';
Names{20} = 'Right Uncinate';

cd ..\..

close(h)


