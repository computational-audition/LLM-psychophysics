function [ustrs,cstrs,sres,pres,nres,BOOT,avg_colors,sleg]=get_lindsey_and_brown(fname,rgbs,yxs,NBOOT)
% clear sall;close all;clc
%
% addpath('~/ResearchMIT/toolboxes/nUTIL/');
%
% wdir='~/rMPIEA/RESEARCH_STUDENTS_COLLAB/gpt3-psycho';
% cd(wdir);
% is_plot=false;
% [rgbs,yxs]=get_plot_wcs_colors(is_plot); % get wcolor values.


% if is_constained
%     raw_LB2014=readtable('data/Lindsey and Brownm 2014 - constrained - bcNamesEnglish51SubjForDistribution.xlsx','ReadVariableNames',false);
%
% else
%
%     raw_LB2014=readtable('data/Lindsey and Brownm 2014 - NamesEnglish51SubjForDistribution.xlsx','ReadVariableNames',false);
% end
fprintf('Reading: %s...\n',fname);
raw_LB2014=readtable(fname,'ReadVariableNames',false);


raw_LB2014=table2cell(raw_LB2014);
ucolor=unique(raw_LB2014(:));

VS={'A','B','C','D','E','F','G','H','I','J'};

V_values=cell(330,1);
y_values=nan(330,1);
x_values=nan(330,1);

for I=1:8
    for ll=1:40
        V_values{ (I-1)*40 + ll}= VS{10-I};
        y_values( (I-1)*40 + ll)= length(VS)-find(strcmp(VS{10-I},VS))+1;
        x_values( (I-1)*40 + ll)= ll;
    end
end
V_values(321:330)=VS(end:(-1):1);

y_values(321:330)=1:10;
x_values(321:330)=0;

rgb_in_lb_order=nan(330,3);
for I=1:330
    pos=(y_values(I)==yxs(:,1)) & (x_values(I)==yxs(:,2));
    assert(sum(pos)==1);
    idx=find(pos);
    rgb_in_lb_order(I,:)=rgbs(idx,:);
end

%%

% all:
[all_ustrs,all_cstrs]=str_hist(raw_LB2014(:),false);


sres=cell(size(raw_LB2014,1),1);
pres=nan(size(raw_LB2014,1),1);
nres=nan(size(raw_LB2014,1),1);

for I=1:size(raw_LB2014,1)
    [my_ustrs,my_cstrs]=str_hist(raw_LB2014(I,:),false);
    p=my_cstrs(1)/sum(my_cstrs);
    sel=my_ustrs{1};

    pos=(y_values(I)==yxs(:,1)) & (x_values(I)==yxs(:,2));
    assert(sum(pos)==1);
    idx=find(pos);

    sres{idx}=sel;
    pres(idx)=p;
    nres(idx)=find(strcmp(sel,all_ustrs));
end
%%
Bsres=cell(size(raw_LB2014,1),NBOOT);
Bpres=nan(size(raw_LB2014,1),NBOOT);
Bnres=nan(size(raw_LB2014,1),NBOOT);

fprintf('Bootrapping...')


for I=1:size(raw_LB2014,1)
    if mod(I,10)==1
        fprintf('.');
    end
    pos=(y_values(I)==yxs(:,1)) & (x_values(I)==yxs(:,2));
    assert(sum(pos)==1);
    idx=find(pos);

    for B=1:NBOOT
        vals=raw_LB2014(I,:);
        vals=vals(randi(length(vals),1,length(vals)));
        [my_ustrs,my_cstrs]=str_hist(vals,false);
        p=my_cstrs(1)/sum(my_cstrs);
        sel=my_ustrs{1};

        Bsres{idx,B}=sel;
        Bpres(idx,B)=p;
        Bnres(idx,B)=find(strcmp(sel,all_ustrs));
    end
end
fprintf('\n');
BOOT=[];
BOOT.Bsres=Bsres;
BOOT.Bpres=Bpres;
BOOT.Bnres=Bnres;
%%
%note only "best" selected colors over 51 majority of participants are
%included in this list!

[ustrs,cstrs]=str_hist(sres,true);

avg_colors=nan(size(ustrs,1),3);


for uu=1:length(ustrs)
    locs=strcmp(sres,ustrs{uu});
    %mclr=mean(rgb_in_lb_order(locs,:),1);
    mclr=mean(rgbs(locs,:),1);
    avg_colors(uu,:)=mclr;
end

sleg=cell(1,1);cnt=0;
for uu=1:length(ustrs)
    mclr=avg_colors(uu,:);
    if isnan(sum(mclr))
        continue
    end

    cnt=cnt+1;sleg{cnt}=sprintf('%s (%d)',ustrs{uu},sum(strcmp(sres,ustrs{uu})));
    plot(5,5,'sk','MarkerFaceColor',mclr/255,'MarkerSize',20);hold on;
end
legend(sleg,'AutoUpdate','off','Location','east');
set(gca,'FontSize',14)

for uu=1:length(ustrs)
    mclr=avg_colors(uu,:);

    if isnan(sum(mclr))
        continue
    end
    locs=strcmp(sres,ustrs{uu});
    flocs=find(locs==1);
    for ll=1:length(flocs)
        I=flocs(ll);
        %         y=y_values(I); %IMPORTANT FOR CORRELATION NOTE THIS IS A DIFFERNET ORDER!!
        %         x=x_values(I);
        y=yxs(I,1);
        x=yxs(I,2);


        p=pres(I);
        %pclr=p*(mclr/255)+(1-p)*[0,0,0];
        pclr=mclr/255;

        rectangle("FaceColor",pclr,'Position',[x-0.5,y-0.5,1,1]);hold on;
        if p<0.90
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

title(strrep(fname,'_','-'));
% if ~is_constained
%     title('Lindsey and Brown 2014 (free naming): English')
% else
%     title('Lindsey and Brown 2014 (constrained naming): English')
% end
axis off
