function [ustrs,cstrs,sres,pres,nres,BOOT,avg_colors,sleg]=load_plot_psynet_experiments(fname,rgbs,yxs,NBOOT,BASIC)
%figure(1);clf
%fname='data/export_gb_color.csv';
%fname='data/export_ru_color.csv'
fprintf('Reading: %s...\n',fname);
ores=readtable(fname);
%%
tres=cell(330,5);
for I=1:size(ores,1)

    val=ores.answers(I);val=val{1};val=val(2:(end-1));val=strrep(val,"'","");val=strrep(val,' ','');
    if contains(val,'nan')
        
        assert(1==0)
    end
        
    vals=strsplit(val,',');
    oy=ores.y_coordinate(I);
    ox=ores.x_coordinate(I);
    orgb=[ores.r(I),ores.g(I),ores.b(I)];
    idx=(yxs(:,2)==ox)&(yxs(:,1)==oy);
    assert(sum(idx)==1);
    idx=find(idx);
    assert(sum(rgbs(idx,:)==orgb)==3);
    for ll=1:length(vals)
        tres{idx,ll}=vals{ll};
    end

end

for I=1:size(tres,1)
    for J=1:size(tres,2)
        if isempty(tres{I,J})
            tres{I,J}='<empty>';
        end
    end
end

nterms=zeros(size(tres,1),1);
for I=1:size(tres,1)
    icnt=0;
    for J=1:size(tres,2)
        if isempty(tres{I,J})
            continue
        end
        if strcmp(tres{I,J},'<empty>')
            continue
        end
         if strcmp(tres{I,J},'nan')
            continue
         end
        icnt=icnt+1;
    end
    nterms(I)=icnt;
end

fprintf('%s- Number of responses: min %3.2f max %3.2f mean %3.2f\n',fname,min(nterms),max(nterms),mean(nterms));
%%


is_print=true;


ftres=tres(:);
ftres=ftres(~strcmp(ftres,'<empty>'));
ftres=ftres(~strcmp(ftres,'nan'));

[ustrs,cstrs]=str_hist(ftres,is_print);
if ~isempty(BASIC)
    ustrs=BASIC;
end

sres=cell(size(tres,1),1);
pres=nan(size(tres,1),1);
nres=nan(size(tres,1),1);

for I=1:size(tres,1)
    vals=tres(I,:);

    vals=vals(~strcmp(vals,'<empty>'));
    if isempty(vals)
        continue
    end
    [my_ustrs,my_cstrs]=str_hist(vals,false);
    p=my_cstrs(1)/sum(my_cstrs);
    sel=my_ustrs{1};
    sres{I}=sel;
    pres(I)=p;
    nres(I)=find(strcmp(ustrs,sel));
end
%%
Bsres=cell(size(tres,1),NBOOT);
Bpres=nan(size(tres,1),NBOOT);
Bnres=nan(size(tres,1),NBOOT);

fprintf('Bootrapping...')
for B=1:NBOOT
    if mod(B,10)==1
        fprintf('.');
    end
for I=1:size(tres,1)
    vals=tres(I,:);
    
    vals=vals(~strcmp(vals,'<empty>'));
    if isempty(vals)
        continue
    end
    vals=vals(randi(length(vals),1,length(vals)));
    [my_ustrs,my_cstrs]=str_hist(vals,false);
    p=my_cstrs(1)/sum(my_cstrs);
    sel=my_ustrs{1};
    Bsres{I,B}=sel;
    Bpres(I,B)=p;
    Bnres(I,B)=find(strcmp(ustrs,sel));
end
end
BOOT=[];
BOOT.Bsres=Bsres;
BOOT.Bpres=Bpres;
BOOT.Bnres=Bnres;
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
title(strrep(fname,'_','-'))

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

    xlim([-2 41]);
    axis off
