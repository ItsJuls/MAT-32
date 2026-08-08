function wave = gen_shimmer_noise(duration, Fs, bands)
% GEN_SHIMMER_NOISE  Sum of several band-limited noise layers, each with
% its own independent decay rate.
%
% Your existing gen_noise + apply_tvf sweep is a single band of noise
% whose brightness fades as ONE moving lowpass cutoff -- fine for a snare,
% but a real cymbal's "sizzle" is really several frequency regions dying
% out at different speeds simultaneously (the very top end flashes and is
% gone almost instantly; the mid-high region lingers much longer). Summing
% independently-decaying bands gets closer to that than one sweeping filter.
%
%   wave = gen_shimmer_noise(duration, Fs, bands)
%   bands - Nx3 matrix, each row = [loHz, hiHz, tauSeconds]
%           e.g. [4000 8000 0.8; 2000 4000 1.8; 800 2000 3.0]
%           (top band flashes and dies fast, lower bands linger)

N = round(duration * Fs);
t = (0:N-1) / Fs;
wave = zeros(1, N);

for i = 1:size(bands, 1)
    lo  = bands(i,1);
    hi  = min(bands(i,2), 0.98*(Fs/2));
    tau = bands(i,3);

    noise = randn(1, N);

    % RBJ bandpass biquad centered between lo/hi
    f0 = sqrt(lo*hi);
    bw_oct = log2(hi/lo);
    w0 = 2*pi*f0/Fs;
    alpha = sin(w0) * sinh( log(2)/2 * bw_oct * w0/sin(w0) );

    b0 =  alpha;
    b1 =  0;
    b2 = -alpha;
    a0 =  1 + alpha;
    a1 = -2*cos(w0);
    a2 =  1 - alpha;

    filtered = filter([b0 b1 b2]/a0, [1 a1/a0 a2/a0], noise);
    filtered = filtered .* exp(-t/tau);

    wave = wave + filtered;
end

peakVal = max(abs(wave));
if peakVal > 0
    wave = wave / peakVal;
end
end
