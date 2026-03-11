fprintf('=== GPU Training Job ===\\n\\n');

try
    %% Check GPU
    fprintf('Checking GPU...\\n');
    g = gpuDevice;
    fprintf('GPU: %s\\n', g.Name);
    fprintf('Memory: %.2f GB\\n\\n', g.TotalMemory/1e9);
    
    %% Generate Training Data
    fprintf('Generating training data...\\n');
    numTrainImages = 2000;
    numTestImages = 500;
    
    % Create synthetic 28x28 grayscale images
    XTrain = rand(28, 28, 1, numTrainImages, 'single');
    YTrain = categorical(randi([0 9], numTrainImages, 1));
    
    XTest = rand(28, 28, 1, numTestImages, 'single');
    YTest = categorical(randi([0 9], numTestImages, 1));
    
    fprintf('Training images: %d\\n', numTrainImages);
    fprintf('Test images: %d\\n\\n', numTestImages);
    
    %% Define Network
    fprintf('Building network architecture...\\n');
    layers = [
        imageInputLayer([28 28 1])
        
        convolution2dLayer(3, 8, 'Padding', 'same')
        batchNormalizationLayer
        reluLayer
        
        maxPooling2dLayer(2, 'Stride', 2)
        
        convolution2dLayer(3, 16, 'Padding', 'same')
        batchNormalizationLayer
        reluLayer
        
        maxPooling2dLayer(2, 'Stride', 2)
        
        fullyConnectedLayer(10)
        softmaxLayer
        classificationLayer];
    
    fprintf('Network created with %d layers\\n\\n', length(layers));
    
    %% Training Options
    fprintf('Configuring training options...\\n');
    options = trainingOptions('adam', ...
        'ExecutionEnvironment', 'gpu', ...
        'MaxEpochs', 15, ...
        'MiniBatchSize', 128, ...
        'ValidationData', {XTest, YTest}, ...
        'ValidationFrequency', 20, ...
        'Shuffle', 'every-epoch', ...
        'Verbose', true, ...
        'Plots', 'none');
    
    fprintf('Max Epochs: %d\\n', options.MaxEpochs);
    fprintf('Batch Size: %d\\n\\n', options.MiniBatchSize);
    
    %% Train Network
    fprintf('Starting training on GPU...\\n');
    fprintf('=====================================\\n');
    tic;
    [net, info] = trainNetwork(XTrain, YTrain, layers, options);
    trainTime = toc;
    fprintf('=====================================\\n');
    fprintf('Training completed in %.2f seconds\\n\\n', trainTime);
    
    %% Evaluate
    fprintf('Evaluating model...\\n');
    YPred = classify(net, XTrain, 'ExecutionEnvironment', 'gpu');
    trainAcc = sum(YPred == YTrain) / numel(YTrain) * 100;
    
    YPredTest = classify(net, XTest, 'ExecutionEnvironment', 'gpu');
    testAcc = sum(YPredTest == YTest) / numel(YTest) * 100;
    
    fprintf('Training Accuracy: %.2f%%\\n', trainAcc);
    fprintf('Test Accuracy: %.2f%%\\n\\n', testAcc);
    
    %% Save Results
    fprintf('Saving results...\\n');
    save('trainedNet.mat', 'net', 'info', 'trainTime', 'trainAcc', 'testAcc');
    
    fprintf('\\n=== Training Summary ===\\n');
    fprintf('Time: %.2f seconds\\n', trainTime);
    fprintf('Train Acc: %.2f%%\\n', trainAcc);
    fprintf('Test Acc: %.2f%%\\n', testAcc);
    fprintf('Results saved to trainedNet.mat\\n');
    
catch ME
    fprintf('\\n=== ERROR ===\\n');
    fprintf('Message: %s\\n', ME.message);
    fprintf('\\nStack trace:\\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\\n', ME.stack(i).name, ME.stack(i).line);
    end
end
