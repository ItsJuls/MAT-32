function [sampleMono, sampleFs] = load_attack_sample(wavPath)
[raw, sampleFs] = audioread(wavPath);


if size(raw, 2) > 1
    raw = mean(raw, 2);
end


sampleMono = raw(:).';


peakVal = max(abs(sampleMono));
if peakVal > 0
    sampleMono = sampleMono / peakVal;
end
end
