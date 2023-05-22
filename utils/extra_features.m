function F = extra_features(p, E, im)
    if isempty(im)
        F1 = [];
    else
        F1 = F1_gen(p, im);
    end
    F2 = F2_gen(p, E{2});
    F = {F1, F2};
end

function F1 = F1_gen(p, im)
    F1 = [];
end

function F2 = F2_gen(p, E2)
    D = p(E2(:, 1), :) - p(E2(:, 2), :);
    F2 = [sqrt(sum(D.^2, 2))];
%     F2 = F2 ./ max(F2);
end
