function X = IPFP(K, shape)
    X = ones(shape);
    X_ = X;
    for t = 1:100
        b = lap_solver(reshape(K * X(:), shape));
        C = X(:)' * K * (b(:) - X(:));
        D = (b(:) - X(:))' * K * (b(:) - X(:));
        if D >= 0
            X = b;
        else
            r = min([-C/D, 1]);
            X = X + r * (b - X);
        end
        if max(abs(X - X_), [], 'all') < 1e-4
            break;
        end
        X_ = X;
    end
    X = lap_solver(X);
end
