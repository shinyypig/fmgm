function S = similarity_gen_willow(Fs)
    graph_num = length(Fs);
    feature_num = length(Fs{1});
    S = {};
    sigma = [0.3, 0.1];
    for i = 1:feature_num
        F = {};
        for j = 1:graph_num
            F = cat(1, F, Fs{j}{i});
        end
        if isempty(F)
            S = cat(1, S, {[]});
        else
            S = cat(1, S, similarity(F, sigma(i)));
        end
    end
end

function S = similarity(F, sigma)
    S = pdist2(F{1}, F{2});
    S = S / max(S(:));
    S = exp(- S / sigma);
    S = S ./ max(S(:));
end
