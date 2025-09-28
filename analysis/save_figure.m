% Save figure 

function save_figure(figure_handle_h, title, file_type)

    if isfile([title, '.',file_type])
        fprintf('File already exists');
        return;
    end

    set(figure_handle_h, 'Units','Inches');
    pos = get(figure_handle_h,'Position');
    set(figure_handle_h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]);
    
    if strcmp(file_type, 'pdf')    
        print(figure_handle_h,[title],'-dpdf', '-fillpage', '-opengl');

    elseif strcmp(file_type, 'eps')
        print(figure_handle_h,[title],'-depsc','-r300');

    elseif strcmp(file_type, 'svg')
        print(figure_handle_h,[title],'-dsvg','-r300');
        
    elseif strcmp(file_type, 'ps')
        print(figure_handle_h,[title],'-dpsc','-r300');
            
    elseif strcmp(file_type, 'png')
        print(figure_handle_h,[title],'-dpng','-r300');
        
    elseif strcmp(file_type, 'tiff')
        print(figure_handle_h,[title],'-dtiff','-r300');
        
    else 
        fprintf('Unexpected file type');
    end

end
