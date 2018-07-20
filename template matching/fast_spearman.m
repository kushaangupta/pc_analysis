function rho=fast_spearman(x,y,gpuFlag)
% A little bit faster than corr(x,y,'type','spearman')
% Expect significant performance increase with GPU

if nargin<3
    gpuFlag=false;
end

x_len=size(x,2);
A=[x y];

if gpuFlag
    A=(A-min(A))./range(A).*(2^16-2);
    A=uint16(A);
    [~,~,ranks]=oddeven(A);
    ranks=double(gather(ranks));
else
    [sorted,idx]=sort(A,'descend');

    ranks=zeros(size(A));
    parfor i=1:size(A,2)
        ranks(:,i)=getRanks(sorted(:,i));
    end
    ranks(idx+(0:size(A,2)-1).*size(A,1))=ranks;
end

x=ranks(:,1:x_len);
y=ranks(:,x_len+1:end);

rho=corr(x,y);


function ranks=getRanks(vect)
[~,idx]=unique(vect,'stable');

ranks=zeros(length(vect),1);
for i=1:length(idx)-1
    ranks(idx(i):idx(i+1)-1)=(idx(i+1)-idx(i)-1)/2+idx(i);
end
ranks(idx(end):end)=(length(vect)-idx(end))/2+idx(end);