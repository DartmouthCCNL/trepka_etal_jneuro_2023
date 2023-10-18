function [t, n] = convert_nt_rall(nt, ending, timescales, pre_or_suf)

if ~exist("pre_or_suf", 'var')
    pre_or_suf = 'suffix';
end

areas = unique(nt.area);

t = {};
for i = 1:length(timescales)
    t{i} = {};
    if pre_or_suf == 'suffix'
        r2_val = nt{:, timescales(i) + "_" + ending} ;
    else
        r2_val = nt{:, ending + "_" + timescales(i)} ;
    end
        
    nt_sub = nt(logical(r2_val > 0), :);

    for j = 1:length(areas)
        nt_asub = nt_sub(nt_sub{:, "area"} == areas(j), :);
        if pre_or_suf == 'suffix'
            t{i}{end+1} = nt_asub{:, timescales(i) + "_" + ending};
        else
            t{i}{end+1} = nt_asub{:, ending + "_" + timescales(i)};
        end
        disp(timescales{i} + " " + string(areas(j)) + ": " + length(t{i}{end}));
    end
end

n = [];
for j = 1:length(areas)
    n(j) = sum(nt{:, "area"} == areas(j));
end
end