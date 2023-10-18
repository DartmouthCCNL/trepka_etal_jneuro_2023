function rs_out = compute_acf_from_ars(ar_coeffs)
% commpute the autocorrelation function corresponding to autoregressive
% coefficients by optimziing yule-walker equations

order = length(ar_coeffs);
rs = optimvar('rs',order,"LowerBound", -1, "UpperBound", 1);
ars = ar_coeffs';

eqns = {};
for i = 1:order
rs_flip = flip(rs);
if i == 1
    eqnn = ars(i) + sum(rs(1:end-i).*ars(i+1:end));
elseif i == order
    eqnn = ars(i) + sum(rs_flip(end-i+2:end).*ars(1:i-1));
else
    eqnn = ars(i) + sum(rs(1:end-i).*ars(i+1:end)) + sum(rs_flip(end-i+2:end).*ars(1:i-1));
end
eqns{i} = eqnn - rs(i);
end

prob = eqnproblem;
for i = 1:order
prob.Equations.("eqn" + i) = eqns{i} == 0;
end

x0.rs = .5 * ones(1, order);
[sol,fval,exitflag] = solve(prob,x0);

rs_out = sol.rs';

end


% for an AR(1) process parametrized by xt = a1xt-1 + b, the autocorrelation function 
% at each time lag = a1^(t)
%
% for an AR(2) process parametrized by xt = a1xt-1 + a2xt-2 + b, the
% autocorrelation function at each time lag has an analytical solution
% p(1) = a1/(1-a2)
% p(2) = a1^2/(1-a2) + a2
% p(e) = (a1^3 + a1a2)/(a-a2) + a1a2
% for an AR(p) process, analytical solution is less clear 


% alternative solution based on simulating AR models, produces equivalent
% solution
% 
% rs = zeros(size(ar_coeffs));
% 
% for jj = 1:size(ar_coeffs, 1)
%     try
%         Mdl = arima('Constant',0,'AR',ar_coeffs(jj, :),'Variance',1);
%         npaths = 50;
%         Y = simulate(Mdl,20000, 'NumPaths', npaths);
%         all_acf = [];
%         for ii = 1:npaths
%             [acf, lags] = autocorr(Y(:, ii));
%             all_acf = [all_acf; acf'];
%         end
%         acf = nanmean(all_acf, 1);
%     catch
%         acf = [1, ar_coeffs]; 
%     end
%     rs(jj, :) = acf(2:size(ar_coeffs, 2)+1);
% end