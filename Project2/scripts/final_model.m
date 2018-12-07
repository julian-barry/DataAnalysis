%% Final model building
%Here we'll use all the data set to build our final model with optimal
%parameters computed from the Guidesheets.
%Different options: With/without PCA. Lasso/Elastic nets. Optimal lambda,
%alpha. Optimal number of features.
%
%STANDARD LINEAR REGRESSION
%Number of features with PCA: 690 (corresponding to 90% variance)
%
%LASSO / ELASTIC NETS
%Number of features with PCA: ?
%lambda = 2.683e-4; 
%alpha = 0.58;

%% Data loading
clear all;
close all;
load('../data/Data.mat');

%% Standard Linear regression with PCA

%% Data set partitioning and PCA 
%Partition
train_proportion = 0.7;     
rows = size(Data,1); 
sep_idx = round(rows*train_proportion);

train = Data(1:sep_idx,:);
test = Data(sep_idx+1:end,:); 

[std_train, mu, sigma] = zscore(train); 
std_test = (test - mu ) ./ sigma; 

%PCA
[coeff, score, latent] = pca(std_train);

pca_train = std_train * coeff;
pca_test = std_test * coeff; 

%% Regression - linear
nPCs = 741;  %for 90% total variance
%Train
pos_x_train = PosX(1:sep_idx); 
pos_y_train = PosY(1:sep_idx); 
FM_train = pca_train(:,1:nPCs); 
I_train = ones(size(FM_train,1),1); 
X_train = [I_train FM_train];

%Regression and mse
bx = regress(pos_x_train, X_train); 
by = regress(pos_y_train, X_train);
x_hat = X_train * bx; 
y_hat = X_train * by;
mse_pos_x = immse(pos_x_train, x_hat); 
mse_pos_y = immse(pos_y_train, y_hat);

%Test
pos_x_test = PosX(sep_idx+1:end); 
pos_y_test = PosY(sep_idx+1:end);
FM_test = pca_test(:,1:nPCs);
I_test = ones(size(FM_test,1),1);
X_test = [I_test FM_test];

x_hat_test = X_test * bx; 
y_hat_test = X_test * by;
mse_posx_test = immse(pos_x_test, x_hat_test);
mse_posy_test = immse(pos_y_test, y_hat_test);

%% Plot
regressed_x = [x_hat; x_hat_test];
regressed_y = [y_hat; y_hat_test];

%X motion
subplot(2,1,1)
plot(PosX, 'Linewidth', 1); hold on;
plot(regressed_x, 'LineWidth', 1); hold off;
xlabel('Time [ms]');
ylabel('X');
%axis([8500 9500 -0.05 0.18]); %2000-2500 vs -0.05 0.18
x = [sep_idx sep_idx];
y = [-1 1];
line(x, y, 'Color', 'black', 'LineStyle', '--')
legend('Observed', 'Predicted', 'Train/Test separation');

%Y motion
subplot(2,1,2)
plot(PosY, 'LineWidth', 1); hold on;
plot(regressed_y, 'LineWidth', 1); hold off;
xlabel('Time [ms]');
ylabel('Y');
%title('');
%axis([8500 9500 0.1 0.33]); %2000-2500 vs -0.05 0.18
line(x, y, 'Color', 'black', 'LineStyle', '--')
legend('Observed', 'Predicted', 'Train/Test separation');

%% Display MSE
disp(['Linear regression: MSE train (Position X) = ', num2str(mse_pos_x)]);
disp(['Linear regression: MSE train (Position Y) = ', num2str(mse_pos_y)]);
disp(['Linear regression: MSE test (Position X) = ', num2str(mse_posx_test)]);
disp(['Linear regression: MSE test (Position Y) = ', num2str(mse_posy_test)]);

%% Standard Linear regression with PCA
% nPCs = 741;
% %Standardization
% std_Data = zscore(Data);
% %PCA
% [coeff, score, latent] = pca(std_Data);
% %Regression
% bx = regress(PosX, score);
% 
% FM_x = score(:,1:nPCs); % training feature matrix
% I_x = ones(size(FM_x,1),1); % X should include a column of ones so that the model contains a constant term
% X_x = [I_x FM_x];
% 
% x_hat = X_x * bx;

%% Plot results - Standard Linear Regression
% figure
% plot(PosX, 'LineWidth', 1.5); hold on;
% plot(x_hat, 'LineWidth', 1.5);
% xlabel('Time [ms]');
% ylabel('Position X');
% axis([2000 2500 -0.05 0.15]);


%% Lasso / Elastic Nets
%% Clean variables
clear all;
close all;
load('../data/Data.mat');

%% Data partiotionning
%Partition
train_proportion = 0.7;     
rows = size(Data,1); 
sep_idx = round(rows*train_proportion);

train = Data(1:sep_idx,:);
test = Data(sep_idx+1:end,:); 

pos_x_train = PosX(1:sep_idx); 
pos_y_train = PosY(1:sep_idx); 

pos_x_test = PosX(sep_idx+1:end); 
pos_y_test = PosY(sep_idx+1:end);

%Standardization
[std_train, mu, sigma] = zscore(train); 
std_test = (test - mu ) ./ sigma; 

%PCA
[coeff, score, latent] = pca(std_train);

pca_train = std_train * coeff;
pca_test = std_test * coeff;

%%
lambda = 2.68e-4;
alpha = 1;
nPCs = 300;
    
%Train
FM_train = X_train(:, 1:nPCs);
I_train = ones(size(FM_train, 1), 1); 
X_train = [I_train pca_train]; %nPCs ??


%Test
FM_test = X_test(:, 1:nPCs);
I_test = ones(size(FM_test, 1), 1); 
X_test = [I_test pca_test];

[bx, FitInfox] = lasso(pca_train, pos_x_train, 'Lambda', lambda, 'Alpha', alpha);
[by, FitInfoy] = lasso(pca_train, pos_y_train, 'Lambda', lambda, 'Alpha', alpha);

coeff_x = [FitInfox.Intercept bx'];
coeff_y = [FitInfoy.Intercept by'];

x_hat_train = X_train * coeff_x';
y_hat_train = X_train * coeff_y';


x_hat_test = X_test * coeff_x';
y_hat_test = X_test * coeff_y';

%Train error
mse_x_train = immse(pos_x_train, x_hat_train);
mse_y_train = immse(pos_x_train, y_hat_train);
    
%Test error
mse_x_test = immse(pos_x_test, x_hat_test);
mse_y_test = immse(pos_x_test, y_hat_test);


%Prediction X
% FM_x = [score(:,1:nPCs_x)];
% I_x = ones(size(FM_x,1),1);
% X_x = [I_x FM_x];
% 
% Bx = [FitInfox.Intercept bx'];
% 
% x_hat = X_x * Bx';
% 
% %Prediction Y
% FM_y = [score(:,1:nPCs_y)];
% I_y = ones(size(FM_y,1),1);
% X_y = [I_y FM_y];
% 
% By = [FitInfoy.Intercept by'];
% 
% y_hat = X_y * By';

%% Plot PosX
% figure
% plot(PosX, 'LineWidth', 1.5); hold on;
% plot(x_hat, 'LineWidth', 1.5);
% xlabel('Time [ms]');
% ylabel('Position X');
% legend('Observed', 'Predicted');
% axis([2000 2500 -0.05 0.15]);
% title('Observed and predicted X position - Lasso with PCA');

%% Lasso / Elastic Nets - Plot results
regressed_x = [x_hat_train; x_hat_test];
regressed_y = [y_hat_train; y_hat_test];

figure
subplot(2,1,1)
plot(PosX, 'LineWidth', 1.5); hold on;
plot(regressed_x, 'LineWidth', 1.5);
xlabel('Time [ms]');
ylabel('Position X');
legend('Observed', 'Predicted');
axis([8500 9500 -0.05 0.15]);
title('Observed and predicted X position - Elastic Nets with PCA (\alpha = ...');

subplot(2,1,2);
plot(PosY, 'LineWidth', 1.5); hold on;
plot(regressed_y, 'LineWidth', 1.5);
xlabel('Time [ms]');
ylabel('Position Y');
legend('Observed', 'Predicted');
axis([8500 9500 0.15 0.28]);
title('Observed and predicted Y position - Elastic Nets with PCA (\alpha = ...');

%% Display results
disp(['EN/Lasso: MSE train (Position X) (\alpha = ', num2str(alpha), ') = ', num2str(mse_x_train)]);
disp(['EN/Lasso: MSE train (Position Y) (\alpha = ', num2str(alpha), ') = ', num2str(mse_y_train)]);
disp(['EN/Lasso: MSE test (Position X) (\alpha = ', num2str(alpha), ') = ', num2str(mse_x_test)]);
disp(['EN/Lasso: MSE test (Position Y) (\alpha = ', num2str(alpha), ') = ', num2str(mse_y_test)]);

%% Elastic Nets with PCA
lambda = 2.68e-4;
alpha = 0.57;
nPCs = 300;

%Standardization
[std_Data, mu, sigma] = zscore(Data);
%PCA
[coeff, score, latent] = pca(std_Data);
%Lasso
[bx, FitInfox] = lasso(score(:, 1:nPCs_x), PosX, 'Lambda', lambda);
[by, FitInfoy] = lasso(score(:, 1:nPCs_y), PosY, 'Lambda', lambda);
%Prediction X
FM_x = [score(:,1:nPCs_x)];
I_x = ones(size(FM_x,1),1);
X_x = [I_x FM_x];

Bx = [FitInfox.Intercept bx'];

x_hat = X_x * Bx';

%Prediction Y
FM_y = [score(:,1:nPCs_y)];
I_y = ones(size(FM_y,1),1);
X_y = [I_y FM_y];

By = [FitInfoy.Intercept by'];

y_hat = X_y * By';


%%
%+ test + error
%Check MSE
%Separate train and test set (70% - 30%)
%For EN > test error 70-30




