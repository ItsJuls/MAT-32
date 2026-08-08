% =========================================================================
% APP DESIGNER UI INSTRUCTIONS (READ ME!)
% =========================================================================
% HEY! If you are building the App Designer (.mlapp) UI, here is what you
% need to know to hook it up to this backend function.
%
% 1. UI COMPONENTS TO BUILD:
%    Drag and drop these into the app and name them exactly like this:
%    - 3x UIAxes: app.TopUIAxes, app.MiddleUIAxes, app.BottomUIAxes
%    - 3x Knobs:
%        * app.SAMPLETRIMKnob (Range: 0.01 to 0.50, Default: 0.15)
%        * app.BASEFREQHzKnob (Range: 20 to 1000, Default: 110)
%        * app.LAMIXKnob      (Range: 0.0 to 2.0, Default: 1.0)
%    - 4x Vertical Sliders (ADSR):
%        * app.ASlider (Range: 0.0 to 2.0, Default: 0.01)
%        * app.DSlider (Range: 0.0 to 5.0, Default: 2.6)
%        * app.SSlider (Range: 0.0 to 1.0, Default: 0.0)
%        * app.RSlider (Range: 0.0 to 2.0, Default: 0.5)
%    - 1x Button: Trigger Note
%
% 2. WHAT THIS FUNCTION RETURNS:
%    When you call this function, it hands back 4 variables:
%    - attackWave : The trimmed real audio (Plot this in TopUIAxes)
%    - synthTail  : The math-generated ADSR wave (Plot this in MiddleUIAxes)
%    - finalAudio : The combined crossfaded sound (Plot this in BottomUIAxes)
%    - Fs         : The sample rate (Pass this into sound() so it plays)
%
% 3. THE CALLBACK CODE:
%    Right-click your "Trigger Note" button, select Callbacks > Add,
%    and paste this exact code inside the function it creates:
%
%    filePath = 'guitar_attack.wav';
%    trim = app.SAMPLETRIMKnob.Value;
%    freq = app.BASEFREQHzKnob.Value;
%    mix  = app.LAMIXKnob.Value;
%
%    A = app.ASlider.Value;
%    D = app.DSlider.Value;
%    S = app.SSlider.Value;
%    R = app.RSlider.Value;
%
%    [attack, tail, combined, Fs] = processLASynth(filePath, trim, freq, mix, A, D, S, R);
%
%    plot(app.TopUIAxes, attack);
%    plot(app.MiddleUIAxes, tail);
%    plot(app.BottomUIAxes, combined);
%    sound(combined, Fs);
%
% =========================================================================

function [attackWave, synthTail, finalAudio, Fs] = processLASynth(wavFilePath, trimTime, baseFreq, laMixLevel, A, D, S, R)

    if nargin < 5
        A = 0.01;
        D = 2.60;
        S = 0.00;
        R = 0.50;
    end

    [rawSample, Fs] = audioread(wavFilePath);
    if size(rawSample, 2) > 1
        rawSample = mean(rawSample, 2);
    end
    rawSample = rawSample(:)';

    attackSamples = min(round(trimTime * Fs), length(rawSample));
    attackWave = rawSample(1:attackSamples);

    tailDuration = 4.0;
    t = (0 : round(tailDuration * Fs) - 1) / Fs;


    k = (1:6)';


    amplitudes = 1 ./ (k.^1.5);


    rawSynth = sum(amplitudes .* sin(2 * pi * k * baseFreq * t), 1);

    envelope = generateADSR(A, D, S, R, length(t), Fs);
    synthTail = rawSynth .* envelope;

    tailStartLevel = max(abs(attackWave(end-50:end)));

    maxTail = max(abs(synthTail));
    if maxTail > 0
        synthTail = synthTail * (tailStartLevel / maxTail) * laMixLevel;
    end

    crossfadeTime = 0.02;
    xfadeSamples = round(crossfadeTime * Fs);

    totalLength = length(attackWave) + length(synthTail) - xfadeSamples;
    finalAudio = zeros(1, totalLength);

    finalAudio(1:length(attackWave)) = attackWave;

    if xfadeSamples > 0 && length(attackWave) > xfadeSamples
        fadeOut = linspace(1, 0, xfadeSamples);
        fadeIn  = linspace(0, 1, xfadeSamples);

        xfadeStart = length(attackWave) - xfadeSamples + 1;
        xfadeEnd   = length(attackWave);

        finalAudio(xfadeStart:xfadeEnd) = (attackWave(xfadeStart:xfadeEnd) .* fadeOut) + ...
                                          (synthTail(1:xfadeSamples) .* fadeIn);
    end

    finalAudio(length(attackWave)+1:end) = synthTail(xfadeSamples+1:end);

    peakVol = max(abs(finalAudio));
    if peakVol > 0
        finalAudio = finalAudio / peakVol;
    end
end

function env = generateADSR(A, D, S, R, totalSamples, Fs)
    a_samp = round(A * Fs);
    d_samp = round(D * Fs);
    r_samp = round(R * Fs);

    s_samp = totalSamples - a_samp - d_samp - r_samp;

    envA = linspace(0, 1, a_samp);

    tD = linspace(0, 5, d_samp);
    envD = S + (1 - S) * exp(-tD);

    envS = ones(1, max(0, s_samp)) * S;

    tR = linspace(0, 5, r_samp);
    envR = S * exp(-tR);

    env = [envA, envD, envS, envR];

    if length(env) > totalSamples
        env = env(1:totalSamples);
    elseif length(env) < totalSamples
        env = [env, zeros(1, totalSamples - length(env))];
    end
end