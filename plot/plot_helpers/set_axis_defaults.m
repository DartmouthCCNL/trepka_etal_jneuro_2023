function set_axis_defaults
    set(gca, 'FontName', 'Helvetica', 'FontSize', 14,'FontWeight','normal', 'LineWidth', 2, 'tickdir', 'out', 'box','off');
            curr_legend = findobj(gcf, 'Type', 'Legend');
    if strcmp(class(curr_legend), 'matlab.graphics.illustration.Legend')
        set(curr_legend, "Location", "Best");
    end
end