function [eScore,M,traceback]=needleWunsch(seq1,seq2)
% a modified Needleman-Wunsch algorithm for global alignment of replay
% sequences
%
% by HaoRan Chang

M=zeros(length(seq1)+1,length(seq2)+1);
traceback=M;
M(:,1)=0:-1:-length(seq1);
M(1,:)=0:-1:-length(seq2);
traceback(:,1)=2;
traceback(1,:)=1;

simM=getSimM(seq1,seq2);

for i=2:size(M,1)
    for j=2:size(M,2)
        M(i,j)=max([M(i-1,j-1)+simM(i-1,j-1) M(i-1,j)-1 M(i,j-1)-1]);
        arrow=M(i,j)==[M(i-1,j-1)+simM(i-1,j-1) M(i-1,j)-1 M(i,j-1)-1];
        traceback(i,j)=base2dec(replace(num2str(arrow),' ',''),2);
    end
end

eScore=scoreIt(M,traceback);

function simM=getSimM(seq1,seq2)
% compute similarity matrix
simM=seq1'*seq2;
simM=sqrt(simM);
simM=double(simM==floor(simM));
simM(~simM)=-1;

function score=scoreIt(M,traceback)
% scoring function
scoring=true;
i=size(M,1);
j=size(M,2);
score=M(i,j);
while(scoring)
    switch traceback(i,j)
        case 1
            j=j-1;
        case 2
            i=i-1;
        case 4
            i=i-1;
            j=j-1;
            
        case 5
            score=
    end
    score=score+M(i,j);
    if i==1 && j==1
        scoring=false;
    end
end