function wave = gen_pulse(freq, duration, Fs, dutyCycle)
t = (0:round(duration*Fs)-1) / Fs;
wave = square(2*pi*freq*t, dutyCycle*100);
end