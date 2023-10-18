function save_close_figures(save_path) 
FigList = findobj(allchild(0), 'flat', 'Type', 'figure');
for i=length(FigList):-1:1
    %fig = FigList(i);
    %set(fig, 'WindowState', 'maximized');
    %set(0, 'CurrentFigure', fig);
    %set(gcf,'Units','inches');
    %screenposition = get(gcf,'Position');
    %set(gcf,...
    %'PaperPosition',[0 0 screenposition(3:4)],...
    %'PaperSize',[screenposition(3:4)]);
    %pause(2)
    print('-dpdf','-painters', strcat(save_path, num2str(i)))
    %set(gcf, 'PaperUnits', 'centimeters');
    %set(gcf, 'PaperPosition', [0 0 20 10]); %x_width=10cm y_width=15cm
    %saveas(gcf, strcat(save_path, num2str(i),'.tif'));
    close;
end
end