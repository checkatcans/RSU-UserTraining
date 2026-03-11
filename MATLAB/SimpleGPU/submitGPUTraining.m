% submitGPUTraining.m
% GPU training with data generation included

clear; clc;

%% Setup cluster
c = parcluster();
%c.AdditionalProperties.AdditionalSubmitArgs = '--gres=gpu:1 --mem=16G --time=01:00:00';

%% Create training script with data generation
trainingScript = {
    'fprintf(''=== GPU Training Job ===\\n\\n'');'
    ''
    'try'
    '    %% Check GPU'
    '    fprintf(''Checking GPU...\\n'');'
    '    g = gpuDevice;'
    '    fprintf(''GPU: %s\\n'', g.Name);'
    '    fprintf(''Memory: %.2f GB\\n\\n'', g.TotalMemory/1e9);'
    '    '
    '    %% Generate Training Data'
    '    fprintf(''Generating training data...\\n'');'
    '    numTrainImages = 2000;'
    '    numTestImages = 500;'
    '    '
    '    % Create synthetic 28x28 grayscale images'
    '    XTrain = rand(28, 28, 1, numTrainImages, ''single'');'
    '    YTrain = categorical(randi([0 9], numTrainImages, 1));'
    '    '
    '    XTest = rand(28, 28, 1, numTestImages, ''single'');'
    '    YTest = categorical(randi([0 9], numTestImages, 1));'
    '    '
    '    fprintf(''Training images: %d\\n'', numTrainImages);'
    '    fprintf(''Test images: %d\\n\\n'', numTestImages);'
    '    '
    '    %% Define Network'
    '    fprintf(''Building network architecture...\\n'');'
    '    layers = ['
    '        imageInputLayer([28 28 1])'
    '        '
    '        convolution2dLayer(3, 8, ''Padding'', ''same'')'
    '        batchNormalizationLayer'
    '        reluLayer'
    '        '
    '        maxPooling2dLayer(2, ''Stride'', 2)'
    '        '
    '        convolution2dLayer(3, 16, ''Padding'', ''same'')'
    '        batchNormalizationLayer'
    '        reluLayer'
    '        '
    '        maxPooling2dLayer(2, ''Stride'', 2)'
    '        '
    '        fullyConnectedLayer(10)'
    '        softmaxLayer'
    '        classificationLayer];'
    '    '
    '    fprintf(''Network created with %d layers\\n\\n'', length(layers));'
    '    '
    '    %% Training Options'
    '    fprintf(''Configuring training options...\\n'');'
    '    options = trainingOptions(''adam'', ...'
    '        ''ExecutionEnvironment'', ''gpu'', ...'
    '        ''MaxEpochs'', 15, ...'
    '        ''MiniBatchSize'', 128, ...'
    '        ''ValidationData'', {XTest, YTest}, ...'
    '        ''ValidationFrequency'', 20, ...'
    '        ''Shuffle'', ''every-epoch'', ...'
    '        ''Verbose'', true, ...'
    '        ''Plots'', ''none'');'
    '    '
    '    fprintf(''Max Epochs: %d\\n'', options.MaxEpochs);'
    '    fprintf(''Batch Size: %d\\n\\n'', options.MiniBatchSize);'
    '    '
    '    %% Train Network'
    '    fprintf(''Starting training on GPU...\\n'');'
    '    fprintf(''=====================================\\n'');'
    '    tic;'
    '    [net, info] = trainNetwork(XTrain, YTrain, layers, options);'
    '    trainTime = toc;'
    '    fprintf(''=====================================\\n'');'
    '    fprintf(''Training completed in %.2f seconds\\n\\n'', trainTime);'
    '    '
    '    %% Evaluate'
    '    fprintf(''Evaluating model...\\n'');'
    '    YPred = classify(net, XTrain, ''ExecutionEnvironment'', ''gpu'');'
    '    trainAcc = sum(YPred == YTrain) / numel(YTrain) * 100;'
    '    '
    '    YPredTest = classify(net, XTest, ''ExecutionEnvironment'', ''gpu'');'
    '    testAcc = sum(YPredTest == YTest) / numel(YTest) * 100;'
    '    '
    '    fprintf(''Training Accuracy: %.2f%%\\n'', trainAcc);'
    '    fprintf(''Test Accuracy: %.2f%%\\n\\n'', testAcc);'
    '    '
    '    %% Save Results'
    '    fprintf(''Saving results...\\n'');'
    '    save(''trainedNet.mat'', ''net'', ''info'', ''trainTime'', ''trainAcc'', ''testAcc'');'
    '    '
    '    fprintf(''\\n=== Training Summary ===\\n'');'
    '    fprintf(''Time: %.2f seconds\\n'', trainTime);'
    '    fprintf(''Train Acc: %.2f%%\\n'', trainAcc);'
    '    fprintf(''Test Acc: %.2f%%\\n'', testAcc);'
    '    fprintf(''Results saved to trainedNet.mat\\n'');'
    '    '
    'catch ME'
    '    fprintf(''\\n=== ERROR ===\\n'');'
    '    fprintf(''Message: %s\\n'', ME.message);'
    '    fprintf(''\\nStack trace:\\n'');'
    '    for i = 1:length(ME.stack)'
    '        fprintf(''  %s (line %d)\\n'', ME.stack(i).name, ME.stack(i).line);'
    '    end'
    'end'
};

%% Write script to file
fprintf('Creating training script...\n');
fid = fopen('trainDL.m', 'w');
for i = 1:length(trainingScript)
    fprintf(fid, '%s\n', trainingScript{i});
end
fclose(fid);
fprintf('Script saved: trainDL.m\n\n');

%% Submit job
fprintf('Submitting training job to GPU cluster...\n');
job = c.batch('trainDL', 'AutoAddClientPath', false);

fprintf('Job ID: %d\n', job.ID);
fprintf('Job State: %s\n', job.State);
fprintf('\nWaiting for job to complete...\n');
fprintf('(This may take several minutes)\n\n');

%% Wait for completion
wait(job);

%% Display results
fprintf('=== Job Output ===\n');
diary(job);

%% Load trained network
fprintf('\n=== Loading Results ===\n');
try
    load(job, 'net', 'info', 'trainTime', 'trainAcc', 'testAcc');
    
    fprintf('SUCCESS! Network loaded.\n\n');
    fprintf('Training Time: %.2f seconds\n', trainTime);
    fprintf('Training Accuracy: %.2f%%\n', trainAcc);
    fprintf('Test Accuracy: %.2f%%\n', testAcc);
    fprintf('Network Layers: %d\n', length(net.Layers));
    fprintf('Training Iterations: %d\n', length(info.TrainingLoss));
    
    % Plot training progress
    fprintf('\nGenerating training plots...\n');
    figure('Position', [100, 100, 1200, 400]);
    
    subplot(1, 3, 1);
    plot(info.TrainingAccuracy, 'b-', 'LineWidth', 2);
    hold on;
    plot(info.ValidationAccuracy, 'r--', 'LineWidth', 2);
    xlabel('Iteration');
    ylabel('Accuracy (%)');
    title('Training Progress');
    legend('Training', 'Validation');
    grid on;
    
    subplot(1, 3, 2);
    plot(info.TrainingLoss, 'b-', 'LineWidth', 2);
    hold on;
    plot(info.ValidationLoss, 'r--', 'LineWidth', 2);
    xlabel('Iteration');
    ylabel('Loss');
    title('Loss Curve');
    legend('Training', 'Validation');
    grid on;
    
    subplot(1, 3, 3);
    bar([trainAcc, testAcc]);
    set(gca, 'XTickLabel', {'Training', 'Test'});
    ylabel('Accuracy (%)');
    title('Final Accuracy');
    ylim([0 100]);
    grid on;
    
    sgtitle(sprintf('GPU Training Results (%.1f sec)', trainTime), ...
            'FontSize', 14, 'FontWeight', 'bold');
    
    saveas(gcf, 'training_results.png');
    fprintf('Plot saved: training_results.png\n');
    
catch ME
    fprintf('Error loading results: %s\n', ME.message);
    fprintf('Check job output above for details.\n');
end

%% Cleanup
delete(job);
fprintf('\nJob complete and cleaned up.\n');