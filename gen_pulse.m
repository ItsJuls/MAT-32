function wave = gen_pulse(freq, duration, Fs, dutyCycle)
% GEN_PULSE  Band-limited pulse/square wave using additive synthesis.
% This replaces the built-in square() function to prevent digital aliasing whine.

t = (0:round(duration*Fs)-1) / Fs;
wave = zeros(1, length(t));

% The Nyquist limit is exactly half the sample rate.
% We cannot generate any frequencies above this without causing aliasing.
nyquist = Fs / 2;
max_harmonic = floor(nyquist / freq);

% Build the pulse wave by stacking harmonics
for k = 1:max_harmonic
    % The amplitude of each harmonic is determined by the duty cycle
    amp = sin(pi * k * dutyCycle) / k;

    % Use cosine to properly align the phases of the harmonics for a pulse
    wave = wave + amp * cos(2 * pi * k * freq * t);
end

% Normalize the final wave so it fits perfectly between -1.0 and 1.0
peakVal = max(abs(wave));
if peakVal > 0
    wave = wave / peakVal;
end

end