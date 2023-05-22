%%
clear; close all;
% number of runs
itr_num = 200;
% number of graphs
graph_num = 3;
% number of nodes in each graph
node_num = 10;

% evaluated algorithms
alglist = {'Origin', 'MatchSync', 'MatchLift', 'MatchALS', 'JOMGM', 'CDMGM', 'FMGM'};

%%
% set the range of the standard deviation of noise
num = 10;
noise = linspace(0, 0.2, num);
acc = zeros([num, length(alglist)]);
acc_ = zeros([itr_num, length(alglist)]);
tic;
for i = 1:num
    noise_ = noise(i);
    parfor t = 1:itr_num
        % randomly generate points
        [P, gt_list] = gen_points(graph_num, node_num, noise_);
        % run all methods
        acc_(t, :) = run_all(P, gt_list);
    end
    acc(i, :) = acc(i, :) + mean(acc_, 1);
    disp([num2str(i), '/', num2str(num)]);
end
toc;

%%
% plot the results
figure, plot(noise, acc);
legend(alglist, 'Location', 'best');
% save(['./results/acc_noise_', num2str(graph_num), '.mat'], 'acc');
%%
function [P, gt_list] = gen_points(graph_num, node_num, noise)
    % randomly generate point sets with noise
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
