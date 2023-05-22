function X = constrain2way(X)
    X_ = X;
    for t = 1:100
        X = X ./ (sum(X, 1) + 1e-5);
        X = X ./ (sum(X, 2) + 1e-5);
        if mean(abs(X - X_), 'all') < 1e-5
            break;
        end
        X_ = X;
    end
end
