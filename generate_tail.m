function [rawTail, isSustained] = generate_tail(patch, freq, Fs)
% GENERATE_TAIL  Dispatch by patch.family. This is the whole "add a new
% instrument" surface -- five families, each mapping to one of two
% underlying generators (gen_partial_cluster for one-shot decaying
% instruments, gen_sustained_voice for continuously-energized ones).
%
%   [rawTail, isSustained] = generate_tail(patch, freq, Fs)
%   patch.family - 'keyboard' | 'pluckedString' | 'percussion' |
%                  'bowedString' | 'woodwind' | 'brass'
%   freq         - note frequency (Hz). Ignored only for a fully
%                  unpitched percussion patch (partialMix near 0).
%   isSustained  - true if this family holds a level rather than always
%                  decaying -- tells synth_instrument_note.m whether to
%                  use adsr_envelope (real sustain) or exp_decay_envelope.

switch lower(patch.family)

    % ---- ONE-SHOT: struck/plucked, energy only at the start ----
    case 'keyboard'      % piano, electric piano, mallet keyboards
        numPartials = getf(patch, 'numPartials', 16);
        randomness  = getf(patch, 'randomness', 0.02);   % near-pure harmonic
        rawTail = gen_partial_cluster(freq, numPartials, patch.tailDuration, ...
            Fs, getf(patch,'tailTau',2.5), randomness, getf(patch,'freqSpread',6), getf(patch,'seed',1));
        isSustained = false;

    case 'pluckedstring' % guitar, harp, pizzicato, harpsichord
        numPartials = getf(patch, 'numPartials', 20);
        randomness  = getf(patch, 'randomness', 0.0);    % purest harmonic of the three
        rawTail = gen_partial_cluster(freq, numPartials, patch.tailDuration, ...
            Fs, getf(patch,'tailTau',3.5), randomness, getf(patch,'freqSpread',6), getf(patch,'seed',1));
        isSustained = false;

    case 'percussion'    % cymbal, gong, tom, snare, woodblock
        % NOTE: freqSpread and numPartials are the two levers that decide
        % "cymbal" (dense, wide, noisy) vs "gong" (sparse, low, tonal).
        numPartials = getf(patch, 'numPartials', 150);
        randomness  = getf(patch, 'randomness', 0.9);
        freqSpread  = getf(patch, 'freqSpread', 14);
        partialMix  = getf(patch, 'partialMix', 0.45);
        ampRolloffHz = getf(patch, 'ampRolloffHz', 2500);
        tau = getf(patch,'tailTau',3.0);

        % --- Tonal ring fades FASTER than the noise floor ---
        % Measured against a real recording: real cymbal spectral
        % flatness goes from ~0.01 (tonal/ringing) early to ~0.33
        % (near-pure hiss) by the end -- the metallic RING dies out well
        % before the broadband HISS does, so the tail of a real cymbal
        % is mostly just fading noise. If cluster and noise decay on the
        % same timescale, that mix ratio never shifts and it just sounds
        % like one static blend the whole way through. clusterTauScale
        % < 1 makes the tonal partials die faster than the noise layer,
        % so the balance genuinely shifts from ring -> hiss over time.
        clusterTauScale = getf(patch, 'clusterTauScale', 0.55);
        noiseTauScale   = getf(patch, 'noiseTauScale', 1.3);

        clusterA = gen_partial_cluster(freq, numPartials, patch.tailDuration, ...
            Fs, tau*clusterTauScale, randomness, freqSpread, getf(patch,'seed',1), ampRolloffHz);
        clusterB = gen_partial_cluster(freq*1.03, round(numPartials*0.6), patch.tailDuration, ...
            Fs, tau*clusterTauScale*0.85, randomness, freqSpread*0.7, getf(patch,'seed',1)+97, ampRolloffHz);
        cluster = clusterA * 0.65 + clusterB * 0.35;
        cluster = cluster / max(abs(cluster));

        bands = getf(patch, 'shimmerBands', [4000 8000 tau*noiseTauScale*0.5; ...
                                              2000 4000 tau*noiseTauScale*1.0;  ...
                                               800 2000 tau*noiseTauScale*1.6]);
        noiseLayer = gen_shimmer_noise(patch.tailDuration, Fs, bands);
        rawTail = cluster * partialMix + noiseLayer * (1 - partialMix);
        isSustained = false;

    % ---- SUSTAINED: continuously energized, can hold a level ----
    case 'bowedstring'   % violin, cello, double bass
        numPartials = getf(patch, 'numPartials', 14);
        voice = gen_sustained_voice(freq, numPartials, patch.tailDuration, Fs, ...
            getf(patch,'brightness',1.0), getf(patch,'seed',1));
        bowNoise = gen_shimmer_noise(patch.tailDuration, Fs, ...
            getf(patch,'noiseBands', [2000 6000 patch.tailDuration*100]));  % huge tau = effectively flat/no internal decay
        noiseAmount = getf(patch, 'noiseAmount', 0.06);
        rawTail = voice * (1-noiseAmount) + bowNoise * noiseAmount;
        isSustained = true;

    case 'woodwind'       % flute, clarinet, oboe, sax
        numPartials = getf(patch, 'numPartials', 8);
        voice = gen_sustained_voice(freq, numPartials, patch.tailDuration, Fs, ...
            getf(patch,'brightness',1.3), getf(patch,'seed',1));
        breathNoise = gen_shimmer_noise(patch.tailDuration, Fs, ...
            getf(patch,'noiseBands', [3000 9000 patch.tailDuration*100]));
        noiseAmount = getf(patch, 'noiseAmount', 0.12);  % audibly breathier than a bow
        rawTail = voice * (1-noiseAmount) + breathNoise * noiseAmount;
        isSustained = true;

    case 'brass'          % trumpet, trombone, horn, tuba
        numPartials = getf(patch, 'numPartials', 18);
        voice = gen_sustained_voice(freq, numPartials, patch.tailDuration, Fs, ...
            getf(patch,'brightness',0.7), getf(patch,'seed',1));  % denser highs = brassy edge
        buzzNoise = gen_shimmer_noise(patch.tailDuration, Fs, ...
            getf(patch,'noiseBands', [1500 4000 patch.tailDuration*100]));
        noiseAmount = getf(patch, 'noiseAmount', 0.03);  % least noisy of the sustained families
        rawTail = voice * (1-noiseAmount) + buzzNoise * noiseAmount;
        isSustained = true;

    otherwise
        error('generate_tail:unknownFamily', ...
            'Unknown patch.family "%s". Expected keyboard | pluckedString | percussion | bowedString | woodwind | brass.', ...
            patch.family);
end

rawTail = rawTail / max(abs(rawTail));
end

function v = getf(s, field, default)
if isfield(s, field)
    v = s.(field);
else
    v = default;
end
end