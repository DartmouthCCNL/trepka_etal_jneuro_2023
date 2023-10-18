function [h, p, chi2stat, test_string] = chi_squared_test(n1, N1, n2, N2)
    x1 = [repmat('a',N1,1); repmat('b',N2,1)];
    x2 = [repmat(1,n1,1); repmat(2,N1-n1,1); repmat(1,n2,1); repmat(2,N2-n2,1)];
    %output
    [tbl,chi2stat,p] = crosstab(x1,x2);
    test_string = strcat("\chi^2(1,", int2str(N1+N2), ")=", num2str(chi2stat), ", p=",num2str(p));
    h = p<.05;
end