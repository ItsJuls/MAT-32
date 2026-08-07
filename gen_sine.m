function wave = gen_sine(freq, duration, Fs)
t = (0:round(duration*Fs)-1) / Fs;
wave = sin(2*pi*freq*t);
end
