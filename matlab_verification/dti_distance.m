% This mfile is intended to load the images given to us to test the various
% distances, calculate the distance between test voxels and the test
% tracts, and see how the various distances compare. 

function dti_distance(folder, fileName)
 
subj = fileName; 
folder = folder;
[eigVectors, eigValues, Tensor, Names] = dti_distance_load_fun_brainMask(folder); 
for i = 1:20
    Tensor{i} = double(Tensor{i}); 
end

%% Get principal eigenvectors and angles


% Get principal eigenvectors
prinEigVector = getPrinEigVec(eigVectors, eigValues); 


% Get angle of vector
[angles, lambda] = getAngles(eigVectors, prinEigVector); 




% Compute nonparametric population density function using kde2d. 
minXY = [-90 -90]; 
maxXY = [90 90];
numBins = 2^7; 
for i = 1:length(angles)
    [bandwidth, density, X, Y] = kde2d(angles{i}, numBins, minXY, maxXY);
    density = density / sum(sum(density));
    density = density';
    anglePdf{i} = density;
    anglePdfLog{i} = log(density); 
end

%{
figure(2); 
 for i = 1:10
     subplot(2,5,i);
     mesh(gridx1, gridx2, nonPara{i}); 
     title(Names{i}); 
     xlabel('\psi'); 
     ylabel('\theta');
 end
%}
for i = 1:20
    angle1bin{i} = angles{i}(:,1); 
    angle1bin{i} = angle1bin{i} * numBins / 180; 
    angle1bin{i} = floor(angle1bin{i}); 
    angle1bin{i} = angle1bin{i} + numBins/2+1; 

    angle2bin{i} = angles{i}(:,2); 
    angle2bin{i} = angle2bin{i} * numBins / 180; 
    angle2bin{i} = floor(angle2bin{i}); 
    angle2bin{i} = angle2bin{i} + numBins/2+1; 
end

%% Do same for lambda

minXY = [0 0]; 
maxXY = [1 1];
numBins = 2^5; 
for i = 1:length(lambda)
    [bandwidth, density, X, Y] = kde2d(lambda{i}, numBins, minXY, maxXY);
    density = density / sum(sum(density)); 
    density = density';
    lambdaPdf{i} = density; 
    lambdaPdfLog{i} = log(density); 
    subplot(4,5,i); 
    surf(X,Y,lambdaPdf{i})

end


%{
for i = 1:10
    nonParaProbLam = ksdensity2d(double(lambda{i}),gridx1,gridx2); 
    sumNonParaLam(i) = sum(sum(nonParaProbLam)); 
    nonParaLam{i} = nonParaProbLam / sumNonParaLam(i);
    logNonParaLam{i} = log(nonParaLam{i}); 
    sum(sum(nonParaLam{i}));
end
%}

%{
for i = 1:10
    subplot(2,5,i);
    mesh(gridx1, gridx2, nonParaLam{i}); 
    title(Names{i}); 
    xlabel('\lambda_2'); 
    ylabel('\lambda_1');
end
%}
for i = 1:20
    lambda1bin{i} = lambda{i}(:,1); 
    lambda1bin{i} = lambda1bin{i} * numBins ; 
    lambda1bin{i} = floor(lambda1bin{i}); 
    lambda1bin{i} = lambda1bin{i}+1; 
    
    lambda2bin{i} = lambda{i}(:,2); 
    lambda2bin{i} = lambda2bin{i} * numBins;
    lambda2bin{i} = floor(lambda2bin{i}); 
    lambda2bin{i} = lambda2bin{i}+1; 

end


%%
figure; 

   progressbar('Calculating Mean Probabilities for Subject 1'); 

for i = 1:10
    for j = 1:10
        for k = 1:length(angle1bin{i})
%             probabilityAngle{i,j}(k) = anglePdf{j}(angle1bin{i}(k), angle2bin{i}(k));
            probabilityAngleLog{i,j}(k) = anglePdfLog{j}(angle1bin{i}(k), angle2bin{i}(k)); 

           % probabilityShape{i,j}(k) = lambdaPdf{j}(lambda1bin{i}(k), ...
           %     lambda2bin{i}(k)); 
            

        end
%             meanProbAngle(i,j) = mean(probabilityAngle{i,j}); 
            meanProbAngleLog{1}(i,j) = mean(probabilityAngleLog{i,j}); 
%             medProbAngle(i,j) = median(probabilityAngle{i,j}); 
          %  meanProbShape(i,j) = mean(probabilityShape{i,j}); 
%         probabilityTotal{i,j} = probabilityAngle{i,j} .* probabilityShape{i,j}; 
%         meanProb(i,j) = mean(probabilityTotal{i,j}); 
%         medProb(i,j) = median(probabilityTotal{i,j}); 

%         meanProb(i,j) = mean(probability{i,j}); 
    end
    progressbar(i/10)
end
 
meanProbAngleLog{1} = abs(meanProbAngleLog{1});
meanDiag = diag(meanProbAngleLog{1}); 
maxMean = min(meanProbAngleLog{1}'); 
missesMean = meanDiag ~= maxMean'; 
sum(missesMean)



% medProbAngle
% medDiag = diag(medProbAngle); 
% maxMed = max(medProbAngle'); 
% missesMed = medDiag ~= maxMed'; 
% sum(missesMed)

%xlswrite('distanceCompare.xls',meanProb,'totalNonPara'); 
progressbar('Calculating Mean Probabilities for Subject 2'); 

for i = 11:20
    for j = 11:20
        for k = 1:length(angle1bin{i})
%             probabilityAngle{i,j}(k) = anglePdf{j}(angle1bin{i}(k), angle2bin{i}(k));
            probabilityAngleLog{i,j}(k) = anglePdfLog{j}(angle1bin{i}(k), angle2bin{i}(k)); 

           % probabilityShape{i,j}(k) = lambdaPdf{j}(lambda1bin{i}(k), ...
           %     lambda2bin{i}(k)); 
            

        end
%             meanProbAngle(i,j) = mean(probabilityAngle{i,j}); 
            meanProbAngleLog{2}(i-10,j-10) = mean(probabilityAngleLog{i,j}); 
%             medProbAngle(i,j) = median(probabilityAngle{i,j}); 
          %  meanProbShape(i,j) = mean(probabilityShape{i,j}); 
%         probabilityTotal{i,j} = probabilityAngle{i,j} .* probabilityShape{i,j}; 
%         meanProb(i,j) = mean(probabilityTotal{i,j}); 
%         medProb(i,j) = median(probabilityTotal{i,j}); 

%         meanProb(i,j) = mean(probability{i,j}); 
    end
    progressbar((i-10)/10)
end
meanProbAngleLog{2} = abs(meanProbAngleLog{2})
meanDiag = diag(meanProbAngleLog{2}); 
maxMean = min(meanProbAngleLog{2}'); 
missesMean = meanDiag ~= maxMean'; 
sum(missesMean)
%{
% medProb
% medDiag = diag(medProb); 
% maxMed = min(medProb'); 
% missesMed = medDiag ~= maxMed'; 
% sum(missesMed)


% 
% tic
% [X Y]=meshgrid(-90:2:90);
% for i = 1:10
%     x1=angles{i}(:,1);
%     y1=angles{i}(:,2);
%     [XI, YI] = meshgrid(x1, y1); 
%     Z=nonPara{i};        
%     ZI=double(interp2(X,Y,Z,XI,YI));
%     figure; contour(X,Y,Z); 
%     figure; contour(XI, YI, ZI); 
%     %distNonpara(i,j) = mean(probability); 
% end
% toc

% [X Y]=meshgrid(-90:2:90);
% for i = 1:10
%     for j = 1:10       
%         x1=angles{i}(:,1);
%         y1=angles{i}(:,2);
%         [XI, YI] = meshgrid(x1, y1); 
%         Z=nonPara{j};        
%         probability{=interp2(X,Y,Z,XI,YI);
%         %distNonpara(i,j) = mean(probability); 
%     end
% end

% sum=sum(distNonpara(:));
% distNonpara2=zeros(10,10);
% for i=1:10
%     for j=1:10
%         distNonpara2(i,j)=distNonpara(i,j)./sum;
%     end
% end
% xlswrite('nonparametric2b.xls',distNonpara2,'totalNonpara');
%}

%% Calculate Distances
%Mahalanobis

for i = 1:10
    for j = 1:10
        distMahal{1}(i,j) = mean(mahal(Tensor{i},Tensor{j})); 
    end
end



mahalDiag = diag(distMahal{1}); 
minMahal = min(distMahal{1}'); 
missesMahal = mahalDiag ~= minMahal'; 
sum(missesMahal)

 progressbar('Computing MCD Norm, Subject 1'); 
for i = 1:10
    for j = 1:10 
        distMCD{1}(i,j) = mean(mcdmahalNoPlot(Tensor{i},Tensor{j})); 
        progressbar(((i-1)*10+j) / 100);
    end
end
mcdDiag = diag(distMCD{1}); 
minMCD = min(distMCD{1}'); 
missesMCD = mcdDiag ~= minMCD'; 
sum(missesMCD)

for i = 11:20
    for j = 11:20
        distMahal{2}(i-10,j-10) = mean(mahal(Tensor{i},Tensor{j})); 
    end
end



mahalDiag = diag(distMahal{2}); 
minMahal = min(distMahal{2}'); 
missesMahal = mahalDiag ~= minMahal'; 
sum(missesMahal)

progressbar('Computing MCD Norm, Subject 2'); 

for i = 11:20
    for j = 11:20 
        distMCD{2}(i-10,j-10) = mean(mcdmahalNoPlot(Tensor{i},Tensor{j})); 
        progressbar( ((i-11) * 10 + j-10) / 100)
    end
end
mcdDiag = diag(distMCD{2}); 
minMCD = min(distMCD{2}'); 
missesMCD = mcdDiag ~= minMCD'; 
sum(missesMCD)


%{
xlswrite('distanceCompare.xls',distMahal,'totalMahal'); 
xlswrite('distanceCompare.xls', distMCD, 'totalMCD'); 
%}


xlswrite(subj, meanProbAngleLog{1},'meanProbAngleLog1'); 
xlswrite(subj, meanProbAngleLog{2}, 'meanProbAngleLog2'); 
xlswrite(subj, distMahal{1}, 'distMahal1'); 
xlswrite(subj, distMahal{2}, 'distMahal2'); 
xlswrite(subj, distMCD{1}, 'distMCD1'); 
xlswrite(subj, distMCD{2}, 'distMCD2'); 

%{
lCst2Ilf = mahal(left_cst_TensorMat, left_ilf_TensorMat);
lCst2rCst = mahal(left_cst_TensorMat, right_cst_TensorMat);
lCst2lCst = mahal(left_cst_TensorMat, left_cst_TensorMat);
lCst2Slf = mahal(left_cst_TensorMat, left_slf_TensorMat); 
lCst2lUnc = mahal(left_cst_TensorMat, left_unc_TensorMat); 

% Mahalanobis with MCD covariance matrix
lCst2lCstMCD = mcdmahal(double(left_cst_TensorMat), double(left_cst_TensorMat));
lCst2IlfMCD = mcdmahal(double(left_cst_TensorMat), double(left_ilf_TensorMat));
lCst2rCstMCD = mcdmahal(double(left_cst_TensorMat), double(right_cst_TensorMat));
lCst2SlfMCD = mcdmahal(double(left_cst_TensorMat), double(left_slf_TensorMat)); 
lCst2lUncMCD = mcdmahal(double(left_cst_TensorMat), double(left_unc_TensorMat)); 

%% Plot
[lCst2lCstHist, lCst2lCstBin] = hist(lCst2lCst, 1000); 
[lCst2IlfHist, lCst2IlfBin] = hist(lCst2Ilf, 1000); 
[lCst2rCstHist, lCst2rCstBin] = hist(lCst2rCst, 1000); 
[lCst2SlfHist, lCst2SlfBin] = hist(lCst2Slf, 1000); 
[lCst2lUncHist, lCst2lUncBin]  = hist(lCst2lUnc, 1000); 

[lCst2lCstHistMCD, lCst2lCstBinMCD] = hist(lCst2lCstMCD, 1000); 
[lCst2IlfHistMCD, lCst2IlfBinMCD] = hist(lCst2IlfMCD, 1000); 
[lCst2rCstHistMCD, lCst2rCstBinMCD] = hist(lCst2rCstMCD, 1000); 
[lCst2SlfHistMCD, lCst2SlfBinMCD] = hist(lCst2SlfMCD, 1000); 
[lCst2lUncHistMCD, lCst2lUncBinMCD]  = hist(lCst2lUncMCD, 1000); 

figure; 
plot(lCst2IlfBin, lCst2IlfHist, lCst2rCstBin, lCst2rCstHist, ...
    lCst2SlfBin, lCst2SlfHist, lCst2lUncBin, lCst2lUncHist,lCst2lCstBin, lCst2lCstHist); 
legend('Left CST to Left ILF', 'Left CST to Right CST', 'Left CST to Left SLF', ...
    'Left CST to Left Uncinate', 'Left CST to Left CST')


axis([0 50 0 1000])
xlabel('Distance'); ylabel('Counts'); 
title('Histogram of Mahalanobis Distance Between Various Tracts')
saveas(gcf, 'mahalDistance.png')

figure; 

plot(lCst2IlfBinMCD, lCst2IlfHistMCD, lCst2rCstBinMCD, lCst2rCstHistMCD, ...
    lCst2SlfBinMCD, lCst2SlfHistMCD, lCst2lUncBinMCD, lCst2lUncHistMCD, lCst2lCstBinMCD, lCst2lCstHistMCD); 
legend('Left CST to Left ILF', 'Left CST to Right CST', 'Left CST to Left SLF', ...
    'Left CST to Left Uncinate', 'Left CST to Left CST')

axis([0 50 0 1000])
xlabel('Distance'); ylabel('Counts'); 
title('Histogram of MCD Mahalanobis Distance Between Various Tracts')
saveas(gcf, 'mcdMahalDistance.png')

% Create bar graph of average distances
avgDist(1, 1) = mean(lCst2rCst); 
avgDist(1,2) = mean(lCst2rCstMCD); 
avgDist(2,1) = mean(lCst2Ilf); 
avgDist(2,2) = mean(lCst2IlfMCD); 
avgDist(3,1) = mean(lCst2Slf); 
avgDist(3,2) = mean(lCst2SlfMCD); 
avgDist(4,1) = mean(lCst2lUnc); 
avgDist(4,2) = mean(lCst2lUncMCD);

for i = 1:4
distDif(i, :) = avgDist(i,:) - avgDist(1,:);
end

medDist(1, 1) = median(lCst2rCst); 
medDist(1,2) = median(lCst2rCstMCD); 
medDist(2,1) = median(lCst2Ilf); 
medDist(2,2) = median(lCst2IlfMCD); 
medDist(3,1) = median(lCst2Slf); 
medDist(3,2) = median(lCst2SlfMCD); 
medDist(4,1) = median(lCst2lUnc); 
medDist(4,2) = median(lCst2lUncMCD);

for i = 1:4
distDifMed(i, :) = medDist(i,:) - medDist(1,:);
end

figure; bar(distDif(2:4,:)); 

%}

    