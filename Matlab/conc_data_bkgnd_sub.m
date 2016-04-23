%
% This script is the same as conc_data.m, but it is specifically for
% compiling the neutral data that was recorded. The size is standardized to
% 760 data points by interpolating in order to match the size of the left
% hand and right hand movement matrices. Also writes neutral data to files.
%

for n = 1:100

% Load raw EEG data
eeg = csvread(['../training_data/kiri/training_' num2str(n) '.txt'], 1, 0);

% Break up into testing sessions
divs = find(eeg(:,1) == 0);
neutral = eeg(1:(divs(1)-1), :);
right = eeg((divs(1)+1):(divs(2)-1), :);
left = eeg((divs(2)+1):end, :);

% Ensure there are 760 samples in neutral by interpolating
goalsamples = 760;
xq = 1:goalsamples;

n_interp = zeros(760, size(neutral,2));

for y = 1:size(neutral,2)
    x = linspace(1, goalsamples, length(neutral));
    n_interp(:,y) = interp1(x, neutral(:,y), xq);
end

% Butterworth filter design and filtering
seconds = 5;
Fs = length(n_interp)/seconds; % Sampling frequency
L = length(n_interp);
T = 1/Fs;

[b, a] = butter(10, [7 30]/(Fs/2), 'bandpass'); % Filter b/t 7-30 Hz
n_interp = filter(b,a,n_interp);

% Four channels:

% Separate into right and left hemispheres
neutral_left = n_interp(:,1:2);
neutral_right = n_interp(:,3:4);
%}

%{
% Write neutral data to files
dlmwrite('../training_data/kiri/neutral_left.txt', neutral_left, '-append');
dlmwrite('../training_data/kiri/neutral_right.txt', neutral_right, '-append');
%}

end





