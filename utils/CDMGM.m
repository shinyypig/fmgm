function [pair_list, acc] = CDMGM(Ks, Xs, gt_list)
    [node_num, graph_num] = size(gt_list);
    
    [idx, Xs] = cal_score(Xs, graph_num, node_num);

    Xs_ = Xs;
    for t = 1:100
        tmp = Xs;
        score_ = eval_a(Xs, Ks, graph_num);
        for i = [1:idx-1, idx+1:graph_num]
            K = 0;
            for j = 1:graph_num
                if i ~= j
                    K = K + kron(Xs{j}, eye(node_num))' * Ks{i, j} * kron(Xs{j}, eye(node_num));
                end
            end
            Xs{i} = RRWM(K, [node_num, node_num]);

            if norm(Xs{i}(:) - tmp{i}(:)) ~= 0
                score = eval_a(Xs, Ks, graph_num);
                if score < score_
                    Xs = tmp;
                else
                    tmp = Xs;
                    score_ = score;
                end
            end
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


function [idx, Xs] = cal_score(Xs, graph_num, node_num)
    P = cell(graph_num);
    for i = 1:graph_num
        for j = 1:graph_num
            P{i, j} = Xs((i-1)*node_num+1:i*node_num, (j-1)*node_num+1:j*node_num);
        end
    end
    score = zeros(graph_num, 1);
    for i = 1:graph_num
        score(i) = calculate_C(P, i);
    end
    [~, idx] = max(score);
    Xs = cell(graph_num, 1);
    for i = idx
        for j = 1:graph_num
            Xs{j} = P{i, j}';
        end
    end
end

function score = eval_a(Xs, Ks, graph_num)
    score = 0;
    for i = 1:graph_num
        for j = [1:i-1, i+1:graph_num]
            Xij = Xs{i} * Xs{j}';
            score = score + Xij(:)' * Ks{i, j} * Xij(:);
        end
    end
end

function X = RRWM(K, shape)
    alpha = 0.2;
    beta = 30;
    X = ones(shape);
    X = X / sum(X, 'all');
    X_ = X;
%     K = sparse(K);
    for t = 1:100
        dX = reshape(K * X(:), shape);
        Y = exp(beta*dX/max(dX(:)));
        Y = constrain2way(Y);
        Y = Y / sum(Y(:));
        X = alpha * dX + (1 - alpha) * Y;
        X = dX / sum(X, 'all');

        if max(abs(X_ - X), [], 'all') < 1e-4
            break;
        end
        X_ = X;
    end
    X = lap_solver(X);
end

function C = calculate_C(Ps, k)
    graph_num = size(Ps, 1);
    node_num = size(Ps{1}, 1);
    e = 0;
    for i = 1:graph_num
        for j = i+1:graph_num
            e = e + sqrt(sum(abs(Ps{i, j} -  Ps{i, k} * Ps{k, j}), 'all'))/2;
        end
    end
    C = 1 - e / graph_num / (graph_num-1) / node_num * 2;
end
