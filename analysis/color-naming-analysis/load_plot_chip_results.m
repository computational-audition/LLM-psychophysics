function [ustrs,cstrs,sres,pres,nres,BOOT,avg_colors,sleg]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,BASIC)
%fname='data/english-colors-WCS-GPT4.csv';
fprintf('Reading: %s...\n',fname);
tres=readtable(fname);


tres=table2cell(tres(2:end,:));
for I=1:size(tres,1)
    val=tres(I,end);
    assert((val{1}==I)) % last column has col;umnnumber
end
tres=tres(:,1:(end-1));
is_print=true;
[ustrs,cstrs]=str_hist(tres(:),is_print);
if ~isempty(BASIC)
    ustrs=BASIC;
end

sres=cell(size(tres,1),1);
nres=nan(size(tres,1),1);
pres=nan(size(tres,1),1);
for I=1:size(tres,1)
    [my_ustrs,my_cstrs]=str_hist(tres(I,:),false);
    p=my_cstrs(1)/sum(my_cstrs);
    sel=my_ustrs{1};
    sres{I}=sel;
    pres(I)=p;

    nres(I)=find(strcmp(ustrs,sel));

end
%%

Bsres=cell(size(tres,1),NBOOT);
Bnres=nan(size(tres,1),NBOOT);
Bpres=nan(size(tres,1),NBOOT);
fprintf('Bootrapping...')
for B=1:NBOOT
    if mod(B,10)==1
        fprintf('.');
    end
    for I=1:size(tres,1)
        vals=tres(I,:);
        vals=vals(randi(length(vals),1,length(vals)));
        [my_ustrs,my_cstrs]=str_hist(vals,false);
        p=my_cstrs(1)/sum(my_cstrs);
        sel=my_ustrs{1};
        Bsres{I,B}=sel;
        Bpres(I,B)=p;
        val=find(strcmp(ustrs,sel));
        if isempty(val)
           val=0;
        end
        Bnres(I,B)=val;
    end
end
BOOT=[];
BOOT.Bsres=Bsres;
BOOT.Bnres=Bnres;
BOOT.Bpres=Bpres;
fprintf('\n');
%%
avg_colors=nan(size(ustrs,1),3);


for uu=1:length(ustrs)
    locs=strcmp(sres,ustrs{uu});
    mclr=mean(rgbs(locs,:),1);
    avg_colors(uu,:)=mclr;
end

%figure(2);clf
sleg=cell(1,1);cnt=0;
for uu=1:length(ustrs)
    mclr=avg_colors(uu,:);
    if isnan(sum(mclr))
        %continue
        mclr=[255,255,255];
    end

    cnt=cnt+1;sleg{cnt}=sprintf('%s (%d)',ustrs{uu},sum(strcmp(sres,ustrs{uu})));
    plot(5,5,'sk','MarkerFaceColor',mclr/255,'MarkerSize',20);hold on;
end
legend(sleg,'AutoUpdate','off','Location','east');
set(gca,'FontSize',14)
title(fname)

for uu=1:length(ustrs)
    mclr=avg_colors(uu,:);

    if isnan(sum(mclr))
         %continue
        mclr=[0,0,0];
    end
    locs=strcmp(sres,ustrs{uu});
    flocs=find(locs==1);
    for ll=1:length(flocs)
        I=flocs(ll);
        x=yxs(I,2);
        y=yxs(I,1);
        p=pres(I);
        %pclr=p*(mclr/255)+(1-p)*[0,0,0];
        pclr=mclr/255;

        rectangle("FaceColor",pclr,'Position',[x-0.5,y-0.5,1,1]);hold on;
        if p<=0.9
            if p<0.5
                text(x,y,'-');
            else
                text(x,y,'*');
            end
        end
    end
end
VS={'A','B','C','D','E','F','G','H','I','J'};

set(gca,'YTick',1:length(VS))
set(gca,'YTickLabels',VS(length(VS):-1:1))
set(gca,'XTick',1:40)

xlim([-2 41]);axis off
