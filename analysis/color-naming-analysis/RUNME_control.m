clear all;close all;clc % "To begin at the beginning" Under Milk Wood – Dylan Thomas
addpath('supporting_code/')

NBOOT=1000;

res=cell(1,1);
cnt_res=0;

EN_BASIC={'Red','Blue', 'Yellow', 'Green', 'Orange','Purple','Pink', 'Brown', 'Black', 'White', 'Gray', 'Beige', 'Turquoise', 'Gold', 'Silver','error'};
EN_BASIC_L=lower(EN_BASIC);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% READS ALL DATA:

figure(1);clf;
subplot(2,2,1);
is_plot=true;
[rgbs,yxs]=get_plot_wcs_colors(is_plot);

title('Colors')
axis off
for_ilia=[(1:size(rgbs,1))',yxs,rgbs];
t_for_ilia=array2table(for_ilia,'VariableNames',{'order','y_coordinate','x_coordinate','r','g','b'});
%write(t_for_ilia,'results/ilia_export_data_WCS.csv')
%axis on
IS_EXCLUDE_COLOR_BLIND=false;


figure(2);clf;

fname='data/control/colors-CIELAB-naming-0-gpt-4-0.7-c.csv';

subplot(2,2,1);
[ustrs_eg3,cstrs_e3g,sres_eg3,pres_eg3,nres_eg3,BOOT_eg3,savg_colors_eg3,sleg_eg3]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,EN_BASIC_L);
title('CIELAB');
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_eg3;
res{cnt_res,1}.BOOT=BOOT_eg3;
res{cnt_res,1}.name='CIELAB';
res{cnt_res,1}.sname='CIELAB';

fname='data/control/colors-CIELUV-naming-0-gpt-4-0.7-c.csv';

subplot(2,2,2);
[ustrs_rg3,cstrs_r3g,sres_rg3,pres_rg3,nres_rg3,BOOT_rg3,savg_colors_rg3,sleg_rg3]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,EN_BASIC_L);
title('CIELUV');
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_rg3;
res{cnt_res,1}.BOOT=BOOT_rg3;
res{cnt_res,1}.name='CIELUV';
res{cnt_res,1}.sname='CIELUV';


fname='data/control/colors-hex-naming-Mistral-7B.csv';
subplot(2,2,3);
[ustrs_eg35,cstrs_eg35,sres_eg35,pres_eg35,nres_eg35,BOOT_eg35,savg_colors_eg35,sleg_eg35]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,EN_BASIC);
title('Mistral-7B');
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_eg35;
res{cnt_res,1}.BOOT=BOOT_eg35;
res{cnt_res,1}.name='Mistral-7B';
res{cnt_res,1}.sname='Mistral-7B';
%axis on

subplot(2,2,4);

fname='data/export_gb_color.csv';
[ustrs_ep,cstrs_ep,sres_ep,pres_ep,nres_ep,BOOT_ep,avg_colors_ep,sleg_ep]=load_plot_psynet_experiments(fname,rgbs,yxs,NBOOT,EN_BASIC);
title('English Human Experiment')
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_ep;
res{cnt_res,1}.BOOT=BOOT_ep;
res{cnt_res,1}.name='English Human Experiment';
res{cnt_res,1}.sname='Participants, English';


ssnames=cell(size(res));

for I=1:length(res)
    ssnames{I}=res{I}.sname;
end
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOT FULL RAND INDEX MATRIX:

%linkaxes(ax,'x')
figure(5);clf;

ord=1:length(res);

rand_index_matrix=nan(length(ord),length(ord));
snames=cell(size(ord));

sub_place=yxs(:,1)>=-99999; % everything


for I=1:length(ord)
    snames{ord(I)}=res{I}.sname;
    for J=1:length(ord)
        if I==J
            %   continue
        end
        score=rand_index(res{I}.nres(sub_place),res{J}.nres(sub_place),'adjusted');
        rand_index_matrix(ord(I),ord(J))=score;
    end
end
my_lim=1:length(ord);


imagesc(rand_index_matrix(my_lim,my_lim));hold on;
for I=1:size(rand_index_matrix(my_lim,my_lim),1)
    for J=1:size(rand_index_matrix(my_lim,my_lim),2)
        score=rand_index_matrix(my_lim(I),my_lim(J));
        if my_lim(I)==my_lim(J)
            continue
        end
        msg=sprintf('%2.2g',score);
        if strcmp(msg(1),'0')
            msg=msg(2:end);
        end

        if score>0.6
            text(I,J,msg,'Color','k','FontSize',12);
        else
            text(I,J,msg,'Color','w','FontSize',12);
        end

    end
end
set(gca,'FontSize',14)
set(gca,"XTick",1:length(snames(my_lim)));
set(gca,"XTickLabel",snames(my_lim));
set(gca,"YTick",1:length(snames(my_lim)));
set(gca,"YTickLabel",snames(my_lim));
colorbar;
%colormap turbo
colormap bone
title('Adjusted Rand Index')
%%


PERC=95;

figure(102);clf;
subplot(1,2,1)
bar_comp=cell(1,1);
bar_comp{1}={'CIELAB','Participants, English';'CIELUV','Participants, English';'Mistral-7B','Participants, English'};

bar_comp{1};NK=size(bar_comp{1},1);

mbar=nan(size(bar_comp{1},1),NK);
mleg=cell(size(bar_comp{1},1),NK);

K=1;
fprintf("\nresults:\n");
mres=[];
for I=1:size(bar_comp{K},1)
    my_bar_comp=bar_comp{K};
    idx1=find(strcmp(ssnames,my_bar_comp{I,1}),1);
    idx2=find(strcmp(ssnames,my_bar_comp{I,2}),1);
    score=rand_index(res{idx1}.nres,res{idx2}.nres,'adjusted');
    BOOT1=res{idx1}.BOOT;
    BOOT2=res{idx2}.BOOT;

    vs=nan(size(BOOT1.Bnres,2),1);
    for B=1:size(BOOT1.Bnres,2)
        vs(B)=rand_index(BOOT1.Bnres(:,B),BOOT2.Bnres(:,B),'adjusted');
    end
    mstd=std(vs);vss=sort(vs);
    CIdown=prctile(vss,(100-PERC)/2);
    CIup=prctile(vss,100-(100-PERC)/2);
    CImed=prctile(vss,50);
    mres=[mres;I,score,mstd,CIdown,CIup,CImed];

    fprintf('%s and %s %3.2f 95%% CI [%3.2f,%3.2f]\n',my_bar_comp{I,1},my_bar_comp{I,2},score,CIdown,CIup)
end

for I=1:3
    score=mres(I,2);
    bar(I,score);hold on;
end


