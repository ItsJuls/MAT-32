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

    rawSynth = zeros(1, length(t));
    for k = 1:6
        amplitude = 1 / (k^1.5);
        rawSynth = rawSynth + amplitude * sin(2 * pi * k * baseFreq * t);
    end

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