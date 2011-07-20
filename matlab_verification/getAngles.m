function [angles, lambda] = getAngles(eigValues, prinEigVector)

for i = 1:length(eigValues)
    for j = 1:length(eigValues{i})
        z=prinEigVector{i}{j}(3);
        y=prinEigVector{i}{j}(2);
        x=prinEigVector{i}{j}(1);
        
        angles{i}(j,1) = acos(z); % \ ...
        
        if(abs(x)+abs(y)<10^-9)
            angles{i}(j,2)=0;
        else
            if (y==0)
                if (x>0)
                    angles{i}(j,2)=0;
                else
                    angles{i}(j,2)=pi;
                end
            elseif (x==0)
                    if (y>0)
                        angles{i}(j,2)=pi/2;
                    else
                        angles{i}(j,2)=1.5*pi;
                    end
                
            elseif (x>0&&y>0)
                    angles{i}(j,2)=atan(y/x);
                
            elseif (x<0&&y>0)
                    angles{i}(j,2)=pi+atan(y/x);
                
            elseif (x<0&&y<0)
                    angles{i}(j,2)=pi+atan(y/x);
                
            else
                    angles{i}(j,2)=2*pi+atan(y/x);
            end
        end

        
        prinEigVectorSort = sort(abs(eigValues{i}{j}),'descend'); 
        
        lambda{i}(j,1) = prinEigVectorSort(1); 
        lambda{i}(j,2) = prinEigVectorSort(4); 
    end
    %Get only one quadrant of the sphere:  When x is greater than 0, and z
    %is greater than zero.  This will give phi ranging from -phi\2 to
    %phi\2, and psi from 0 to phi\2. 
    %angles{i}(angles{i}(1)<0) = -angles{i}(angles{i}(1)<0);
    %angles{i}(angles{i}(3)<0) = -angles{i}(angles{i}(3)<0); 
end