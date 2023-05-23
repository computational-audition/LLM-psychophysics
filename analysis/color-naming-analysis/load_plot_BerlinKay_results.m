clear all;close all;clc
wdir='~/rMPIEA/RESEARCH_STUDENTS_COLLAB/gpt3-psycho';
cd(wdir);

% words=readtable('data/WCS/dict.txt');
% spkrs=readtable('data/WCS/spkr-lsas.txt');
% naming=readtable('data/WCS/term.txt');



% wcs_words=readtable('data/WCS/dict.txt');
% wcs_naming=readtable('data/WCS/term.txt');

[rgbs,yxs,xnum]=get_plot_wcs_colors(false);

%%
bk_words=readtable('data/WCS/BK-dict.txt');
bk_naming=readtable('data/WCS/BK-term.txt');


SLANG='B&K English';LANG=6; % HEBREW 7 LANG=6
%SLANG='B&K Hebrew';LANG=7; % HEBREW 7 LANG=6

pos=(bk_naming.Var1==LANG);

my_nam=bk_naming(pos,:);

NC=330;

pos=bk_words.x_lnum==LANG;bw=bk_words(pos,:);

ts=unique(my_nam.Var4);
fts=cell(size(ts)); % full names
%ftn=nan(size(ts)); % index of colo
for ll=1:length(ts)
    idx=find(strcmp(bw.abbr,ts{ll}));
    assert(length(idx)==1);
    fullname=bw.term(idx);
    number=bw.tnum(idx);
    fts{ll}=fullname{1};
    %ftn(ll)=number;
end

%res=nan(NC,1);
sres=cell(NC,1);
fres=cell(NC,1);

for I=1:NC
    fres{I}='not defined';
    sres{I}='..';
end
for I=1:size(my_nam,1)
    participant=my_nam.Var2(I);
    assert(participant==1)
    ncolor=my_nam.Var3(I);

    loc=find(xnum==ncolor);
    abr=my_nam.Var4(I);
    abr=abr{1};
    idx_ts=find(strcmp(ts,abr));
    %res(ncolor)=idx_ts;

    sres{loc}=abr;
    fres{loc}=fts{idx_ts};
end


ustrs=unique(fres);
mres=fres;


avg_colors=nan(size(ustrs,1),3);


for uu=1:length(ustrs)
    locs=strcmp(mres,ustrs{uu});
    mclr=mean(rgbs(locs,:),1);
    avg_colors(uu,:)=mclr;
    %avg_colors(uu,:)=rand(1,3)*255;
end

avg_colors

figure(1);clf;

sleg=cell(1,1);cnt=0;
for uu=1:length(ustrs)

    mclr=avg_colors(uu,:);
    if isnan(sum(mclr))
        continue
    end
    %
    cnt=cnt+1;sleg{cnt}=sprintf('%s (%d)',ustrs{uu},sum(strcmp(mres,ustrs{uu})));
    plot(5+uu/10,5+uu/10,'sk','MarkerFaceColor',mclr/255);hold on;
end

legend(sleg,'AutoUpdate','off','Location','eastoutside');
set(gca,'FontSize',14)

%for uu=12

for uu=1:length(ustrs)
    mclr=avg_colors(uu,:);

    if isnan(sum(mclr))
        continue
    end
    locs=strcmp(mres,ustrs{uu});
    flocs=find(locs==1);
    for ll=1:length(flocs)
        I=flocs(ll);
        x=yxs(I,2);
        y=yxs(I,1);
        %pclr=p*(mclr/255)+(1-p)*[0,0,0];
        pclr=mclr/255;

        rectangle("FaceColor",pclr,'Position',[x-0.5,y-0.5,1,1]);hold on;

    end
end
VS={'A','B','C','D','E','F','G','H','I','J'};

set(gca,'YTick',1:length(VS))
set(gca,'YTickLabels',VS(length(VS):-1:1))
set(gca,'XTick',1:40)

xlim([-2 41]);
title(SLANG)
