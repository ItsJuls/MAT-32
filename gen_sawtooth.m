function wave = gen_sawtooth(freq, duration, Fs)
t = (0:round(duration*Fs)-1) / Fs;
wave = sawtooth(2*pi*freq*t);
end