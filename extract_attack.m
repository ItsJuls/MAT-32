% ================================================================
% LA_SYNTH: Attack Transient Extractor
% ================================================================

% 1. Configuration
inputFile = 'guitar.wav';  % Replace with your raw audio file
outputFile = 'guitar_attack.wav';   % The file your LA synth will use

noiseGateDb = -40;     % Threshold to detect where the note actually starts
searchWindowT = 0.5;   % Look for the peak within the first 0.5 seconds
padMs = 25;            % How much of the natural decay to keep after the peak
fadeOutMs = 10;        % Micro fade-out at the end to prevent crossfade clicks

% 2. Load and prep the audio
[wav, Fs] = audioread(inputFile);

% Downmix to mono if stereo
if size(wav, 2) > 1
    wav = mean(wav, 2);
end

% 3. Trim leading silence (Find the exact onset)
peakVol = max(abs(wav));
gateThreshold = peakVol * 10^(noiseGateDb / 20);
startIdx = find(abs(wav) > gateThreshold, 1, 'first');

if isempty(startIdx)
    error('Audio is too quiet or empty. Lower the noiseGateDb.');
end

% Back up slightly (5ms) to catch the very beginning of the zero-crossing
startIdx = max(1, startIdx - round(0.005 * Fs));
wav = wav(startIdx:end);

% 4. Find the attack peak (using an amplitude envelope)
envWin = max(1, round(0.003 * Fs)); % 3ms smoothing window
envelope = movmean(abs(wav), envWin);

searchSamples = min(length(wav), round(searchWindowT * Fs));
[~, peakIdx] = max(envelope(1:searchSamples));

% 5. Cut the sample with padding
padSamples = round(padMs / 1000 * Fs);
endIdx = min(length(wav), peakIdx + padSamples);
attackWave = wav(1:endIdx);

% 6. Apply a gentle half-cosine fade-out to prevent clicks
fadeSamples = round(fadeOutMs / 1000 * Fs);
if fadeSamples > length(attackWave)
    fadeSamples = floor(length(attackWave) / 2);
end

% Create the fade curve (1 down to 0)
theta = linspace(0, pi/2, fadeSamples)';
fadeCurve = cos(theta);

% Apply it to the tail end of the attack wave
attackWave(end-fadeSamples+1:end) = attackWave(end-fadeSamples+1:end) .* fadeCurve;

% 7. Normalize to 1.0 (0 dBFS)
attackWave = attackWave / max(abs(attackWave));

% 8. Save the file
audiowrite(outputFile, attackWave, Fs);

fprintf('Extracted %d ms transient and saved to %s\n', round(length(attackWave)/Fs * 1000), outputFile);