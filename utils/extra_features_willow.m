function F = extra_features_willow(p, E)
    F1 = F1_gen(p);
    F2 = F2_gen(p.frame', E{2});
    F = {F1, F2};
end

function F1 = F1_gen(p)
    F1 = p.desc';
end

function F2 = F2_gen(p, E2)
    D = p(E2(:, 1), :) - p(E2(:, 2), :);
    A = abs(atan2(D(:, 1), D(:, 2))) / pi;
    F2 = [sqrt(sum(D.^2, 2)), A];
    F2(:, 1) = F2(:, 1) ./ max(F2(:, 1));
%     F2 = A;
%     F2 = sqrt(sum(D.^2, 2));
%     F2(:, 1) = F2(:, 1) ./ max(F2(:, 1));
end
