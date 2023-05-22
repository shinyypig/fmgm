function [pair_list, acc] = JOMGM(Ks, gt_list)
    [node_num, graph_num] = size(gt_list);
    
    Xs = cell(graph_num, 1);
    Xs{1} = eye(node_num);
    for i = 2:graph_num
        Xs{i} = ones(node_num) / node_num^2;
    end
    Xs_ = Xs;
    for t = 1:100
        for i = 2:graph_num
            K = 0;
            for j = 1:graph_num
                if i ~= j
                    K = K + kron(Xs{j}, eye(node_num))' * Ks{i, j} * kron(Xs{j}, eye(node_num));
                end
            end
            Xs{i} = IPFP(K, [node_num, node_num]);
        end
        
        e = [];
        for i = 2:graph_num
            e = cat(1, e, max(abs(Xs_{i} - Xs{i}), [], 'all'));
        end
        if max(e) < 1e-4
            break;
        end
        Xs_ = Xs;
    end

    P = {};
    for i = 1:graph_num
        P = cat(1, P, lap_solver(Xs{i}));
    end
    pair_list = [];
    for i = 1:graph_num
        [~, idx] = max(P{i}, [], 1);
        pair_list = cat(2, pair_list, idx');
    end

    acc = eval_acc(gt_list, pair_list);
end