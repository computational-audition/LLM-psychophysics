function print_screen(FILE_NAME_SEED,DATA_EXPORT_DIRECTORY,screen_size)

if isempty(screen_size)
    %%% do nothing
    scale_factor=1;

else
    switch screen_size
        case 'big'
            set(gcf,'Units','Normalized')
            set(gcf,'Position',[0.03    0.03    0.93   0.93])
            scale_factor=1;
        case 'scale_medium'
            scale_factor=0.6;
        case 'scale_big'
            scale_factor=0.8;
        case 'scale_small'
            scale_factor=0.5;
        case 'scale_tiny'
            scale_factor=0.4;
        otherwise
            fprintf('screen_size %s is incorrect\n',screen_size);
            assert(1==0);
    end
end

drawnow; % make sure things plotted before start printing.

% png file: (all groups)
cname=sprintf('%s/%s.png',DATA_EXPORT_DIRECTORY,FILE_NAME_SEED);
fprintf('png:\tsaving to: %s \n',cname);
print(cname,'-dpng','-r300');

% pdf file: (all groups)
pname=sprintf('%s/%s.pdf',DATA_EXPORT_DIRECTORY,FILE_NAME_SEED);
fprintf('pdf:\tsaving to: %s \n',pname);

set(0,'units','inches');screenSizeInches = get(0,'screensize');largePaperSize = screenSizeInches*scale_factor;
set(gcf,'papersize',largePaperSize (3:4))
print(gcf, pname, '-dpdf', '-vector', '-r300');