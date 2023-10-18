function [t, n] = convert_nt(nt)

areas = unique(nt.area);
timescales = ["intrinsic", "seasonal"];

t = {};
t = {};
for i = 1:length(timescales)
    t{i} = {};
    nt_sub = nt(logical(nt{:, "include"}), :);
    for j = 1:length(areas)
        nt_asub = nt_sub(nt_sub{:, "area"} == areas(j), :);
        t{i}{end+1} = nt_asub{:, timescales(i) + "_tau"};
    end
end


n = [];
for j = 1:length(areas)
    n(j) = sum(nt{:, "area"} == areas(j));
end
end