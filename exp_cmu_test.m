%%
clear; close all;
% load the keypoints
cmum = importdata('./cmum/cmum.mat');
% select cmu house or cmu hotel
% points = cmum.house.XTs;
points = cmum.hotel.XTs;

for i = 1:length(points)
    points{i} = points{i}';
end

% number of runs
itr_num = 2000;
% number of graphs
graph_num = 4:1:12;

% evaluated algorithms
alglist = {'Origin', 'MatchSync', 'MatchLift', 'MatchALS', 'JOMGM', 'CDMGM', 'FMGM'};

%%
acc = zeros([length(graph_num), 7]);
tic;
for i = 1:length(graph_num)
    a = zeros(itr_num, 7);
    graph_num_ = graph_num(i);
    parfor t = 1:itr_num
        % randomly select graphs from the dataset
        [P, gt_list] = random_select(points, graph_num_);
        a(t, :) = run_all(P, gt_list);
    end
    acc(i, :) = mean(a, 1);
    disp([num2str(i), '/', num2str(length(graph_num))]);
end
toc;

%%
% plot the result
plot(graph_num, acc);
legend(alglist, 'Location', 'best');
% save('./results/cmu_house_.mat', 'acc');
save('./results/cmu_hotel_.mat', 'acc');

function [P, gt_list] = random_select(points, k)
    % randomly select graphs from the dataset
    idx = randperm(length(points), k);
    P = points(idx);
    sel = randperm(length(P{1}), 10);
    for i = 1:k
        P{i} = P{i}(sel, :);
    end
    gt_list = (1:size(P{1}, 1))' * ones(1, k);
end
