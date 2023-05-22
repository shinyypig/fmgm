function [H, F] = construct_graph(p, k, im)
    E = gen_edges(p, k);
    H = construct_incidence_matrices(E);
    F = extra_features(p, E, im);
end

function H = construct_incidence_matrices(E)
% construct the incidence matrices according to the feature information
    H = cell(2);
    for i = 1:2
        for j = i:2
            H{i, j} = find_incidence(E{i}, E{j});
            H{j, i} = H{i, j}';
        end
    end
end

function H = find_incidence(Ea, Eb)
% find the incidence matrix between features Ea and Eb
    [na, ma] = size(Ea);
    [nb, mb] = size(Eb);
    if ma > mb
        flag = 1;
        [Eb, Ea] = deal(Ea, Eb);
        [nb, na] = deal(na, nb);
        [mb, ma] = deal(ma, mb);
    else
        flag = 0;
    end
    if ma == mb
        H = eye(na);
        return;
    end

    H = zeros(na, nb);
    cnum = nchoosek(mb, ma);

    for i = 1:size(Eb, 1)
        C = nchoosek(Eb(i, :), ma);
        for j = 1:cnum
            idx = mean(Ea == C(j, :), 2) == 1;
            H(idx, i) = 1;
        end
    end

    if flag
        H = H';
    end
end
