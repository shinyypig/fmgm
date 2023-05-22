%%
clear;
% evaluated algorithms
alglist = {'Origin', 'MatchSync', 'MatchLift', 'MatchALS', 'JOMGM', 'CDMGM', 'FMGM'};
folders = dir('./data/pf-willow/');
%%
acc = [];
% generate the true matching result
gt_list = (1:10)' * ones(1, 10);
for i = 1:length(folders)
    if folders(i).name(1) ~= '.'
        % load data
        kpts = load_kpts([folders(i).folder, filesep, folders(i).name]);
        a = run_all(kpts, gt_list);
        acc = cat(1, acc, a);
        disp(folders(i).name);
        disp(a);
    end
end
%%
function kpts = load_kpts(path)
    kpts = {};
    files = dir([path, filesep, '*kpts.mat']);
    for i = 1:length(files)
        kpt = importdata([files(i).folder, filesep, files(i).name]);
        if kpt.nfeature == 10
            kpts = cat(1, kpts, kpt);
        end
    end
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

    [Xs, a1] = PairWiseMatch(Ds, Vs, gt_list);
    [~, a2] = MatchSync(Xs, gt_list);
    [~, a3] = MatchLift(Xs, gt_list);
    [~, a4] = MatchALS(Xs, gt_list);
    [~, a5] = JOMGM(Ks, gt_list);
    [~, a6] = CDMGM(Ks, Xs, gt_list);
    [~, a7] = FMGM(Ds, Vs, Xs, gt_list);

    acc = [a1 a2 a3 a4 a5 a6 a7];
end
