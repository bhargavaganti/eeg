%
% This script is used to concatenate all of the raw electrode data written
% to files from training_sessions.java and separate by hand movement and
% brain hemisphere. The results are written to four separate files in the
% same directory as the original training data. 
%


for n = 1:100 % 100 training trials

% Load raw EEG data
eeg = csvread(['../training_data/kiri/training_' num2str(n) '.txt'], 1, 0);

% Break up into testing sessions
divs = find(eeg(:,1) == 0);
neutral = eeg(1:(divs(1)-1), :);
right = eeg((divs(1)+1):(divs(2)-1), :);
left = eeg((divs(2)+1):end, :);

% Ensure there are 760 samples in right and left
goalsamples = 760;

if length(left) < goalsamples
    diff = goalsamples - length(left);
    copy = left(1:diff,:);
    left = [left; copy];
elseif length(left) > goalsamples
    left = left(1:goalsamples, :);
end
if length(right) < goalsamples
    diff = goalsamples - length(right);
    copy = right(1:diff,:);
    right = [right; copy];
elseif length(right) > goalsamples
    right = right(1:goalsamples, :);
end


% Butterworth filter design and filtering
seconds = 5;
Fs = length(right)/seconds; % Sampling frequency
L = length(right);
T = 1/Fs;

[b, a] = butter(10, [7 30]/(Fs/2), 'bandpass'); % Filter b/t 7-30 Hz
neutral = filter(b,a,neutral);
right = filter(b,a,right);
left = filter(b,a,left);

% Four channels:

% Separate into right and left hemispheres
lh_left = left(:,3:4);
lh_right = left(:,5:6);
rh_left = right(:,3:4);
rh_right = right(:,5:6);
%}


%{
% Write to files
dlmwrite('../training_data/four_channels/Lhand_Lhem.txt', lh_left, '-append');
dlmwrite('../training_data/four_channels/Lhand_Rhem.txt', lh_right, '-append');
dlmwrite('../training_data/four_channels/Rhand_Lhem.txt', rh_left, '-append');
dlmwrite('../training_data/four_channels/Rhand_Rhem.txt', rh_right, '-append');
%}

end





