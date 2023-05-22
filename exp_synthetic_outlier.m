%%
clear; close all;
% number of runs
itr_num = 100;
% number of graphs
graph_num = 3;
% number of nodes in each graph
node_num = 10;

% evaluated algorithms
alglist = {'Origin', 'MatchSync', 'MatchLift', 'MatchALS', 'JOMGM', 'CDMGM', 'FMGM'};

%%
% set the range of the number of outliers
num = 6;
outlier = 0:num - 1;

acc = zeros([num, length(alglist)]);
acc_ = zeros([itr_num, length(alglist)]);
tic;
for i = 1:num
    outlier_ = outlier(i);
    parfor t = 1:itr_num
        % randomly generate points
        [P, gt_list] = gen_points(graph_num, node_num, outlier_);
        % run all methods
        acc_(t, :) = run_all(P, gt_list);
    end
    acc(i, :) = acc(i, :) + mean(acc_, 1);
    disp([num2str(i), '/', num2str(num)]);
end
toc;

%%
% plot the results
figure, plot(outlier, acc);
legend(alglist, 'Location', 'best');
% save(['./results/acc_outlier_', num2str(graph_num), '.mat'], 'acc');

%%
function [P, gt_list] = gen_points(graph_num, node_num, outlier)
    % randomly generate point sets with outliers
    inlier = node_num - outlier;
    p = randn(inlier, 2);
    P = {};
    gt_list = [];
    for i = 1:graph_num
        idx = randperm(inlier);
        P = cat(1, P, [p(idx, :); randn(outlier, 2)]);
        [~, idx] = max(idx' == 1:inlier, [], 1);
        gt_list = cat(2, gt_list, idx');
    end
    gt_list = cat(1, gt_list, zeros(outlier, graph_num));
end
