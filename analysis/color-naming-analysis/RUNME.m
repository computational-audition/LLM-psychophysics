clear all;close all;clc
%addpath('~/ResearchMIT/toolboxes/nUTIL/');
addpath('supporting_code/')

NBOOT=1000;

res=cell(1,1);
cnt_res=0;

RU_BASIC={'Красный', 'Оранжевый', 'Желтый', 'Зеленый', 'Голубой', 'Синий', 'Фиолетовый', 'Белый', 'Черный', 'Серый', 'Коричневый', 'Розовый', 'Бирюзовый', 'Бежевый', 'Лиловый'};
EN_BASIC={'Red','Blue', 'Yellow', 'Green', 'Orange','Purple','Pink', 'Brown', 'Black', 'White', 'Gray', 'Beige', 'Turquoise', 'Gold', 'Silver'};

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


% subplot(2,2,2);
% fname='data/Lindsey and Brownm 2014 - NamesEnglish51SubjForDistribution.xlsx';
% [ustrs_en,cstrs_en,sres_en,pres_en,nres_en,BOOT_en,avg_colors_en,sleg_en]=get_lindsey_and_brown(fname,rgbs,yxs,NBOOT);
% title('Lindsey and Brown 2014 (free naming): English')
% 
% cnt_res=cnt_res+1;
% res{cnt_res,1}.nres=nres_en;
% res{cnt_res,1}.BOOT=BOOT_en;
% res{cnt_res,1}.name='Lindsey and Brown 2014 (free naming): English';
% res{cnt_res,1}.sname='L&B 2014, Naming, English';
% 
% subplot(2,2,3);
% fname='data/Lindsey and Brownm 2014 - constrained - bcNamesEnglish51SubjForDistribution.xlsx';
% [ustrs_ec,cstrs_ec,sres_ec,pres_ec,nres_ec,BOOT_ec,avg_colors_ec,sleg_ec]=get_lindsey_and_brown(fname,rgbs,yxs,NBOOT);
% 
% title('Lindsey and Brown 2014 (constrained naming): English')
% cnt_res=cnt_res+1;
% res{cnt_res,1}.nres=nres_ec;
% res{cnt_res,1}.BOOT=BOOT_ec;
% res{cnt_res,1}.name='Lindsey and Brown 2014 (constrained naming): English';
% res{cnt_res,1}.sname='L&B 2014, Constrained, English';


figure(2);clf;

fname='data/english-colors-WCS-text-davinci-003.csv';
subplot(2,2,1);
[ustrs_eg3,cstrs_e3g,sres_eg3,pres_eg3,nres_eg3,BOOT_eg3,savg_colors_eg3,sleg_eg3]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,EN_BASIC);
title('English GPT3');
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_eg3;
res{cnt_res,1}.BOOT=BOOT_eg3;
res{cnt_res,1}.name='GPT3: English';
res{cnt_res,1}.sname='GPT3, English';

fname='data/Russian-colors-WCS-text-davinci-003.csv';
subplot(2,2,2);
[ustrs_rg3,cstrs_r3g,sres_rg3,pres_rg3,nres_rg3,BOOT_rg3,savg_colors_rg3,sleg_rg3]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,RU_BASIC);
title('Russian GPT3');
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_rg3;
res{cnt_res,1}.BOOT=BOOT_rg3;
res{cnt_res,1}.name='GPT3: Russian';
res{cnt_res,1}.sname='GPT3, Russian';


fname='data/english-colors-WCS-GPT35.csv';
subplot(2,2,3);
[ustrs_eg35,cstrs_eg35,sres_eg35,pres_eg35,nres_eg35,BOOT_eg35,savg_colors_eg35,sleg_eg35]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,EN_BASIC);
title('English GPT3.5');
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_eg35;
res{cnt_res,1}.BOOT=BOOT_eg35;
res{cnt_res,1}.name='GPT3.5: English';
res{cnt_res,1}.sname='GPT3.5, English';
%axis on


fname='data/Russian-colors-WCS-GPT35.csv';
subplot(2,2,4);
[ustrs_rg35,cstrs_rg35,sres_rg35,pres_rg35,nres_rg35,BOOT_rg35,savg_colors_rg35,sleg_rg35]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,RU_BASIC);
title('Russian GPT3.5');
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_rg35;
res{cnt_res,1}.BOOT=BOOT_rg35;
res{cnt_res,1}.name='GPT3.5: Russian';
res{cnt_res,1}.sname='GPT3.5, Russian';

%%
figure(3);clf;


fname='data/english-colors-WCS-GPT4.csv';
subplot(2,2,1);
[ustrs_eg,cstrs_eg,sres_eg,pres_eg,nres_eg,BOOT_eg,savg_colors_eg,sleg_eg]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,EN_BASIC);
title('English GPT4');
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_eg;
res{cnt_res,1}.BOOT=BOOT_eg;
res{cnt_res,1}.name='GPT4: English';
res{cnt_res,1}.sname='GPT4, English';
%axis on

fname='data/Russian-colors-WCS-GPT4.csv';

subplot(2,2,3);
[ustrs_rg,cstrs_rg,sres_rg,pres_rg,nres_rg,BOOT_rg,avg_colors_rg,sleg_rg]=load_plot_chip_results(fname,rgbs,yxs,NBOOT,RU_BASIC);
title('Russian GPT4')
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_rg;
res{cnt_res,1}.BOOT=BOOT_rg;
res{cnt_res,1}.name='Russian GPT4';
res{cnt_res,1}.sname='GPT4, Russian';

subplot(2,2,2);

    fname='data/export_gb_color.csv';
[ustrs_ep,cstrs_ep,sres_ep,pres_ep,nres_ep,BOOT_ep,avg_colors_ep,sleg_ep]=load_plot_psynet_experiments(fname,rgbs,yxs,NBOOT,EN_BASIC);
title('English Human Experiment')
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_ep;
res{cnt_res,1}.BOOT=BOOT_ep;
res{cnt_res,1}.name='English Human Experiment';
res{cnt_res,1}.sname='Participants, English';



subplot(2,2,4);


fname='data/export_ru_color.csv';
[ustrs_rp,cstrs_rp,sres_rp,pres_rp,nres_rp,BOOT_rp,avg_colors_rp,sleg_rp]=load_plot_psynet_experiments(fname,rgbs,yxs,NBOOT,RU_BASIC);
title('Russian Human Experiment')
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_rp;
res{cnt_res,1}.BOOT=BOOT_rp;
res{cnt_res,1}.name='Russian Human Experiment';
res{cnt_res,1}.sname='Participants, Russian';



figure(4);
subplot(2,2,2);

    fname='data/export_gb_color_no_color_blind.csv';
   
[ustrs_ep,cstrs_ep,sres_ep,pres_ep,nres_ep,BOOT_ep,avg_colors_ep,sleg_ep]=load_plot_psynet_experiments(fname,rgbs,yxs,NBOOT,EN_BASIC);
title('English Human Experiment')
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_ep;
res{cnt_res,1}.BOOT=BOOT_ep;
res{cnt_res,1}.name='English Human Experiment no-color-blind';
res{cnt_res,1}.sname='Participants, English (no color blind)';

subplot(2,2,4);

fname='data/export_ru_color_no_color_blind.csv';

[ustrs_rp,cstrs_rp,sres_rp,pres_rp,nres_rp,BOOT_rp,avg_colors_rp,sleg_rp]=load_plot_psynet_experiments(fname,rgbs,yxs,NBOOT,RU_BASIC);
title('Russian Human Experiment')
cnt_res=cnt_res+1;
res{cnt_res,1}.nres=nres_rp;
res{cnt_res,1}.BOOT=BOOT_rp;
res{cnt_res,1}.name='Russian Human Experiment no-color-blind';
res{cnt_res,1}.sname='Participants, Russian (no color blind)';



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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SPECIFIC COMPARISONS:
bar_comp=cell(2,1);
bar_comp{1}={'Participants, English','GPT3, English';'Participants, English','GPT3.5, English';...
    'Participants, English','GPT4, English';};
bar_comp{2}={'Participants, Russian','GPT3, Russian';'Participants, Russian','GPT3.5, Russian';...
    'Participants, Russian','GPT4, Russian'};

bar_comp{3}={'Participants, English','GPT3, Russian';'Participants, English','GPT3.5, Russian';...
    'Participants, English','GPT4, Russian'};
bar_comp{4}={'Participants, Russian','GPT3, English';'Participants, Russian','GPT3.5, English';...
    'Participants, Russian','GPT4, English';};



NK=length(bar_comp);
mbar=nan(size(bar_comp{1},1),NK);
mleg=cell(size(bar_comp{1},1),NK);

for K=1:NK
    for I=1:size(bar_comp{K},1)
        my_bar_comp=bar_comp{K};
        idx1=find(strcmp(ssnames,my_bar_comp{I,1}));
        idx2=find(strcmp(ssnames,my_bar_comp{I,2}));
        score=rand_index(res{idx1}.nres,res{idx2}.nres,'adjusted');
        mbar(I,K)=score;
        mleg{I,K}=sprintf('%s -- %s',ssnames{idx1},ssnames{idx2});
        mgrp=ssnames{idx1};

    end
end
figure(6);clf;
bar(mbar');
legend({'GPT3','GPT3.5','GPT4'},'Location','northeastoutside');
set(gca,'XTick',1:4);
set(gca,'XTickLabel',{'English participants and models','Russian participant and models','English participants Russian models','Russian participants English models'});



