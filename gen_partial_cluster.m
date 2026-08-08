function wave = gen_partial_cluster(freq, numPartials, duration, Fs, tauBase, randomness, freqSpread, seed, ampRolloffHz)
% GEN_PARTIAL_CLUSTER  One-shot decaying partial cluster covering the
% whole range from a pure piano-like harmonic tone to a fully-random
% cymbal-like inharmonic wash, controlled by a single "randomness" knob.
% Replaces gen_harmonic_cluster.m and gen_modal_cluster.m -- those were
% the same idea (N decaying partials, higher ones dying faster) with two
% different partial-ratio strategies hardcoded. This makes the strategy
% a continuous parameter instead of two separate files.
%
%   wave = gen_partial_cluster(freq, numPartials, duration, Fs, tauBase, randomness, freqSpread, seed)
%   freq        - fundamental (Hz). Still required even at randomness=1;
%                 it's the base the random ratios are built on top of.
%   numPartials - how many partials. Piano: ~16. Cymbal: ~100+.
%   duration    - length in seconds
%   Fs          - sample rate in Hz
%   tauBase     - decay time constant (s) for partial 1
%   randomness  - 0 = pure harmonic series (piano/plucked string),
%                 1 = fully random ratios (cymbal/gong/metal).
%                 Values in between smoothly blend -- e.g. 0.3-0.4 gets
%                 you a "detuned bell"/tuned-but-clangy character, useful
%                 for things like tuned percussion (marimba, vibraphone).
%   freqSpread  - only matters as randomness increases toward 1: random
%                 ratios are drawn from [1, freqSpread]. Ignored at
%                 randomness=0.
%   seed        - RNG seed

if nargin < 8, seed = 1; end
if nargin < 9, ampRolloffHz = 900; end   % lower = brighter/wider spectrum, less "gong"-y concentration in the lows
rng(seed);

N = round(duration * Fs);
t = (0:N-1) / Fs;
wave = zeros(1, N);

for k = 1:numPartials
    harmonicRatio = k * sqrt(1 + 0.0002 * k^2);   % piano-style slight inharmonicity
    randomRatio   = 1 + (freqSpread - 1) * rand();
    ratio = (1 - randomness) * harmonicRatio + randomness * randomRatio;

    partialFreq = freq * ratio;
    if partialFreq > 0.9 * (Fs/2)
        continue;
    end

    tauHarmonic = tauBase / (1 + (k-1) * 0.35);
    tauModal    = tauBase / (1 + (partialFreq/1200)^1.3);
    tau = (1 - randomness) * tauHarmonic + randomness * tauModal;

    ampHarmonic = 1 / k;
    ampModal    = 1 / (1 + partialFreq/ampRolloffHz);
    amp = (1 - randomness) * ampHarmonic + randomness * ampModal;

    phase = 2*pi*rand();
    wave = wave + amp * sin(2*pi*partialFreq*t + phase) .* exp(-t/tau);
end

peakVal = max(abs(wave));
if peakVal > 0
    wave = wave / peakVal;
end
end
