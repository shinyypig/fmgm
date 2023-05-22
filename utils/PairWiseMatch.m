function [Xs, acc] = PairWiseMatch(Ds, Vs, gt_list)
    [node_num, graph_num] = size(gt_list);

%     Ds = cell(graph_num);
%     Vs = cell(graph_num, 1);
%     for i = 1:graph_num
%         for j = 1:graph_num
%             if i ~= j
%                 S = similarity_gen(Fs([i, j]));
%                 [D, ~, ~] = factorized(Hs{i}, Hs{j}, S);
%                 Ds{i, j} = D;
%             end
%         end
%         Vs{i} = [Hs{i}{1, 1}, Hs{i}{1, 2}];
%     end

    Xs = zeros(graph_num*node_num);
    for i = 1:graph_num
        for j = i:graph_num
            if i ~= j
                X = RRWM(Ds{i, j}, Vs{i}, Vs{j}, [node_num, node_num]);
                Xs((i-1)*node_num+1:i*node_num, (j-1)*node_num+1:j*node_num) = X;
                Xs((j-1)*node_num+1:j*node_num, (i-1)*node_num+1:i*node_num) = X';
            else
                Xs((i-1)*node_num+1:i*node_num, (j-1)*node_num+1:j*node_num) = eye(node_num);
            end
        end
    end
    pair_list = [];
    for i = 1:graph_num
        P = Xs((i-1)*node_num+1:i*node_num, 1:node_num);
        [~, idx] = max(P, [], 1);
        pair_list = cat(2, pair_list, idx');
    end
    acc = eval_acc(gt_list, pair_list);
end


function X = RRWM(D, V1, V2, shape)
    alpha = 0.2;
    beta = 30;
    X = ones(shape);
    X_ = X;
    for t = 1:100
        dX = V1 * (D .* (V1' * X * V2)) * V2';
        Y = exp(beta*dX/max(dX(:)));
        Y = constrain2way(Y);
        Y = Y / sum(Y(:));
        X = alpha * X + (1 - alpha) * Y;
        X = X / sum(X, 'all');

        if max(abs(X_ - X), [], 'all') < 1e-4
            break;
        end
        X_ = X;
    end
    X = lap_solver(X);
end
