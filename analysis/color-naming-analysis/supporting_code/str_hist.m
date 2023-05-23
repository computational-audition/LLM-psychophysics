function [ustrs,cstrs]=str_hist(strs,is_print)
ustrs=unique(strs);
cstrs=zeros(size(ustrs));
for ll=1:length(strs)
    idx=strcmp(ustrs,strs{ll});
    cstrs(idx)=cstrs(idx)+1;
end
[~,idxs]=sort(cstrs,'descend');
ustrs=ustrs(idxs);
cstrs=cstrs(idxs);

if is_print
    for ll=1:length(cstrs)
        fprintf('\t %d \t %s\n',cstrs(ll), ustrs{ll});
    end
end