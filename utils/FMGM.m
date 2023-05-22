function [pair_list, acc] = FMGM(Ds, Vs, Xs, gt_list)
    % Hs: incidence matrices
    % Fs: features of nodes and edges
    % Xs: pairwise matching result
    % gt_list: the true matching result

    % the parameters of RRWM
    alpha = 0.2;
    beta = 30;

    % get the numbers of nodes and graphs
    [node_num, graph_num] = size(gt_list);
    
    % determine the virtual graph according to the pairwise matching result
    [idx, Xs, P] = find_virtual_graph(Xs, graph_num, node_num);

    Xs_ = Xs;
    tmp = Xs;
    % calculate the overall objective score of the initial solution
    score_ = cal_score(tmp, Ds, Vs);

    % global updating
    for t = 1:100
        for i = [1:idx-1, idx+1:graph_num]
    
            Xs{i} = ones(size(Xs{i}));
            Xs{i} = Xs{i} / sum(Xs{i}, 'all');
            X_ = Xs{i};
            for p = 1:100
                X = 0;
                % calculate the global gradient
                for j = 1:graph_num
                    if i ~= j
                        X = X + Vs{i} * (Ds{i, j} .* (Vs{i}' * (Xs{i} * Xs{j}') * Vs{j})) * Vs{j}' * Xs{j};
                    end
                end
                % update according to RRWM
                Y = exp(beta*X/max(X(:)));
                Y = constrain2way(Y);
                Y = Y / sum(Y(:));
                Xs{i} = alpha * X + (1 - alpha) * Y;
                Xs{i} = Xs{i} / sum(Xs{i}, 'all');
                if max(abs(X_ - Xs{i}), [], 'all') < 1e-3
                    break;
                end
                X_ = Xs{i};
            end
            
            % discretize the solution
%             Xs{i} = mat2gray(Xs{i}) > 0.5;
            Xs{i} = lap_solver(Xs{i});
            % decide whether save the updated result
            if norm(Xs{i}(:) - tmp{i}(:)) ~= 0
                score = cal_score(Xs, Ds, Vs);
                if score < score_
                    Xs = tmp;
                else
                    tmp = Xs;
                    score_ = score;
                end
            end
        end

        % check the convergence of the solution
        e = [];
        for i = 2:graph_num
            e = cat(1, e, max(abs(Xs_{i} - Xs{i}), [], 'all'));
        end
        if max(e) < 1e-4
            break;
        end
        Xs_ = Xs;
    end

    % local updating
    for t = 1:100
        for i = [1:idx-1, idx+1:graph_num]
            for j = 1:graph_num
                if i ~= j
                    Xs{i} = ones(size(Xs{i}));
                    Xs{i} = Xs{i} / sum(Xs{i}, 'all');
                    X_ = Xs{i};
                    for p = 1:100
                        % calculate the local gradient
                        X = Vs{i} * (Ds{i, j} .* (Vs{i}' * (Xs{i} * Xs{j}') * Vs{j})) * Vs{j}' * Xs{j};
                        % update according to RRWM
                        Y = exp(beta*X/max(X(:)));
                        Y = constrain2way(Y);
                        Y = Y / sum(Y(:));
                        Xs{i} = alpha * X + (1 - alpha) * Y;
                        Xs{i} = Xs{i} / sum(Xs{i}, 'all');
                        if max(abs(X_ - Xs{i}), [], 'all') < 1e-3
                            break;
                        end
                        X_ = Xs{i};
                    end
%                     Xs{i} = Xs{j} * P{j, i};
                    % discretize the solution
%                     Xs{i} = mat2gray(Xs{i}) > 0.5;
                    Xs{i} = lap_solver(Xs{i});
                    % decide whether save the updated result
                    if norm(Xs{i}(:) - tmp{i}(:)) ~= 0
                        score = cal_score(Xs, Ds, Vs);
                        if score < score_
                            Xs = tmp;
                        else
                            tmp = Xs;
                            score_ = score;
                        end
                    end
                end
            end
        end
    
        % check the convergence of the solution
        e = [];
        for i = 2:graph_num
            e = cat(1, e, max(abs(Xs_{i} - Xs{i}), [], 'all'));
        end
        if max(e) < 1e-4
            break;
        end
        Xs_ = Xs;
    end

    % evaluate the accuracy of the matching result
    pair_list = [];
    for i = 1:graph_num
        [~, idx] = max(Xs{i}, [], 1);
        pair_list = cat(2, pair_list, idx');
    end
    
    acc = eval_acc(gt_list, pair_list);

end

function [idx, Xs, P] = find_virtual_graph(Xs, graph_num, node_num)
    % find the best low-rank approximation
    P = cell(graph_num);
    for i = 1:graph_num
        for j = 1:graph_num
            P{i, j} = Xs((i-1)*node_num+1:i*node_num, (j-1)*node_num+1:j*node_num);
        end
    end
    e = zeros(graph_num, 1);
    for i = 1:graph_num
        e(i) = cal_error(P, i);
    end
    [~, idx] = min(e);
    Xs = cell(graph_num, 1);
    for i = idx
        for j = 1:graph_num
            Xs{j} = P{i, j}';
        end
    end
end

function e = cal_error(Ps, k)
    % calculate ||W - Uk'Uk||
    graph_num = size(Ps, 1);
    e = 0;
    for i = 1:graph_num
        for j = i+1:graph_num
            e = e + sqrt(sum(abs(Ps{i, j} -  Ps{i, k} * Ps{k, j}), 'all'))/2;
        end
    end
end

function score = cal_score(Xs, Ds, Vs)
    % calculate the objective score of the solution
    score = 0;
    graph_num = length(Vs);
    for i = 1:graph_num
        for j = [1:i-1, i+1:graph_num]
            score = score + sum(Ds{i, j} .* (Vs{i}' * (Xs{i} * Xs{j}') * Vs{j}).^2, 'all');
        end
    end
end
