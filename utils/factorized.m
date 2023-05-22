function [L, V1, V2] = factorized(H1, H2, S)
    V1 = [H1{1, 1}, H1{1, 2}]';
    V2 = [H2{1, 1}, H2{1, 2}]';
    
    if isempty(S{1})
        K11 = H1{1, 2} * S{2} * H2{2, 1};
    else
        K11 = H1{1, 2} * S{2} * H2{2, 1} + S{1};
    end

    K12 = - H1{1, 2} * S{2};

    K21 = - S{2} * H2{2, 1};

    K22 = S{2};

    L = [K11 K12;
         K21 K22];
    
end
