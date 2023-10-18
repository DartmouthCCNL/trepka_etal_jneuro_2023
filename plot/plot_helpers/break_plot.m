function break_plot(axis_pos)
axes('Position',[axis_pos(1)+axis_pos(3)*.55 axis_pos(2)-axis_pos(4)*1.27 .07*axis_pos(3) .07*axis_pos(3)]);
px1=[0 5];
py1=[0 10];
px2=[3 8];
py2 = [0 10];
plot(px1,py1,'k','LineWidth',1.5, 'markersize', 0.01);hold all;
plot(px2,py2,'k','LineWidth',1.5,'markersize', 0.01);hold all;
fill([px1 flip(px2)],[py1 flip(py2)],'w','EdgeColor','w');
box off;
axis off;
end