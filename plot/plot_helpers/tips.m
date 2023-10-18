function tips(xs, ytop, width,height, color, linwidth)
    plot([xs(1)+width, xs(1)+width], [ytop-height, ytop], 'Color', color, 'LineWidth', linwidth);
    plot([xs(2)-width, xs(2)-width], [ytop-height, ytop], 'Color', color, 'LineWidth', linwidth);

end