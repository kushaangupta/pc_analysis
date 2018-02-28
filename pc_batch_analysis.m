function analysis=pc_batch_analysis(varargin)
% analysis = pc_batch_analysis(behavior, deconv, params);
%
% Parameters
%   'mask', maskNeurons, mimg
%       required for merging two planes
% 
%   'test',
%       'si' (default) SI shuffle test
%       'gmm' new method based on GMM! more rigorous than SI
%       'mixed' two tests combined
%
%   'shuffles', 1000 (default)
%       number of shuffles for tests
%
%   'bins', 50 (default)
%       number of spatial bins
%
%   'sd', 4 (default)
%       smoothing kernel s.d. in cm
%   'par', true (default)
%       use parallel processing to speed up

behavior=varargin{1};
deconv=varargin{2};

[maskFlag,testFlag,parFlag,shuffles,bins,sd]=parse_input(varargin);

% v2struct(behavior);
unit_pos=behavior.unit_pos;
unit_vel=behavior.unit_vel;
frame_ts=behavior.frame_ts;
trials=behavior.trials;

vr_length=round(range(unit_pos));
sr=1/mean(diff(frame_ts));

thres=noRun(unit_vel);
% thres=0;

[psth,raw_psth,raw_stack,Pi,vel_stack]=getStack(bins,sd,vr_length,deconv,thres,unit_pos,unit_vel,frame_ts,trials);

stack=raw_stack;
stack=(stack-repmat(min(stack),bins,1));
stack=stack./repmat(max(stack),bins,1);

[~,idx]=max(stack);
[~,ordered]=sort(idx);
stack=stack(:,ordered)';

%SI test
% lamb=raw_stack;
% m_lamb=mean(lamb);
% Pi=Pi./sum(Pi,2);
% Pi=Pi';
% 
% SI_series=Pi.*lamb./m_lamb.*log2(lamb./m_lamb);
% SI=sum(SI_series);

%SI test
SI=get_si(raw_psth);
if testFlag==1 || testFlag==3
    SI=[SI;zeros(shuffles,length(SI))];
    if parFlag
        parfor i=1:shuffles
%             perm=ceil(rand(1)*size(deconv,1));
%             shuffled_den=[deconv(perm:end,:);deconv(1:perm-1,:)];
            
%             perm=randi(size(deconv,1),1,1).*ones(1,size(deconv,2));
%             shuffled_den=mat_circshift(deconv,perm);

%             [~,~,lamb1,Pi1]=getStack(bins,sd,vr_length,shuffled_den,thres,unit_pos,unit_vel,frame_ts,trials);
%             m_lamb1=mean(lamb1);
%             Pi1=Pi1./sum(Pi1,2);
%             Pi1=Pi1';

%             temp=Pi1.*lamb1./m_lamb1.*log2(lamb1./m_lamb1);
%             SI(i+1,:)=sum(temp);

            perm=randperm(numel(raw_psth(:,:,1)));
            perm=reshape(perm,size(raw_psth,1),size(raw_psth,2));
            perm=repmat(perm,1,1,size(raw_psth,3));
            perm=perm+reshape(0:numel(raw_psth(:,:,1)):numel(raw_psth)-1,1,1,[]);
            temp=raw_psth(perm);
            SI(i+1,:)=get_si(temp);
        end
    else
        for i=1:shuffles
%             perm=ceil(rand(1)*size(deconv,1));
%             shuffled_den=[deconv(perm:end,:);deconv(1:perm-1,:)];
%             
%             perm=randi(size(deconv,1),1,1).*ones(1,size(deconv,2));
%             shuffled_den=mat_circshift(deconv,perm);
% 
%             [~,~,lamb1,Pi1]=getStack(bins,sd,vr_length,shuffled_den,thres,unit_pos,unit_vel,frame_ts,trials);
%             m_lamb1=mean(lamb1);
%             Pi1=Pi1./sum(Pi1,2);
%             Pi1=Pi1';
% 
%             temp=Pi1.*lamb1./m_lamb1.*log2(lamb1./m_lamb1);
%             SI(i+1,:)=sum(temp);
            perm=randperm(numel(raw_psth(:,:,1)));
            perm=reshape(perm,size(raw_psth,1),size(raw_psth,2));
            perm=repmat(perm,1,1,size(raw_psth,3));
            perm=perm+reshape(0:numel(raw_psth(:,:,1)):numel(raw_psth)-1,1,1,[]);
            temp=raw_psth(perm);
            SI(i+1,:)=get_si(temp);
        end
    end

    pval=1-sum(SI(1,:)>SI(2:end,:))./shuffles;
    pc_list=find(pval<0.001);
end
% SI=sum(SI_series);
SI=SI(1,pc_list);
%

%sparsity
% sparsity=sum(Pi.*lamb).^2./sum(Pi.*lamb.^2);
% sparsity=sparsity(1,pc_list);
sparsity=[];


%PC width
baseline_thres=range(raw_stack).*.2+min(raw_stack);
width_series=raw_stack>baseline_thres;
width_series=width_series(:,pc_list);

for i=1:size(width_series,2)
    temp=width_series(:,i)';
    start=strfind(temp,[0 1]);
    ending=strfind(temp,[1 0]);
    if temp(1)==1
        start=[1 start];
    end
    if temp(end)==1
        ending=[ending length(temp)];
    end
    temp=ending-start;
    width(i)=max(temp);
end
width=width.*vr_length./bins;
%


if maskFlag
    maskNeurons=varargin{maskFlag+1};
    mimg=varargin{maskFlag+2};
    analysis=v2struct(vr_length,sr,psth,raw_psth,raw_stack,Pi,vel_stack,stack,SI,pval,pc_list,sparsity,width,deconv,behavior,maskNeurons,mimg);
else
    analysis=v2struct(vr_length,sr,psth,raw_psth,raw_stack,Pi,vel_stack,stack,SI,pval,pc_list,sparsity,width,deconv,behavior);
end


function [maskFlag,testFlag,parFlag,shuffles,bins,sd]=parse_input(inputs)
maskFlag=0;
testFlag=1;
parFlag=true;
shuffles=1000;
sd=4;
bins=50;

idx=3;
while(idx<length(inputs))
    switch lower(inputs{idx})
        case 'mask'
            maskFlag=idx;
            idx=idx+2;
        case 'test'
            idx=idx+1;
            switch inputs{idx}
                case 'si'
                    testFlag=1;
                case 'gmm'
                    testFlag=2;
                case 'mixed'
                    testFlag=3;
                otherwise
                    error('not a valid test');
            end
        case 'shuffles'
            idx=idx+1;
            shuffles=inputs{idx};
        case 'bins'
            idx=idx+1;
            bins=inputs{idx};
        case 'sd'
            idx=idx+1;
            sd=inputs{idx};
        case 'par'
            idx=idx+1;
            parFlag=inputs{idx};
        otherwise
    end
    idx=idx+1;
end



