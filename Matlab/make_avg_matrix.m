function [ avg_matrix ] = make_avg_matrix( data )

Fs = 96;
samples = length(data);
channels = min(size(data));
sec = samples / Fs;

avg_matrix = zeros(sec, channels);

for x = 1:sec
    start = (x-1)*Fs + 1;
    stop = x*Fs;
    avg_matrix(x,:) = mean(data(start:stop, :));
end

%avg_matrix = mean(avg_matrix, 2);

end

