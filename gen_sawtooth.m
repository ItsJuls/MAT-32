function wave = gen_sawtooth(freq, duration, Fs)
% GEN_SAWTOOTH  Band-limited sawtooth wave using additive synthesis.
% This prevents the harsh "aliasing" buzz caused by the built-in
% geometric sawtooth function.

t = (0:round(duration*Fs)-1) / Fs;
wave = zeros(1, length(t));

% The Nyquist limit is exactly half the sample rate.
% We cannot generate any frequencies above this.
nyquist = Fs / 2;

% Figure out exactly how many harmonics we can fit before crossing Nyquist
max_harmonic = floor(nyquist / freq);

% Build the sawtooth by stacking sine waves (harmonics)
for k = 1:max_harmonic
    % Add each harmonic, dividing its amplitude by its harmonic number (k)
    wave = wave + sin(2 * pi * k * freq * t) / k;
end

% Normalize the final wave so it fits perfectly between -1.0 and 1.0
peakVal = max(abs(wave));
if peakVal > 0
    wave = wave / peakVal;
end

end