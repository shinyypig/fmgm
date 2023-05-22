function E = gen_edges(p, k)
% generate the features with the edges that are connected
% between nearest k nodes
%     E2 = [];
%     Idx = knnsearch(p, p, 'K', 3);
%     for i = 1:size(p, 1)
%         for j = 2:k
%             E2 = cat(1, E2, [i, Idx(i, j)]);
%         end
%     end
    
    E2 = [];
    dt = delaunay(p);
    E2 = cat(1, E2, [dt(:, 1), dt(:, 2)]);
    E2 = cat(1, E2, [dt(:, 1), dt(:, 3)]);
    E2 = cat(1, E2, [dt(:, 2), dt(:, 3)]);
    E2 = rm_extra(E2);

%     rho = 0.5;
%     E2 = nchoosek(1:length(p), 2);
%     ilist = rand(size(E2, 1), 1);
%     E2(ilist > rho, :) = [];

    E1 = (1:size(p, 1))';
    
    E = {E1, E2};
end

function E = rm_extra(E)
    E = sort(E, 2);
    i = 1;
    while true
        if i >= size(E, 1)
            break
        end
        d = sum(abs(E(i, :) - E(i+1:end, :)), 2);
        Idx = find(d == 0) + i;
        E(Idx, :) = [];
        i = i+1;
    end
end