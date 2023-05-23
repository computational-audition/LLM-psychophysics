function [rgbs,yxs,xnum]=get_plot_wcs_colors(is_plot)
wcs_colors=readtable('data/cnum-vhcm-lab-new.txt');


VS={'A','B','C','D','E','F','G','H','I','J'};

rgbs=nan(size(wcs_colors,1),3);
yxs=nan(size(wcs_colors,1),2);
xnum=nan(size(wcs_colors,1),2);

for I=1:size(wcs_colors,1)
    rgb=lab2rgb([wcs_colors.L_(I),wcs_colors.a_(I),wcs_colors.b_(I)],'OutputType','uint8');
    y=length(VS)-find(strcmp(wcs_colors.V(I),VS))+1;
    x=wcs_colors.H(I);
    yxs(I,:)=[y,x];
    rgbs(I,:)=rgb;
    xnum(I)=wcs_colors.x_cnum(I);
end

if is_plot
    %figure(1);clf;

    for I=1:size(rgbs)
        x=yxs(I,2);
        y=yxs(I,1);
        rectangle("FaceColor",rgbs(I,:)/255,'Position',[x-0.5,y-0.5,1,1]);hold on;
    end

    set(gca,'YTick',1:length(VS))
    set(gca,'YTickLabels',VS(length(VS):-1:1))
    set(gca,'XTick',1:40)

    xlim([-2 41]);
    set(gca,'FontSize',14)
end