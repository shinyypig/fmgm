%%
clear; close all;
% load the keypoints
cmum = importdata('./cmum/cmum.mat');

% select cmu house or cmu hotel data
% points = cmum.house.XTs;
points = cmum.hotel.XTs;

for i = 1:length(points)
    points{i} = points{i}';
end

% number of runs
itr_num = 500;
% the sequence gap
gap = 1:2:20;
% number of graphs
graph_num = 4;

% number of inliers/outliers in each graph
inliers = 10;
outliers = 2;

% evaluated algorithms
alglist = {'Origin', 'MatchSync', 'MatchLift', 'MatchALS', 'JOMGM', 'CDMGM', 'FMGM'};
%%
% create empty variables to save accuracy
acc = zeros([length(gap), length(alglist)]);

tic;
for i = 1:length(gap)
    a = zeros(itr_num, length(alglist));
    gap_ = gap(i);
    parfor t = 1:itr_num
        % randomly select graphs from the dataset
        [P, gt_list] = random_select(points, gap_, graph_num, inliers, outliers);
        % run all methods
        a(t, :) = run_all(P, gt_list);
    end
    acc(i, :) = mean(a, 1);
    disp([num2str(i), '/', num2str(length(gap))]);
end
toc;
%%
% plot the result
plot(gap, acc);
legend(alglist, 'Location', 'best');

% remember to uncomment the corresponding save code
% save(['./results/cmu_house_', num2str(outliers), '.mat'], 'acc');
save(['./results/cmu_hotel_', num2str(outliers), '.mat'], 'acc');

%%
function [P, gt_list] = random_select(points, gap, graph_num, inliers, outliers)
    % randomly select graphs from the dataset
    num = length(points);
    % caculate the maximum value of the base index
    base = num - gap * graph_num - 1;
    % randomly generate the indices with specific sequence gap
    % the indices are: randi(base), randi(base)+gap, randi(base)+2*gap, ...
    idx = randi(base) + (0:gap:(gap*graph_num));

    % select the images with generated indices
    P = points(idx);
    
    % randomly select the inliers
    sel = randperm(length(P{1}), inliers);
    gt_list = [];
    for i = 1:graph_num
        % randomly permuate the order of the points
        idx = randperm(inliers);
        P{i} = P{i}(sel(idx), :);
        % add outliers
        P{i} = cat(1, P{i}, rand([outliers, 2])*500);
        % create the correspondence
        [~, idx] = max(idx' == 1:inliers, [], 1);
        gt_list = cat(2, gt_list, idx');
    end
    gt_list = cat(1, gt_list, zeros(outliers, graph_num));
end
