function shifted = pitch_shift_sample(sampleMono, sampleFs, baseFreq, targetFreq, Fs)


pitchRatio = targetFreq / baseFreq;

[p, q] = rat(pitchRatio * Fs / sampleFs, 1e-6);
shifted = resample(sampleMono, p, q);
end
