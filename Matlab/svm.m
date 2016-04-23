% Compile training data and train SVM

lh = [lhlhem_fft, lhrhem_fft];
rh = [rhlhem_fft, rhrhem_fft];

%{
% Subtract neutral background
neutral = [nL_fft, nR_fft];
avg_n = mean(neutral);
for x = 1:length(lh)
    lh(x,:) = lh(x,:) - avg_n;
    rh(x,:) = rh(x,:) - avg_n;
end
%}

% Split up training and testing data
training_data = [lh(1:400, :); rh(1:400, :)];
test_data = [lh(401:500, :); rh(401:500, :)];

alldata = [lh; rh];
cutdata = [lh(:,1:120); rh(:,1:120)]; % To match size of real-time matrices

% Verbose version
Y = cell(size(training_data, 1), 1);
for x = 1:length(Y);
    if x <= 400
       Y{x} = 'left';
    else
        Y{x} = 'right';
    end
end
%}

% Binary version: 0 = left, 1 = right
%{
Y = zeros(size(training_data, 1), 1);
for x = 1:length(Y);
    if x <= 400
       Y(x) = 0;
    else
        Y(x) = 1;
    end
end
%}

% Train the SVM on labeled training data
svmModel = fitcsvm(training_data, Y, 'KernelFunction', 'linear');

% Test the model on testing data
[label, score] = predict(svmModel, test_data);


% Determine how many of the left and right sets were classified correctly
% Verbose version
l_train = label(1:100);
r_train = label(101:200);
lcount = 0;
rcount = 0;

for x = 1:100
    if strcmp(l_train{x},'left')
        lcount = lcount+1;
    end
    if strcmp(r_train{x}, 'right')
        rcount = rcount+1;
    end
end
%}

% Binary version
%{
for x = 1:100
    if l_train(x) == 0
        lcount = lcount+1;
    end
    if r_train(x) == 1
        rcount = rcount+1;
    end
end
%}
