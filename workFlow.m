%% Acquire data
vibratory_data = acquireData(1,1,200);

%% To check for features it is possible to use diagnosticFeatureDesigner app
diagnosticFeatureDesigner

%% Extract features
indicatorsTable = extractFeatures(vibratory_data);

%% Remove outliers
[indicatorsTable_RmOut, countRm_all, countRm_bin] = removeOutliers(indicatorsTable);

%% Arrange randomly
indicatorsTable_RmOut = indicatorsTable_RmOut(randperm(size(indicatorsTable_RmOut, 1)), :);

%% Z-score standardization
indicatorsTable_scaled = indicatorsTable_RmOut;
[indicatorsTable_scaled{:,5:49}, MU, SIGMA] = zscore(indicatorsTable_RmOut{:,5:49});

%% PCA
[coeffs, score, ~, ~, exp, mu_pca] = pca(indicatorsTable_scaled{:,5:49});
indicatorsTable_PCA = [indicatorsTable_scaled(:,1:4) array2table(score) indicatorsTable_scaled(:,end)];

% How many PCs explain given variation
sum_explained = 0;
idx = 0;
while sum_explained < 95
    idx = idx + 1;
    sum_explained = sum_explained + exp(idx);
end
disp(idx)

%% Split data into training and validation dataset
% For model using indicators
XTrain = indicatorsTable_scaled(1:round(height(indicatorsTable_scaled)*0.85),:);
XTest = indicatorsTable_scaled(round(height(indicatorsTable_scaled)*0.85)+1:end,:);

% For model using PCs
XTrain_PCA = indicatorsTable_PCA(1:round(height(indicatorsTable_PCA)*0.85),:);
XTest_PCA = indicatorsTable_PCA(round(height(indicatorsTable_PCA)*0.85)+1:end,:);

%% To create models use ClassificationLearner app
classificationLearner

%% Train and validate models
% Model trained on wholed dataset
for i = 1:5
    tic
    [trainedClassifier, testAccuracy(i)] = trainBaggedAllPower(XTrain);
    training_time(i) = toc;
    
    yfit = trainedClassifier.predictFcn(XTest);
    validationAcc(i) = sum(XTest.Power == yfit)/length(XTest.Power);
end

figure()
confusionchart(XTest.Power,yfit, 'RowSummary','row-normalized','ColumnSummary','column-normalized','XLabel','Predicted class','YLabel','True class');

disp('Bagged Tree with all indicators:')
fprintf('test = %.2f +- %.2f; valid =  %.2f +- %.2f; time = %.2fs +- %.2fs\n',mean(testAccuracy)*100,std(testAccuracy)*100,mean(validationAcc)*100,std(validationAcc)*100,mean(training_time),std(training_time));

% Model trained on visually chosen dataset
for i = 1:5
    tic
    [trainedClassifier, testAccuracy(i)] = trainBaggedVizualPower(XTrain);
    training_time(i) = toc;
    
    yfit = trainedClassifier.predictFcn(XTest);
    validationAcc1(i) = sum(XTest.Power == yfit)/length(XTest.Power);
end

figure()
confusionchart(XTest.Power,yfit, 'RowSummary','row-normalized','ColumnSummary','column-normalized','XLabel','Predicted class','YLabel','True class');

disp('Bagged Tree with visually chosen indicators:')
fprintf('test = %.2f +- %.2f; valid =  %.2f +- %.2f; time = %.2fs +- %.2fs\n',mean(testAccuracy)*100,std(testAccuracy)*100,mean(validationAcc1)*100,std(validationAcc1)*100,mean(training_time),std(training_time));

% Model trained on PCs
for i = 1:5
    tic
    [trainedClassifier, testAccuracy(i)] = trainBaggedPCAPower(XTrain_PCA);
    training_time(i) = toc;
    
    yfit = trainedClassifier.predictFcn(XTest_PCA);
    validationAcc2(i) = sum(XTest_PCA.Power == yfit)/length(XTest_PCA.Power);
end

figure()
confusionchart(XTest_PCA.Power,yfit, 'RowSummary','row-normalized','ColumnSummary','column-normalized','XLabel','Predicted class','YLabel','True class');

disp('Bagged Tree with PCs:')
fprintf('test = %.2f +- %.2f; valid =  %.2f +- %.2f; time = %.2fs +- %.2fs\n',mean(testAccuracy)*100,std(testAccuracy)*100,mean(validationAcc2)*100,std(validationAcc2)*100,mean(training_time),std(training_time));