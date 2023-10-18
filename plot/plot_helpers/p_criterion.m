function p_ast = p_criterion(p_value)
denom = 1;
p_crit = [.05/denom, .05/(denom*10), .05/(denom*100)];
if isnan(p_value) || p_value > p_crit(1)
    p_ast = '';
elseif p_value <= p_crit(1) && p_value > p_crit(2)
    p_ast = '*';
elseif p_value <= p_crit(2) && p_value > p_crit(3)
    p_ast = '**';
elseif p_value <= p_crit(3)
    p_ast = '***';
end
end