function nt = add_exclusions_full(nt)
    flag = config();
    include = ones(height(nt), 1);
    nt.include = include; % include all neurons by default

    components = ["intrinsic", "seasonal", "cue", "sample", "match", "samplexmatch", "all_tr"];
    for component = components
        include = zeros(height(nt), 1);

        for i = 1:height(nt)
            full = nt{i, "r2_dist_full"};
            minus_comp = nt{i, "r2_dist_" + component};
            if sum(~isnan(full)) > 0 && sum(~isnan(minus_comp)) > 0
                include(i) = signrank(full,minus_comp,'tail','right') < .05;
            end
        end
        
        if component == "seasonal"
            if flag.rem_negative_seasonal
               include = include & nt{1:end, "sea_rs"} >= 0; 
            end
        end
        % for intrinsic component, we apply additional exclusion criteria 
        % to ensure we only include neurons with good exponential fit
        if component == "intrinsic"
            disp("intrinsic: " + sum(include) + " total");
            include = include & nt{1:end, "intrinsic_mi_exp"} < flag.int_max_idx; 
            disp("intrinsic: " + sum(include) +  " first decreasing lag within 50 ms*" + flag.int_max_idx);
            include = include & nt{1:end, "intrinsic_r2_exp"} > flag.int_min_r2; 
            disp("intrinsic: " + sum(include) + " exp r2 greater than " + flag.int_min_r2);
            include = include & nt{1:end, "intrinsic_acf"}(:, 10) < flag.max_acf_end; 
            disp("intrinsic: " + sum(include) + " intrinsic acf ends less than " + flag.max_acf_end);
        end
        nt.("include_" + component) = include;
    end
end