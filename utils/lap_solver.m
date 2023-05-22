function P = lap_solver(S)
%     [m, n] = size(S);
%     flag = 0;
%     if m > n
%         S = S';
%         [m, n] = size(S);
%         flag = 1;
%     end
%     s = S(:);
%     
%     C = kron(eye(n), ones([m, 1]))';
%     Ceq = kron(ones([n, 1]), eye(m))';
%     options = optimoptions('linprog', 'Display', 'off');
%     p = linprog(-s, C, ones([n, 1]), Ceq, ones([m, 1]), zeros([m*n, 1]), [], [], options);
%     P = reshape(p, [m, n]);
%     if flag == 1
%         P = P';
%     end
    
    ind2 = munkres(-S)';
    [n1, n2] = size(S);
    % index -> matrix
    if n1 <= n2
        idx = sub2ind([n1 n2], 1 : n1, ind2');
    else
        ind1 = find(ind2);
        ind2 = ind2(ind1);
        idx = sub2ind([n1 n2], ind1', ind2');
    end
    P = zeros(n1, n2);
    P(idx) = 1;
end
