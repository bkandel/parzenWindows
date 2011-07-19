function prinEigVector = getPrinEigVec(eigVectors, eigValues)

for i = 1:length(eigVectors)
    for j = 1:length(eigVectors{i})
        principal = eigValues{i}{j} == max(sum(eigValues{i}{j})); 
        principal = sum(principal)'; 
        prinVec = eigVectors{i}{j} * principal;
        
        % Only allow eigenvectors within one quadrant %added in for c

        if prinVec(1)<0
            prinVec(1) = -prinVec(1);
        end
        
        prinEigVector{i}{j} =  prinVec; 
    end
end   