function outWave = apply_tvf(wave, Fs, cutoffEnv, resonance)
% APPLY_TVF  Time Variant Filter -- a resonant lowpass filter whose cutoff
% frequency moves over time, driven by its own envelope (separate from the
% amplitude/TVA envelope). This is what takes a raw, buzzy sawtooth/square
% wave and gives it a real, evolving timbre instead of sounding flat and
% "8-bit". Roland's DCO -> TVF -> TVA chain is the core of LA synthesis;
% right now your patches only have DCO -> TVA, which is why the sustain
% portion sounds harsh/thin no matter what waveform you pick.
%
%   outWave = apply_tvf(wave, Fs, cutoffEnv, resonance)
%   wave      - input waveform (row vector), e.g. output of gen_sawtooth
%   Fs        - sample rate in Hz
%   cutoffEnv - per-sample cutoff frequency in Hz, same length as wave
%               (typically built with tvf_cutoff_envelope.m)
%   resonance - filter Q / resonance, > 0.5. Higher = more "peaky"/resonant.
%               0.707 is a gentle, non-resonant lowpass. Try 1-4 for character.

N = length(wave);
outWave = zeros(1, N);

% Direct Form I biquad state
x1 = 0; x2 = 0;
y1 = 0; y2 = 0;

for n = 1:N
    fc = min(max(cutoffEnv(n), 20), Fs/2 - 100); % clamp to safe range
    w0 = 2*pi*fc/Fs;
    alpha = sin(w0) / (2*resonance);
    cosw0 = cos(w0);

    b0 = (1 - cosw0)/2;
    b1 =  1 - cosw0;
    b2 = (1 - cosw0)/2;
    a0 =  1 + alpha;
    a1 = -2*cosw0;
    a2 =  1 - alpha;

    x0 = wave(n);
    y0 = (b0*x0 + b1*x1 + b2*x2 - a1*y1 - a2*y2) / a0;

    outWave(n) = y0;

    x2 = x1; x1 = x0;
    y2 = y1; y1 = y0;
end
end
