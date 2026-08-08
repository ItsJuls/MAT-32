function wave = gen_sustained_voice(freq, numPartials, duration, Fs, brightness, seed)
% GEN_SUSTAINED_VOICE  Continuous (non-decaying) harmonic partial cluster
% for instruments with an ongoing energy source -- bow, breath,
% embouchure -- that can hold a note indefinitely, not just ring out.
%
% This is the structural difference from gen_partial_cluster.m: that one
% bakes exp(-t/tau) decay into every partial, because struck/plucked
% instruments only get one burst of energy. Bowed/blown instruments keep
% getting fed energy for as long as the note is held, so the DECAY here
% is left to synth_instrument_note.m's amplitude envelope (adsr_envelope,
% which can actually hold a sustain level -- exp_decay_envelope can't).
% Don't decay partials here AND apply an ADSR outside, or you'll double
% up the shaping and the note will die even while "sustaining."
%
%   wave = gen_sustained_voice(freq, numPartials, duration, Fs, brightness, seed)
%   freq        - fundamental (Hz)
%   numPartials - harmonic count. Woodwind (esp. clarinet, odd-heavy):
%                 6-10. Brass: 10-20 (brighter/more harmonically dense).
%   duration    - length in seconds (should cover the full note incl.
%                 however long the sustain will be held)
%   Fs          - sample rate in Hz
%   brightness  - partial rolloff exponent: amp = 1/k^brightness.
%                 ~0.6-0.8 = bright/brassy, ~1.2-1.6 = mellow/woody
%   seed        - RNG seed (only affects phase, so mostly cosmetic here)

if nargin < 6, seed = 1; end
rng(seed);

N = round(duration * Fs);
t = (0:N-1) / Fs;
wave = zeros(1, N);

for k = 1:numPartials
    partialFreq = k * freq;
    if partialFreq > 0.9 * (Fs/2)
        continue;
    end
    amp = 1 / (k ^ brightness);
    phase = 2*pi*rand();
    wave = wave + amp * sin(2*pi*partialFreq*t + phase);
end

peakVal = max(abs(wave));
if peakVal > 0
    wave = wave / peakVal;
end
end
