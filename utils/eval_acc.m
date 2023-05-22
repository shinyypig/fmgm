function acc = eval_acc(gt_list, pair_list)
    node_num = size(gt_list, 1);
    outliers = sum(gt_list(:, 1) == 0);
    node_num = node_num - outliers;
    acc = length(find(pdist2(pair_list, gt_list)== 0)) / node_num;
end
