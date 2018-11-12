%% PCA nested cross-validation 3.0
clear all;
load('../data/trainSet.mat');
load('../data/trainLabels.mat');

%Simple corss-validation loop with fix classifier for now! (diaglin)
Priors.ClassNames=[0 1];
Priors.ClassProbs=[0.7 0.3];

kin=5;
nObservations=length(trainLabels);
Nmax=300; %number of PCs

%Error resulting from the inner loop ('simple cross-validation')
trainErrorStorage=zeros(Nmax,kin);
validationErrorStorage=zeros(Nmax,kin);

kout=4;

%Erreur finale calcul�e pour �valuer la PERF du mod�le (!!!)
testErrorStorage=zeros(1,kout);

%Nombre de components N optimal
optimalComponentsNumber=zeros(1, kout);

%Erreur de training + validation minimale > forc�ment il y en a une pas outer fold
minMeanTrainError=zeros(1, kout);
minMeanValidationError=zeros(1, kout);

partitionOut=cvpartition(nObservations, 'kfold', kout); %same dimension of score and trainLabels (597 lines)

for i=1:kout
    %Indexes
    outerTrainIds=partitionOut.training(i);
    outerTestIds=partitionOut.test(i);
    
    %Outer train (2/3)
    outerTrainSet=trainData(outerTrainIds, :); 
    outerTrainLabels=trainLabels(outerTrainIds, :);
    
    %Outer test (1/3)
    outerTestSet=trainData(outerTestIds, :); %lui on le garde pour la fin %trainData
    outerTestLabels=trainLabels(outerTestIds, :);
    
    %To partition the inner set we need to get the size of all the inner fold
    sizeOuterTrain=size(outerTrainSet,1);
    partitionIn = cvpartition(sizeOuterTrain, 'kfold', kin); %les data transform�s ont toujours 597 observations

    for t=1:kin        
        innerTrainIds=partitionIn.training(t);
        innerValidationIds=partitionIn.test(t);
        
        %Inner train set + labels
        innerTrainSet=outerTrainSet(innerTrainIds, :);
        innerTrainLabels=outerTrainLabels(innerTrainIds, :);
        
        %Validation set + labels
        innerValidationSet=outerTrainSet(innerValidationIds, :); %inner test set = validation set
        innerValidationLabels=outerTrainLabels(innerValidationIds, :);
        
        %Normalise both the train + validation set
        [innerTrainSetN, muInnerTrainSet, sigmaInnerTrainSet]=zscore(innerTrainSet);
        innerValidationSetN=(innerValidationSet - muInnerTrainSet)./ sigmaInnerTrainSet;
        
        %Time for PCA
        [coeff, score, variance]=pca(innerTrainSetN);
        
        N_transformedFeatures=size(score, 2);
        
        for N=1:N_transformedFeatures                        
            %selectedComponents=score(:, 1:N); %Components are classified by importance order.
            
            %diaglinear model
            classifier = fitcdiscr(score(:, 1:N), innerTrainLabels, 'DiscrimType', 'diaglinear', 'Prior', Priors); 
            
            %Prediction for the train and validation sets
            innerTrainPrediction=predict(classifier, score(:, 1:N));
            
            %Prediction for the validation set            
            validationScore=(innerValidationSetN-mean(innerValidationSetN))*coeff;
            innerValidationPrediction=predict(classifier, validationScore(:, 1:N));
            
            %Compute errors associated to the inner loop ('simple cross-validation')
            trainError=computeClassError(innerTrainPrediction, innerTrainLabels);
            validationError=computeClassError(innerValidationPrediction, innerValidationLabels); %testError or validationError
            
            trainErrorStorage(N,t)=trainError;
            validationErrorStorage(N,t)=validationError;
        end
    end

    %Compute MEAN errors of previous section (inner)
    meanTrainError=mean(trainErrorStorage, 2); %2 specifies mean on rows
    meanValidationError=mean(validationErrorStorage, 2);
        %stocker �ventuellement meanTrainError = meanInnerTrainError
        %stocker �ventuellement meanValidationError
    
    %Find the min error and the corresponding value
    [minValidationError, minValidationErrorIdx]=min(meanValidationError);
    
    %minimum mean TRAINING error
    minMeanTrainError(1,i)=min(meanTrainError); %pas sur    
    
    %minimum mean VALIDATION error > on la stocke quand m�me
    minMeanValidationError(1,i)=minValidationError;
       
    %Find the optimal NUMBER OF COMPONENTS N with the index of the min error
    optimalComponentsNumber(1,i)=minValidationErrorIdx; %index matters here
    
    
    %EVALUATION OF OPTIMAL MODEL
    %as for PCA components are already in order of importance
    %selectedComponents=score(1:minValidationErrorIdx); %pas utile
    
    %Optimal model
    optimalModel=fitcdiscr(outerTrainSet(:, 1:minValidationErrorIdx), outerTrainLabels, 'DiscrimType', 'diaglinear','Prior',Priors);
    optimalModelPrediction=predict(optimalModel, outerTestSet(:, 1:minValidationErrorIdx));
    
    %Compute errors associated to the outer loop = TEST ERRORS
    testError=computeClassError(optimalModelPrediction, outerTestLabels);
    testErrorStorage(1,i)=testError; 
end

