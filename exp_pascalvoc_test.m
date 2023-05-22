%%
clear; close all;
% evaluated algorithms
alglist = {'Origin', 'MatchSync', 'MatchLift', 'MatchALS', 'JOMGM', 'CDMGM', 'FMGM'};
base_folder = './data/PascalVOC/';
folders = dir(base_folder);

idx = zeros([length(folders), 1]);
for i = 1:length(folders)
    if folders(i).isdir
        if folders(i).name(1) ~= '.'
            idx(i) = 1;
        end
    end
end
idx = idx == 1;
folders = folders(idx);

objs = {};
for i = 1:length(folders)
    objs = cat(1, objs, folders(i).name);
end
% objs = {'cat', 'car'};
%%
itr_num = 500;
graph_num_list = 6;

% tic;
acc = [];
for k = 1:length(objs)
    obj = objs{k};
    folder = [base_folder, obj];
    disp(obj);
    for i = 1:length(graph_num_list)
        graph_num = graph_num_list(i);
        acc_ = zeros([itr_num, length(alglist)]);
        parfor t = 1:itr_num
            [kpts, gt_list] = load_kpts(folder, graph_num);
            acc_(t, :) = run_all(kpts, gt_list);
        end
        acc = cat(1, acc, mean(acc_, 1));
        disp(mean(acc_, 1));
    end
    %     toc;
end
disp(mean(acc, 1));
% save(['./results/voc_', num2str(graph_num), '.mat'], 'acc');

%%
[~, idx] = max(acc, [], 2);

disp(sum(idx == 7))

%%
function [kpts, gt_list] = load_kpts(folder, graph_num)
    kpts = {};
    files = dir([folder, filesep, '*_feature.mat']);
    sel_list = [];
    while true
        idx = randi(length(files), 1);
        if isempty(find(idx == sel_list, 1))
            kpt = importdata([files(idx).folder, filesep, files(idx).name]);
            if kpt.nfeature > 4
                kpt.nfeature = 4;
                kpt.frame = kpt.frame(:, 1:4);
                kpt.desc = kpt.desc(1:4, :)';
                kpts = cat(1, kpts, kpt);
            else
                kpt.desc = kpt.desc';
                kpts = cat(1, kpts, kpt);
            end
            sel_list = cat(1, sel_list, idx);
        end
        if length(sel_list) == graph_num
            break;
        end
    end

    gt_list = double(1:kpt.nfeature)' * ones(1, graph_num);
    %     gt_list = (1:kpt.nfeature)';
    %     for i = 2:graph_num
    %         list = randperm(kpt.nfeature);
    %         kpts{i}.desc = kpts{i}.desc(:, list);
    %         kpts{i}.frame = kpts{i}.frame(:, list);
    %         [~, idx] = max(gt_list(:, 1) == list, [], 2);
    %         gt_list = cat(2, gt_list, idx);
    %     end
    %     gt_list = double(gt_list);
end

function acc = run_all(P, gt_list)
    [~, graph_num] = size(gt_list);
    Hs = {};
    Fs = {};
    for i = 1:graph_num
        [H, F] = construct_graph_willow(P{i}, 3);
        Hs = cat(1, Hs, {H});
        Fs = cat(1, Fs, {F});
    end

    Ks = cell(graph_num);
    for i = 1:graph_num
        for j = 1:graph_num
            if i ~= j
                Ss = similarity_gen_willow(Fs([i, j]));
                Ss{2} = Ss{2} * 0.1;
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
                S = similarity_gen_willow(Fs([i, j]));
                S{2} = S{2} * 0.1;
                [D, ~, ~] = factorized(Hs{i}, Hs{j}, S);
                Ds{i, j} = D;
            end
        end
        Vs{i} = [Hs{i}{1, 1}, Hs{i}{1, 2}];
    end

    [Xs, a1] = PairWiseMatch(Ds, Vs, gt_list);
    [~, a2] = MatchSync(Xs, gt_list);
    [~, a3] = MatchLift(Xs, gt_list);
    [~, a4] = MatchALS(Xs, gt_list);
    [~, a5] = JOMGM(Ks, gt_list);
    [~, a6] = CDMGM(Ks, Xs, gt_list);
    [~, a7] = FMGM(Ds, Vs, Xs, gt_list);

    acc = [a1 a2 a3 a4 a5 a6 a7];
end
