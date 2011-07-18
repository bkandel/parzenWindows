function [eigenVectors, eigenValues, tensorMatrix] = dti_load_brainMask(maskName,imageName)

% This mfile is intended to load the images given to us to test the various
% distances, calculate the distance between test voxels and the test
% tracts, and see how the various distances compare. 


%% Load Images and Tracts
niiCcTemplate=load_nii(maskName);
nii=load_nii(imageName);
niiCcMask = niiCcTemplate.img > 0; % Retrieve template

% Retrieve components of image that are within labeled tract.
for i = 1:6
    niiImage{i} = nii.img(:,:,:,1,i);
    niiImageFil{i} = niiImage{i}(niiCcMask); 
    % Delete voxels that have zero values, corresponding to voxels that are
    % actually outside the brain. 
    niiImageFil{i}(niiImageFil{i}==0)=[];  
end 

% Recreate DTI tensors
for j = 1:length(niiImageFil{1}) %which niiImageFil cell we use doesn't matter
    for k = 1:9
        tensor{j}(1,1) = niiImageFil{1}(j); 
        tensor{j}(2,1) = niiImageFil{2}(j); 
        tensor{j}(3,1) = niiImageFil{4}(j); 
        tensor{j}(1,2) = niiImageFil{2}(j); 
        tensor{j}(2,2) = niiImageFil{3}(j); 
        tensor{j}(3,2) = niiImageFil{5}(j); 
        tensor{j}(1,3) = niiImageFil{4}(j); 
        tensor{j}(2,3) = niiImageFil{5}(j);
        tensor{j}(3,3) = niiImageFil{6}(j); 
    end
end

% Generate eigenvalues and eigenvectors
for i = 1:length(tensor)
    [eigenVectors{i}, eigenValues{i} ] = eig(tensor{i}); 
end

% Generate a matrix of all the tensors
for i = 1:length(niiImageFil{1})
    for j = 1:6
        tensorMatrix(i, j) = niiImageFil{j}(i); 
    end
end


