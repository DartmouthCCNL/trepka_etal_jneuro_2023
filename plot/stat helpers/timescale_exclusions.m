function [timescales, mask] = timescale_exclusions(timescales, thresholds)
% apply exclusions
for i=1:length(timescales)
    for j = 1:length(timescales{1})
        orig_len = length(timescales{i}{j});
        idxes = 1:orig_len;
        curr_ts = timescales{i}{j};
        
        % apply exclusion crit - > timescales less than threshold
        %exclude_one = ~(curr_ts>thresholds(i));
        
        % apply exclusion crit - ><1.5 iqr
        exclude_two = ~isoutlier(curr_ts,'quartiles');
        exclude_one = exclude_two;
        timescales{i}{j} = curr_ts(exclude_one & exclude_two);
        idxes = idxes(exclude_one & exclude_two);
        
        curr_mask = zeros(orig_len,1);
        curr_mask(idxes) = 1;
        mask{i}{j} = curr_mask;
    end
end
end