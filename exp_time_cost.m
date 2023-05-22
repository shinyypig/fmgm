clear;
% evaluated algorithms
alglist = {'MatchSync', 'MatchLift', 'MatchALS', 'JOMGM', 'CDMGM', 'FMGM'};

%% time vs node num
% number of graphs
graph_num = 3;
% number of nodes
node_num = 50:-5:10;
% number of runs
itr_num = 20;

tcost = zeros([length(node_num), length(alglist)]);
for i = 1:length(node_num)
    node_num_ = node_num(i);
    t_ = zeros(length(alglist), itr_num);
    parfor t = 1:itr_num
        [P, gt_list] = gen_points(graph_num, node_num_, 0.05);
        t_(:, t) = run_all(P, gt_list);
    end
    tcost(i, :) = mean(t_, 2);
    disp([num2str(i), '/', num2str(length(node_num))]);
end

%% plot the result
semilogy(node_num, tcost);
legend(alglist);
legend('Location', 'best');
drawnow;
save('./results/tcost1.mat', 'tcost');

%% time vs graph num
% number of graphs
graph_num = 20:-2:4;
% number of nodes
node_num = 20;
% number of runs
itr_num = 10;

tcost = zeros([length(node_num), length(alglist)]);
for i = 1:length(graph_num)
    graph_num_ = graph_num(i);
    t_ = zeros(length(alglist), itr_num);
    parfor t = 1:itr_num
        [P, gt_list] = gen_points(graph_num_, node_num, 0.05);
        t_(:, t) = run_all(P, gt_list);
    end
    tcost(i, :) = mean(t_, 2);
    disp([num2str(i), '/', num2str(length(graph_num))]);
end

%% plot the result
semilogy(graph_num, tcost);
legend(alglist);
legend('Location', 'best');
save('./results/tcost2.mat', 'tcost');

%%
function [P, gt_list] = gen_points(graph_num, node_num, noise)
    p = randn(node_num, 2);
    P = {};
    gt_list = (1:node_num)';
    P = cat(1, P, p + randn(size(p)) * noise);
    for i = 2:graph_num
        idx = randperm(node_num);
        P = cat(1, P, p(idx, :) + randn(size(p)) * noise);
        [~, idx] = max(idx' == 1:node_num, [], 1);
        gt_list = cat(2, gt_list, idx');
    end
end

function t = run_all(P, gt_list)
    [~, graph_num] = size(gt_list);
    % construct graphs from the points
    Hs = {};
    Fs = {};
    for i = 1:graph_num
        [H, F] = construct_graph(P{i}, 3, []);
        Hs = cat(1, Hs, {H});
        Fs = cat(1, Fs, {F});
    end
    % create the affinity matrices
    Ks = cell(graph_num);
    for i = 1:graph_num
        for j = 1:graph_num
            if i ~= j
                Ss = similarity_gen(Fs([i, j]));
                [L, V1, V2] = factorized(Hs{i}, Hs{j}, Ss);
                V = kron(V2, V1);
                K = V' * (L(:) .* V);
                Ks{i, j} = abs(K);
            end
        end
    end

    % generate the factorizations of the affinity matrices
    Ds = cell(graph_num);
    Vs = cell(graph_num, 1);
    for i = 1:graph_num
        for j = 1:graph_num
            if i ~= j
                S = similarity_gen(Fs([i, j]));
                [D, ~, ~] = factorized(Hs{i}, Hs{j}, S);
                Ds{i, j} = D;
            end
        end
        Vs{i} = [Hs{i}{1, 1}, Hs{i}{1, 2}];
    end

    tic;
    [Xs, ~] = PairWiseMatch(Ds, Vs, gt_list);
    t1 = toc;

    tic;
    MatchSync(Xs, gt_list);
    t2 = toc;

    tic;
    MatchLift(Xs, gt_list);
    t3 = toc;

    tic;
    MatchALS(Xs, gt_list);
    t4 = toc;

    tic;
    JOMGM(Ks, gt_list);
    t5 = toc;

    tic;
    CDMGM(Ks, Xs, gt_list);
    t6 = toc;

    tic;
    FMGM(Ds, Vs, Xs, gt_list);
    t7 = toc;

    %in JOMGM, the pairwise matching result is not needed
    t = [t2 t3 t4 t5 - t1 t6 t7] + t1;
end
