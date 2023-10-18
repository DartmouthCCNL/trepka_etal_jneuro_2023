function [r2, min_tau] = fit_exp(times, rs, component)
flag = config();

% reshape and remove nan
rs = reshape(rs, [], 1);
times = reshape(times, [], 1);
remove_idx = isnan(rs) | isnan(times);
rs(remove_idx) = [];
times(remove_idx) = [];

par = struct; 

if component == "intrinsic"
par.int_a_bound = [0, 1];
par.int_tau_bound = [1e-1, 500];
par.int_b_bound = [-1, 1];
par.iters = 5;
par.int_order = flag.intrinsic_order;
elseif component == "seasonal"
par.int_a_bound = [0, 1];
par.int_tau_bound = [1e-1, 25];
par.int_b_bound = [-1, 1];
par.iters = 5;
par.int_order = flag.seasonal_order;
end

 min_mse = 1e20;
 for iii = 1:par.iters
    c = "int_";
    abound = par.(c + 'a_bound');
    bbound = par.(c + 'b_bound');
    tbound = par.(c + 'tau_bound');

    A_init = unifrnd(abound(1),abound(2));
    B_init = unifrnd(bbound(1),bbound(2));
    tau_init = unifrnd(tbound(1), tbound(2));
    fitted_params = [A_init, B_init, tau_init];
    while fitted_params(1) == A_init && fitted_params(2) == B_init && fitted_params(3) == tau_init
        A_init = unifrnd(abound(1),abound(2));
        B_init = unifrnd(bbound(1),bbound(2));
        tau_init = unifrnd(tbound(1), tbound(2));

        [fitted_params, ~, ~, ~, ~, ~, jacobian] = lsqnonlin(@(p) exponential_decay_fit(p, times, rs), ...
                                  [A_init, B_init, tau_init], ...
                                  [abound(1), bbound(1), tbound(1)], ...
                                  [abound(2), bbound(2), tbound(2)], optimset('display', 'off'));
    end

    rs_pred = exponential_decay(fitted_params, times);
    mse = sum((rs_pred-rs).^2);

    if mse < min_mse
        min_mse = mse;
        if component == "intrinsic"
            min_pred = exponential_decay(fitted_params, flip(linspace(-50*flag.intrinsic_order, -50, 100)));

            rss = sum((rs_pred-rs).^2);
            tss = sum((rs - mean(rs)).^2);
            r2 = 1 - rss/tss;
        elseif component == "seasonal"
            min_pred = exponential_decay(fitted_params, flip(linspace(-flag.triallen*flag.seasonal_order, -flag.triallen, 100)));
        end
        min_tau = fitted_params(3);
    end
 end
end

function y_fit = exponential_decay_fit(params, t, y)
    y_fit = exponential_decay(params, t) - y;
end

function y_fit = exponential_decay(params, t)
    A = params(1);
    B = params(2);
    tau = params(3);
    y_fit = A * exp(t./tau) + B;
end
