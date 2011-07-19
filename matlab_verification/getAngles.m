function [angles, lambda] = getAngles(eigVectors, prinEigVector)

for i = 1:length(eigVectors)
    for j = 1:length(eigVectors{i})
        angles{i}(j,1) = atand(prinEigVector{i}{j}(2) / ...
            prinEigVector{i}{j}(1)); % theta(horizontal)
        angles{i}(j,2) = asind(prinEigVector{i}{j}(3)); % \ ...
        
        prinEigVectorSort = sort(abs(prinEigVector{i}{j}),'descend'); 
        
        lambda{i}(j,1) = prinEigVectorSort(1); 
        lambda{i}(j,2) = prinEigVectorSort(2); 
    end
    %Get only one quadrant of the sphere:  When x is greater than 0, and z
    %is greater than zero.  This will give phi ranging from -phi\2 to
    %phi\2, and psi from 0 to phi\2. 
    %angles{i}(angles{i}(1)<0) = -angles{i}(angles{i}(1)<0);
    %angles{i}(angles{i}(3)<0) = -angles{i}(angles{i}(3)<0); 
end