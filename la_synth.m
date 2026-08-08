% ================================================================
% LA Synthesis: Data-Matched Guitar Pluck
% ================================================================
pkg load signal;

% 1. LOAD THE SAMPLE
[rawSample, Fs] = audioread('guitar_attack.wav');

% Downmix to mono and ensure it is a row vector
if size(rawSample, 2) > 1
    rawSample = mean(rawSample, 2);
end
rawSample = rawSample(:)';

% 2. AUTOMATIC PITCH DETECTION
[r, lags] = xcorr(rawSample, 'coeff');
r = r(lags > 0);
lags = lags(lags > 0);

minLag = round(Fs / 1000);
maxLag = round(Fs / 70);
[~, peakLoc] = max(r(minLag:maxLag));
truePeakLoc = peakLoc + minLag - 1;

freq = Fs / truePeakLoc;
fprintf('Detected sample pitch: %.2f Hz\n', freq);

% 3. ISOLATE THE ATTACK TRANSIENT
% Capture past the 0.125s peak identified in the metrics
attackDuration = 0.15;
attackSamples = min(round(attackDuration * Fs), length(rawSample));
attackWave = rawSample(1:attackSamples);

% 4. SYNTHESIZE THE MATCHING TAIL
tailDuration = 12.0; % Extended to match the physical decay time
t = (0 : round(tailDuration * Fs) - 1) / Fs;

% Additive synthesis with independent harmonic decay
synthTail = zeros(1, length(t));
baseTau = 2.6; % The fundamental frequency's decay time constant

for k = 1:6
    % Higher harmonics have lower amplitude (warmer tone)
    amplitude = 1 / (k^1.5);

    % Higher harmonics decay much faster (mimics natural string dampening)
    tau_k = baseTau / (k^1.2);

    harmonic = amplitude * sin(2 * pi * k * freq * t) .* exp(-t / tau_k);
    synthTail = synthTail + harmonic;
end

% Match the volume of the synth to the exact end of the attack sample
tailStartLevel = max(abs(attackWave(end-50:end)));
synthTail = synthTail * (tailStartLevel / max(abs(synthTail)));

% 5. CROSSFADE AND STITCH
crossfadeTime = 0.02; % 20ms equal-power crossfade
xfadeSamples = round(crossfadeTime * Fs);

totalLength = length(attackWave) + length(synthTail) - xfadeSamples;
finalAudio = zeros(1, totalLength);

% Insert Attack
finalAudio(1:length(attackWave)) = attackWave;

% Crossfade region
if xfadeSamples > 0
    fadeOut = linspace(1, 0, xfadeSamples);
    fadeIn  = linspace(0, 1, xfadeSamples);

    xfadeStart = length(attackWave) - xfadeSamples + 1;
    xfadeEnd   = length(attackWave);

    finalAudio(xfadeStart:xfadeEnd) = (attackWave(xfadeStart:xfadeEnd) .* fadeOut) + ...
                                      (synthTail(1:xfadeSamples) .* fadeIn);
end

% Insert Tail
finalAudio(length(attackWave)+1:end) = synthTail(xfadeSamples+1:end);

% 6. NORMALIZE & EXPORT
finalAudio = finalAudio / max(abs(finalAudio));
audiowrite('la_synth_matched_output.wav', finalAudio, Fs);

disp('Synthesis complete! Playing audio...');
sound(finalAudio, Fs);

% 7. VISUALIZE FOR CLASS
figure;
plot((0:length(finalAudio)-1)/Fs, finalAudio);
title(sprintf('LA Synthesis (Matched perfectly at %.1f Hz)', freq));
xlabel('Time (seconds)');
ylabel('Amplitude');