function wave = gen_noise(duration, Fs)
% GEN_NOISE  Generate white noise as a sustain "waveform" for percussive,
% inharmonic sounds (cymbals, snares, hi-hats) where a tonal oscillator
% (sine/square/sawtooth) would be wrong -- those instruments have no clear
% pitch, so a tuned sustain would sound like a synth note bleeding in
% underneath the hit instead of a natural decay.
%
% Paired with apply_tvf sweeping the cutoff downward over time, this
% recreates how a real cymbal decays: bright and full of high-frequency
% shimmer right after the strike, settling into a darker, low rumble as
% the high frequencies die out first.
%
%   wave = gen_noise(duration, Fs)
%   duration - length of the wave in seconds
%   Fs       - sample rate in Hz
N = round(duration * Fs);
wave = randn(1, N);
wave = wave / max(abs(wave)); % normalize so it behaves like the other gen_* outputs
end
