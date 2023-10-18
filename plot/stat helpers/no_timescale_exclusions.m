function [timescales, mask] = no_timescale_exclusions(timescales, exclusions)
% apply exclusions
for i=1:length(timescales)
    for j = 1:length(timescales{1})
        orig_len = length(timescales{i}{j});
        idxes = 1:orig_len;
        curr_ts = timescales{i}{j};
        
        % apply exclusion crit 1 - param cannot be greater than possible
        % timescale
        exclude_one = curr_ts<exclusions(i);
        curr_ts = curr_ts;%(exclude_one);
        idxes = idxes;%(exclude_one);
                
        % apply exclusion crit 2 - ><1.5 iqr
        exclude_two = ~isoutlier(curr_ts,'quartiles');
        timescales{i}{j} = curr_ts%(exclude_two);
        idxes = idxes%(exclude_two);
        
        curr_mask = zeros(orig_len,1);
        curr_mask(idxes) = 1;
        mask{i}{j} = curr_mask;
    end
end
end