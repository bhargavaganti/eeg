%% Get Prediction
% by Keaton Armentrout

% This function predicts based on SVM model m whether the data in traces 
% corresponds to left- or right-hand movement.

% This function is called via Matlab proxy from the eeg_to_arduino.java
% file during real-time data analysis.

% Inputs
%   # traces - N samples x M channel matrix of raw electrode data
%   # m - SVM model

% Outputs
%   # prediction - either a 0 or 1, corresponding to predicted left or
%       right hand movement, respectively

function [ prediction ] = get_prediction( traces, m )

L = length(traces);

left = get_fft_coeffs(mean(traces(:,1:2),2), L);
right = get_fft_coeffs(mean(traces(:,3:4),2), L);

left = left(1:60, :)';
right = right(1:60, :)';

size([left, right]);

prediction = predict(m, [left, right]);

end

