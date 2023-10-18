function [t, n] = convert_nt(nt, components)

areas = unique(nt.area);

t = {};
for i = 1:length(components)
    t{i} = {};

    nt_sub = nt(logical(nt{:, "include_" + components(i)}), :);
    for j = 1:length(areas)
        nt_asub = nt_sub(nt_sub{:, "area"} == areas(j), :);
        t{i}{end+1} = ones(height(nt_asub), 1);
    end
end

n = [];
for j = 1:length(areas)
    n(j) = sum(nt{:, "area"} == areas(j));
end
end