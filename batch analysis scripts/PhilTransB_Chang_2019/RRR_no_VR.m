% Batch analysis for reactivation
% Context:      Phil. Trans. B 2019 manuscript prelim analysis
% Data folder:  Adam's old computer (AKA my computer) E:\HaoRan\RRR\ {RSC036-38}

clear all
list = {'RSC036', 'RSC037', 'RSC038'};
% list = {'EE001_new', 'PCH017'};
% list = {'PCH017'};
% list = {'RSC032'};
% list = {'RSC036'};

%% Batch analysis

for f = 1:length(list)
    
    root = dir(list{f});
    root(1:2) = [];
    
    for i = 1:length(root)
        clear lfp;
        full = fullfile(root(i).folder, root(i).name);
        
%         load(fullfile(full, '2', 'Plane1', 'deconv.mat'));
%         lfp = LFP(fullfile(full, [root(i).name '_2.abf']));
%         lfp.import_deconv(deconv);
%         lfp.perform_analysis;
%         analysis = lfp.analysis;
%         save(fullfile(full, 'analysis.mat'), 'analysis');
%         save(fullfile(full, 'lfp2.mat'), 'lfp');
%         disp(['Got ' num2str(length(analysis.pc_list)) ' place cells out of ' num2str(size(deconv,2))])

        load(fullfile(full, 'analysis.mat'));
        
        clear lfp;
        clear ass
        load(fullfile(full, '1', 'Plane1', 'deconv.mat'));
        lfp = LFP(fullfile(full, [root(i).name '_1.abf']));
        lfp.import_deconv(deconv);
        lfp.import_analysis(analysis);
%         lfp.remove_mvt;
        lfp.detect_sce;
        ass = lfp.ensemble;
        ass.set_ops('clust_method','silhouette');
        ass.set_ops('order','cluster');
        ass.cluster;
        ass.plot('tree');
        save(fullfile(full, 'lfp1.mat'), 'lfp');
        save(fullfile(full, 'ass1.mat'), 'ass');
        
        clear lfp;
        clear ass
        load(fullfile(full, '3', 'Plane1', 'deconv.mat'));
        lfp = LFP(fullfile(full, [root(i).name '_3.abf']));
        lfp.import_deconv(deconv);
        lfp.import_analysis(analysis);
%         lfp.remove_mvt;
        lfp.detect_sce;
        ass = lfp.ensemble;
        ass.set_ops('clust_method','silhouette');
        ass.set_ops('order','cluster');
        ass.cluster;
        ass.plot('tree');
        save(fullfile(full, 'lfp3.mat'), 'lfp');
        save(fullfile(full, 'ass3.mat'), 'ass');
    end
    
end


%% Remake analysis
for f = 1:length(list)
    
    root = dir(list{f});
    root(1:2) = [];
    
    for i = 1:length(root)
        clear lfp;
        full = fullfile(root(i).folder, root(i).name);
        
        if exist(fullfile(full, 'ass3.mat'),'file')
            load(fullfile(full, 'lfp2.mat'));
            lfp.perform_analysis;
            analysis = lfp.analysis;
            save(fullfile(full, 'analysis.mat'), 'analysis');
            save(fullfile(full, 'lfp2.mat'), 'lfp');
            disp(['Got ' num2str(length(analysis.pc_list)) ' place cells out of ' num2str(length(analysis.psth))])
        end
    end
    
end


%% Plot correlation

for f = 1:length(list)
    root = dir(list{f});
    root(1:2) = [];
    
    for i = 1:length(root)
        clear lfp;
        full = fullfile(root(i).folder, root(i).name);
        
        if exist(fullfile(full, 'ass3.mat'),'file')
            load(fullfile(full, 'lfp2.mat'));
            order=get_order(lfp.analysis);
            
            load(fullfile(full, 'lfp1.mat'));
            figure;
            subplot(1,3,1);
            deconv=lfp.deconv(:,order);
            deconv(any(isnan(deconv),2),:)=[];
            deconv=ca_filt(deconv);
            deconv=zscore(deconv);
            deconv=fast_smooth(deconv,2);
            imagesc(corr(deconv));
            axis square;
            colormap jet
            
            load(fullfile(full, 'lfp2.mat'));
            subplot(1,3,2);
            deconv=lfp.deconv(:,order);
            deconv(any(isnan(deconv),2),:)=[];
            deconv=ca_filt(deconv);
            deconv=zscore(deconv);
            deconv=fast_smooth(deconv,2);
            imagesc(corr(deconv));
            axis square;
            colormap jet
            
            load(fullfile(full, 'lfp3.mat'));
            subplot(1,3,3);
            deconv=lfp.deconv(:,order);
            deconv(any(isnan(deconv),2),:)=[];
            deconv=ca_filt(deconv);
            deconv=zscore(deconv);
            deconv=fast_smooth(deconv,2);
            imagesc(corr(deconv));
            axis square;
            colormap jet
            
            title(['Mouse :' list{f} ' Date: ' root(i).name]);
        end
        
    end
    
end

%% Spatial Info, Sparsity, recording length and other stats

session = struct('animal',[],'date',[], 'rest1', [], 'rest2', [], 'frac_overlap',[], 'null_frac',[], 'hypergeo_p',[]);
session.rest1 = struct('SI_clust',[], 'SI_no_clust',[], 'sparsity_clust',[], 'sparsity_no_clust',[], 'recording_frac', [],...
                        'clust_size',[], 'clust_num',[], 'clust_frac',[], 'xcoef',[], 'err',[], 'err_sem',[], 'err_all',[], 'err_sem_all',[], ...
                        'err_no_clust',[], 'err_sem_no_clust',[], 'frac_pc',[], 'frac_pc_clust',[], ...
                        'width',[], 'all_width',[], 'norm_width',[], 'stack_all',[], 'stack_clust',[], 'stack_no_clust',[], ...
                        'null_err',[]);
session.rest2 = session.rest1;

shuffles = 1000;
count=1;

for f = 1:length(list)
    root = dir(list{f});
    root(1:2) = [];
    
    for i = 1:length(root)
        clear lfp;
        full = fullfile(root(i).folder, root(i).name);
        
        if exist(fullfile(full, 'ass3.mat'),'file')
            load(fullfile(full, 'analysis.mat'));
            
            load(fullfile(full, 'ass1.mat'));
            session(count).rest1.SI_clust = analysis.SI(cell2mat(ass.clust));
            session(count).rest1.SI_no_clust = analysis.SI(setxor(cell2mat(ass.clust), 1:length(analysis.psth)));
            session(count).rest1.sparsity_clust = analysis.sparsity(cell2mat(ass.clust));
            session(count).rest1.sparsity_no_clust = analysis.sparsity(setxor(cell2mat(ass.clust), 1:length(analysis.psth)));
            session(count).rest1.recording_frac = sum(~any(isnan(ass.deconv),2)) / size(ass.deconv,1);
            session(count).rest1.clust_size = cellfun(@length, ass.clust);
            session(count).rest1.clust_num = length(ass.clust);
            session(count).rest1.clust_frac = length(cell2mat(ass.clust)) / size(ass.deconv, 2);
            session(count).rest1.clust_frac_clust = cellfun(@length, ass.clust) ./ size(ass.deconv, 2);
            r1_clust = ass.clust;
            session(count).rest1.xcoef = arrayfun(@(x) max(xcorr(belt_idx, mean(analysis.stack(:,ass.clust{x}),2), 'coeff')), 1:length(ass.clust));
            
            null_err = zeros(length(ass.clust),50,shuffles);
            parfor ii = 1:shuffles
                sample = arrayfun(@(x) randperm(length(analysis.psth), x), cellfun(@length, ass.clust), 'uniformoutput',false);
                [~,~,temp] = bayes_infer(analysis, .05, sample);
                null_err(:, :, ii) = temp(2:end,:);
            end
            session(count).rest1.null_err = null_err;
            
            [~,~,session(count).rest1.err,session(count).rest1.err_sem]=bayes_infer(analysis,.05,r1_clust);
            [~,~,session(count).rest1.err_all,session(count).rest1.err_sem_all]=bayes_infer(analysis,.05,{cell2mat(r1_clust)});
            [~,~,session(count).rest1.err_no_clust,session(count).rest1.err_sem_no_clust]=bayes_infer(analysis,.05,{setxor(cell2mat(r1_clust), 1:length(analysis.psth))});
            width = analysis.width(cell2mat(ass.clust));
            idx = ~cellfun(@isempty, width);
            width = cell2mat(width(idx)');
            session(count).rest1.width = width;
            width = analysis.width;
            idx = ~cellfun(@isempty, width);
            width = cell2mat(width(idx)');
            session(count).rest1.all_width = width;
            session(count).rest1.norm_width = accumarray(session(count).rest1.width, 1, [50 50]) ./ accumarray(width, 1, [50 50]);
            session(count).rest1.stack_clust = analysis.stack(:,cell2mat(ass.clust));
            session(count).rest1.stack_no_clust = analysis.stack(:,setxor(cell2mat(ass.clust), 1:length(analysis.psth)));
            session(count).rest1.stack_all = analysis.stack;
            session(count).rest1.frac_pc_clust = length(intersect(analysis.pc_list, cell2mat(r1_clust))) / length(cell2mat(r1_clust));
            session(count).rest1.frac_pc = length(analysis.pc_list) / length(analysis.psth);
            
            load(fullfile(full, 'ass3.mat'));
            session(count).rest2.SI_clust = analysis.SI(cell2mat(ass.clust));
            session(count).rest2.SI_no_clust = analysis.SI(setxor(cell2mat(ass.clust), 1:length(analysis.psth)));
            session(count).rest2.sparsity_clust = analysis.sparsity(cell2mat(ass.clust));
            session(count).rest2.sparsity_no_clust = analysis.sparsity(setxor(cell2mat(ass.clust), 1:length(analysis.psth)));
            session(count).rest2.recording_frac = sum(~any(isnan(ass.deconv),2)) / size(ass.deconv,1);
            session(count).rest2.clust_size = cellfun(@length, ass.clust);
            session(count).rest2.clust_num = length(ass.clust);
            session(count).rest2.clust_frac = length(cell2mat(ass.clust)) / size(ass.deconv, 2);
            session(count).rest2.clust_frac_clust = cellfun(@length, ass.clust) ./ size(ass.deconv, 2);
            r2_clust = ass.clust;
            session(count).rest2.xcoef = arrayfun(@(x) max(xcorr(belt_idx, mean(analysis.stack(:,ass.clust{x}),2), 'coeff')), 1:length(ass.clust));
            
            null_err = zeros(length(ass.clust),50,shuffles);
            parfor ii = 1:shuffles
                sample = arrayfun(@(x) randperm(length(analysis.psth), x), cellfun(@length, ass.clust), 'uniformoutput',false);
                [~,~,temp] = bayes_infer(analysis, .05, sample);
                null_err(:, :, ii) = temp(2:end,:);
            end
            session(count).rest2.null_err = null_err;
            
            [~,~,session(count).rest2.err,session(count).rest2.err_sem]=bayes_infer(analysis,.05,r2_clust);
            [~,~,session(count).rest2.err_all,session(count).rest2.err_sem_all]=bayes_infer(analysis,.05,{cell2mat(r2_clust)});
            [~,~,session(count).rest2.err_no_clust,session(count).rest2.err_sem_no_clust]=bayes_infer(analysis,.05,{setxor(cell2mat(r2_clust), 1:length(analysis.psth))});
            width = analysis.width(cell2mat(ass.clust));
            idx = ~cellfun(@isempty, width);
            width = cell2mat(width(idx)');
            session(count).rest2.width = width;
            width = analysis.width;
            idx = ~cellfun(@isempty, width);
            width = cell2mat(width(idx)');
            session(count).rest2.all_width = width;
            session(count).rest2.norm_width = accumarray(session(count).rest2.width, 1, [50 50]) ./ accumarray(width, 1, [50 50]);
            session(count).rest2.stack_clust = analysis.stack(:,cell2mat(ass.clust));
            session(count).rest2.stack_no_clust = analysis.stack(:,setxor(cell2mat(ass.clust), 1:length(analysis.psth)));
            session(count).rest2.stack_all = analysis.stack;
            session(count).rest2.frac_pc_clust = length(intersect(analysis.pc_list, cell2mat(r2_clust))) / length(cell2mat(r2_clust));
            session(count).rest2.frac_pc = length(analysis.pc_list) / length(analysis.psth);
            
            session(count).frac_overlap = length(intersect(cell2mat(r1_clust), cell2mat(r2_clust))) / size(ass.deconv,2);
            session(count).null_frac = length(cell2mat(r1_clust)) * length(cell2mat(r2_clust)) / (size(ass.deconv,2)^2); %mean of hypergeometric distribution
            session(count).hypergeo_p = hygepdf(length(intersect(cell2mat(r1_clust), cell2mat(r2_clust))), size(ass.deconv,2), length(cell2mat(r1_clust)), length(cell2mat(r2_clust)));
            
            session(count).animal=list{f};
            session(count).date=root(i).name;
            count = count+1;
        end
        
    end
    
end
% session([1 10])=[]; %bad clusters
% session([3 10])=[]; %low pc count
% session([10])=[]; %low pc count


%% cluster PSTH
x = linspace(0, 150, size(analysis.stack,1));

figure;
area(x, analysis.stack(:,post_ass.clust{1}));
colormap jet
axis square

figure;
area(x, mean(analysis.stack(:,post_ass.clust{1}),2));
colormap jet
axis square


%% Distance from cue decoding correlation
bins = size(session(1).rest1.err,2);
bins_idx = 1:bins;
belt_indices = find(belt_idx);
distance_idx = knnsearch(belt_indices', bins_idx');

distance_idx = abs(bins_idx - belt_indices(distance_idx));


%% location vs scale fraction map
rest1_frac = zeros(50);
for i = 1:length(session)
    rest1_frac = rest1_frac + accumarray(session(i).rest1.width, 1, [50 50]);
end
rest2_frac = zeros(50);
for i = 1:length(session)
    rest2_frac = rest2_frac + accumarray(session(i).rest2.width, 1, [50 50]);
end
all_frac = zeros(50);
for i = 1:length(session)
    all_frac = all_frac + accumarray(session(i).rest1.all_width, 1, [50 50]);
end


%% decode error vs position rest1/2 and non-coactive
temp = [];
for i = 1:length(session)
    temp = [temp; session(i).rest1.err(2:end,:)];
end
figure
errorbar(mean(temp),sem(temp))
temp = [];
for i = 1:length(session)
    temp = [temp; session(i).rest2.err(2:end,:)];
end
hold on
errorbar(mean(temp),sem(temp))
temp = [];
for i = 1:length(session)
    temp = [temp; session(i).rest2.err_no_clust(2:end,:)];
end
hold on
errorbar(mean(temp),sem(temp))


%% Decoding error heat map
r1_err_map = [];
r1_sem_map = [];
for i = 1:length(session)
    r1_err_map = [r1_err_map; session(i).rest1.err(2:end,:)];
    r1_sem_map = [r1_sem_map; session(i).rest1.err_sem(2:end,:)];
end
[r1_err_min,r1_err_min_idx] = min(r1_err_map,[],2);
[~,r1_err_idx] = sort(r1_err_min_idx);
figure
% subplot(1,2,1);
imagesc(r1_err_map(r1_err_idx,:));
colormap jet
caxis([0 80]);
p = get(gca, 'position');
colorbar
set(gca, 'position', p);
% hold on;
% plot(r1_err_min_idx(r1_err_idx),1:length(r1_err_idx),'r');
% subplot(1,2,2);
% imagesc(r1_sem_map(r1_err_idx,:));
% colormap jet
% caxis([0 10]);
% colorbar

r2_err_map = [];
r2_sem_map = [];
for i = 1:length(session)
    r2_err_map = [r2_err_map; session(i).rest2.err(2:end,:)];
    r2_sem_map = [r2_sem_map; session(i).rest2.err_sem(2:end,:)];
end
[r2_err_min,r2_err_min_idx] = min(r2_err_map,[],2);
[~,r2_err_idx] = sort(r2_err_min_idx);
figure
% subplot(1,2,1);
imagesc(r2_err_map(r2_err_idx,:));
colormap jet
caxis([0 80]);
p = get(gca, 'position');
colorbar
set(gca, 'position', p);
% hold on;
% plot(r2_err_min_idx(r2_err_idx),1:length(r2_err_idx),'r');
% subplot(1,2,2);
% imagesc(r2_sem_map(r2_err_idx,:));
% colormap jet
% caxis([0 10]);
% colorbar

% non_err_map = [];
% non_sem_map = [];
% for i = 1:length(session)
%     non_err_map = [non_err_map; session(i).rest2.err(1,:)];
%     non_sem_map = [non_sem_map; session(i).rest2.err_sem(1,:)];
% end
% [~,idx] = min(non_err_map,[],2);
% [~,idx] = sort(idx);
% figure
% subplot(1,2,1);
% imagesc(non_err_map(idx,:));
% colormap jet
% caxis([0 80]);
% colorbar
% subplot(1,2,2);
% imagesc(non_sem_map(idx,:));
% colormap jet
% caxis([0 10]);
% colorbar


%% permutation test significant regions
r1_sig_regions=[];
r1_sig_map = [];
for i = 1:length(session)
    r1_sig_regions = [r1_sig_regions; session(i).rest1.err(2:end,:) < prctile(session(i).rest1.null_err, 5, 3)];
    r1_sig_map = [r1_sig_map; sum( session(i).rest1.err(2:end,:) > session(i).rest1.null_err ,3) ./ size(session(i).rest1.null_err,3)];
end

r2_sig_regions=[];
r2_sig_map = [];
for i = 1:length(session)
    r2_sig_regions = [r2_sig_regions; session(i).rest2.err(2:end,:) < prctile(session(i).rest2.null_err, 5, 3)];
    r2_sig_map = [r2_sig_map; sum( session(i).rest2.err(2:end,:) > session(i).rest2.null_err ,3) ./ size(session(i).rest2.null_err,3)];
end
figure
[~,idx] = min(r1_sig_map,[],2);
[~,idx] = sort(idx);
imagesc(r1_sig_map(idx,:))
colormap hot
colorbar
caxis([0 1])
% hold on
% [~,idx]=min(r1_sig_map(idx,:), [], 2);
% plot(idx, 1:size(r1_sig_map,1), 'r')
figure
[r,p]=corr(r1_sig_map);
r(p>.05)=nan;
imagesc(r);
caxis([0 1])
colorbar
colormap jet
axis square

figure
[~,idx] = min(r2_sig_map,[],2);
[~,idx] = sort(idx);
imagesc(r2_sig_map(idx,:))
colormap hot
colorbar
caxis([0 1])
% hold on
% [~,idx]=min(r2_sig_map(idx,:), [], 2);
% plot(idx, 1:size(r2_sig_map,1), 'r')
figure
[r,p]=corr(r2_sig_map);
r(p>.05)=nan;
imagesc(r);
caxis([0 1])
colorbar
colormap jet
axis square


%% Number significant histogram + moving average
figure
% bar(sum(r1_sig_regions)./sum(r1_sig_regions(:)));
% bar([sum(r1_sig_map <= .05 & r1_sig_map > .01); sum(r1_sig_map <= .01 & r1_sig_map > .001); sum(r1_sig_map <= .001)]'./sum(r2_sig_regions(:))', 'stacked');
bar([sum(r1_sig_map <= .05 & r1_sig_map > .01); sum(r1_sig_map <= .01 & r1_sig_map > .001); sum(r1_sig_map <= .001)]'./numel(r2_sig_regions)', 'stacked');
hold on
plot(movmedian(sum(r1_sig_regions)./numel(r1_sig_regions), 10/3), 'r', 'linewidth', 5)
figure
% bar(sum(r2_sig_regions)./sum(r2_sig_regions(:)));
bar([sum(r2_sig_map <= .05 & r2_sig_map > .01); sum(r2_sig_map <= .01 & r2_sig_map > .001); sum(r2_sig_map <= .001)]'./numel(r2_sig_regions)', 'stacked');
hold on
plot(movmedian(sum(r2_sig_regions)./numel(r2_sig_regions), 10/3), 'r', 'linewidth', 5)



%% Distance vs err correlation
idx = reshape(1:size(r1_err_map,2)^2, size(r1_err_map,2), size(r1_err_map,2));
idx = tril(idx, -1);
idx(~idx)=[];

lol = r1_sig_map;
lol(~lol) = .001;
lol = -log10(lol);
[r1_corr_err, r1_corr_p] = corr(lol);
r1_corr_err = r1_corr_err(idx);
r1_corr_p = r1_corr_p(idx);
lol = r2_sig_map;
lol(~lol) = .001;
lol = -log10(lol);
[r2_corr_err, r2_corr_p] = corr(lol);
r2_corr_err = r2_corr_err(idx);
r2_corr_p = r2_corr_p(idx);

distance_sum = distance_idx' + distance_idx;
distance_sum = distance_sum(idx);
distance_sqrd = distance_idx' * distance_idx;
distance_sqrd = distance_sqrd(idx);
distance_max = max(cat(3, repmat(distance_idx', 1, length(distance_idx)), repmat(distance_idx, length(distance_idx), 1)), [], 3);
distance_max = distance_max(idx);
distance_min = min(cat(3, repmat(distance_idx', 1, length(distance_idx)), repmat(distance_idx, length(distance_idx), 1)), [], 3);
distance_min = distance_min(idx);

pairs_distance = mod( repmat((0:size(r1_err_map,2)-1)', 1, size(r1_err_map,2)) - (0:size(r1_err_map,2)-1), size(r1_err_map,2));
pairs_distance = pairs_distance(idx);

[r,p]=corr(distance_sum(r1_corr_p < .05)',r1_corr_err(r1_corr_p < .05)')
[r,p]=corr(distance_sum(r2_corr_p < .05)',r2_corr_err(r2_corr_p < .05)')

[r,p]=corr(log(pairs_distance(~isnan(r1_corr_err) & (r1_corr_p < .05))'),r1_corr_err(~isnan(r1_corr_err) & (r1_corr_p < .05))')
[r,p]=corr(log(pairs_distance(~isnan(r2_corr_err) & (r2_corr_p < .05))'),r2_corr_err(~isnan(r2_corr_err) & (r2_corr_p < .05))')


%% pval vs cue distance correlation
lol = r1_sig_map;
lol(~lol) = .001;
lol = -log10(lol);
idx = repmat(distance_idx, size(lol,1), 1);
[r,p] = corr(lol(:),idx(:))


%% cross-correlation structure for decoding error
figure
[lol,lags]=xcorr_pairs(r1_sig_regions', 50);
% [lol,lags]=xcorr_pairs(-log10(r1_sig_map)', 50);
% lol=lol./max(lol);
[~,idx]=max(lol);
% idx=sum(lol);
% idx = sum(lol(1:floor(size(lol,1)/2), :)) ./ sum(lol(1:ceil(size(lol,1)/2)+1, :));
[~,idx]=sort(idx);
imagesc('xdata',lags.*3,'cdata',lol(:,idx)')
colormap jet
colorbar
xlim([lags(1)*3 lags(end)*3])
ylim([1 size(lol,2)])
hold on
[~,idx] = max(lol(:,idx));
plot(lags(idx).*3, 1:size(lol,2), 'r')

figure
[lol,lags]=xcorr_pairs(r2_sig_map', 50);
lol=lol./max(lol);
[~,idx]=max(lol);
[~,idx]=sort(idx);
imagesc('xdata',lags.*3,'cdata',lol(:,idx)')
colormap jet
colorbar
xlim([lags(1)*3 lags(end)*3])
ylim([1 size(lol,2)])
hold on
[~,idx] = max(lol(:,idx));
plot(lags(idx).*3, 1:size(lol,2), 'r')


%% stack
figure
% stack=arrayfun(@(x) session(x).rest2.stack_clust, 1:length(session), 'uniformoutput',false);
% stack=arrayfun(@(x) session(x).rest1.stack_clust, 1:length(session), 'uniformoutput',false);

% stack=arrayfun(@(x) session(x).rest2.stack_no_clust, 1:length(session), 'uniformoutput',false);
stack=arrayfun(@(x) session(x).rest1.stack_no_clust, 1:length(session), 'uniformoutput',false);
stack=cell2mat(stack);
[~,idx]=max(stack);
[~,idx]=sort(idx);
imagesc(stack(:,idx)');
colormap jet

figure
imagesc(corr(stack'))
colormap jet
colorbar
caxis([0 1])
















