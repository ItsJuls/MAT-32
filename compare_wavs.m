% COMPARE_WAVS - Mathematical analysis of original vs synth
% HEADLESS VERSION: no live figure window, no graphics_toolkit dependency.
% Run with octave-cli.exe. Errors print in full; nothing depends on a
% display or GUI toolkit being available.

1;  % forces Octave to treat this file as a script (needed because a
    % local function is defined below) rather than treating the first
    % function as the entry point.

% ================================================================
% LOCAL FUNCTIONS -- must be defined BEFORE they're called further
% down (Octave does not hoist trailing local functions in scripts).
% ================================================================
function [tOut, rmsOut, centroidOut] = shortTimeAnalysis(wave, Fs, winT, hopT)
% Frame-by-frame RMS and spectral centroid.
% Uses a hand-rolled periodic Hann window instead of the signal
% package's hann() -- removes a dependency that could silently fail if
% the package isn't fully loaded, and this is a one-line formula anyway.

    winSamples = round(winT * Fs);
    hopSamples = round(hopT * Fs);
    N = length(wave);
    numFrames = max(1, floor((N - winSamples) / hopSamples) + 1);

    tOut = zeros(1, numFrames);
    rmsOut = zeros(1, numFrames);
    centroidOut = zeros(1, numFrames);

    win = 0.5 - 0.5*cos(2*pi*(0:winSamples-1)/winSamples);  % periodic Hann
    freqs = (0:winSamples-1) * (Fs / winSamples);
    halfN = floor(winSamples/2);

    for i = 1:numFrames
        startIdx = (i-1)*hopSamples + 1;
        endIdx = min(N, startIdx + winSamples - 1);
        frame = zeros(1, winSamples);
        frame(1:(endIdx-startIdx+1)) = wave(startIdx:endIdx);
        frameWin = frame .* win;

        tOut(i) = (startIdx - 1) / Fs;
        rmsOut(i) = sqrt(mean(frame.^2));

        mag = abs(fft(frameWin));
        mag = mag(1:halfN);
        f = freqs(1:halfN);
        totalMag = sum(mag);
        if totalMag > 0
            centroidOut(i) = sum(f .* mag) / totalMag;
        else
            centroidOut(i) = 0;
        end
    end
end

% ================================================================
% MAIN SCRIPT
% ================================================================
pkg load signal;

% 1. Load the files
[origWave, origFs] = audioread(strcat('guitar.wav'));
[synthWave, synthFs] = audioread('la_synth_matched_output.wav');

if size(origWave, 2) > 1, origWave = mean(origWave, 2); end
if size(synthWave, 2) > 1, synthWave = mean(synthWave, 2); end
origWave = origWave(:).';
synthWave = synthWave(:).';

% 2. Calculate Exact Values
origPeak = max(abs(origWave));
synthPeak = max(abs(synthWave));
origRMS = sqrt(mean(origWave.^2));
synthRMS = sqrt(mean(synthWave.^2));

fprintf('\n--- AMPLITUDE ANALYSIS ---\n');
fprintf('ORIGINAL: Peak = %.4f | RMS (Avg Energy) = %.4f\n', origPeak, origRMS);
fprintf('SYNTH:    Peak = %.4f | RMS (Avg Energy) = %.4f\n', synthPeak, synthRMS);
fprintf('--------------------------\n');

tOrig = (0:length(origWave)-1) / origFs;
tSynth = (0:length(synthWave)-1) / synthFs;

% 3. Short-time RMS + spectral centroid over time
winT = 0.05;
hopT = 0.025;

try
    [origRmsT, origRmsVals, origCentroidVals] = shortTimeAnalysis(origWave, origFs, winT, hopT);
    [synthRmsT, synthRmsVals, synthCentroidVals] = shortTimeAnalysis(synthWave, synthFs, winT, hopT);
    fprintf('Short-time analysis complete: %d orig frames, %d synth frames.\n', ...
        length(origRmsT), length(synthRmsT));
catch err
    fprintf('!!! shortTimeAnalysis FAILED: %s\n', err.message);
    rethrow(err);
end

% 4. Build figure OFF-SCREEN
try
    fig = figure('visible', 'off');

    subplot(4,1,1);
    plot(tOrig, origWave, 'b', 'DisplayName', 'Original');
    hold on;
    plot(tSynth, synthWave, 'r', 'DisplayName', 'Synthesized');
    title('Full Waveform: Original vs Synthesized');
    xlabel('Time (s)'); ylabel('Amplitude');
    legend; grid on;

    ZOOM_START  = 0.02;
    ZOOM_WINDOW = 0.03;
    subplot(4,1,2);
    origMask  = tOrig  >= ZOOM_START & tOrig  <= (ZOOM_START + ZOOM_WINDOW);
    synthMask = tSynth >= ZOOM_START & tSynth <= (ZOOM_START + ZOOM_WINDOW);
    plot(tOrig(origMask), origWave(origMask), 'b', 'DisplayName', 'Original');
    hold on;
    plot(tSynth(synthMask), synthWave(synthMask), 'r', 'DisplayName', 'Synthesized');
    title(sprintf('Zoomed: %.0f-%.0fms (individual cycles)', ZOOM_START*1000, (ZOOM_START+ZOOM_WINDOW)*1000));
    xlabel('Time (s)'); ylabel('Amplitude');
    legend; grid on;

    subplot(4,1,3);
    plot(origRmsT, origRmsVals, 'b', 'DisplayName', 'Original');
    hold on;
    plot(synthRmsT, synthRmsVals, 'r', 'DisplayName', 'Synthesized');
    title('Short-Time RMS (loudness envelope over time)');
    xlabel('Time (s)'); ylabel('RMS');
    legend; grid on;

    subplot(4,1,4);
    plot(origRmsT, origCentroidVals, 'b', 'DisplayName', 'Original');
    hold on;
    plot(synthRmsT, synthCentroidVals, 'r', 'DisplayName', 'Synthesized');
    title('Spectral Centroid over time (brightness -- higher = brighter/harsher)');
    xlabel('Time (s)'); ylabel('Centroid (Hz)');
    legend; grid on;
catch err
    fprintf('!!! Plot build FAILED: %s\n', err.message);
    rethrow(err);
end

% 5. Export PNG + CSV
outDir = pwd;
fprintf('Current working directory: %s\n', outDir);

pngPath = fullfile(outDir, 'compare_wavs_analysis.png');
try
    print(fig, pngPath, '-dpng', '-r150');
    fprintf('Saved plot to %s\n', pngPath);
catch err
    fprintf('!!! PNG export FAILED: %s\n', err.message);
end
close(fig);

n = max(length(origRmsT), length(synthRmsT));
padTo = @(v) [v(:); nan(n - length(v), 1)];

csvPath = fullfile(outDir, 'compare_wavs_metrics.csv');
fid = fopen(csvPath, 'w');
if fid == -1
    error('Could not open %s for writing -- check the path exists and is writable.', csvPath);
end

fprintf(fid, 'time_s,orig_rms,orig_centroid_hz,synth_rms,synth_centroid_hz\n');
tCol      = padTo(origRmsT);
origRmsC  = padTo(origRmsVals);
origCenC  = padTo(origCentroidVals);
synthRmsC = padTo(synthRmsVals);
synthCenC = padTo(synthCentroidVals);
for i = 1:n
    fprintf(fid, '%.4f,%.6f,%.2f,%.6f,%.2f\n', ...
        tCol(i), origRmsC(i), origCenC(i), synthRmsC(i), synthCenC(i));
end
fclose(fid);
fprintf('Saved metrics to %s\n', csvPath);
fprintf('DONE.\n');