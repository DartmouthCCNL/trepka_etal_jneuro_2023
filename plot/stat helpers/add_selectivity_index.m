% compute selectivity index during cue-stimulus, cue-delay,
% sample-stimulus, sample-delay periods

function nt = add_selectivity_index(nt)
cue_pres_sel = [];
cue_delay_sel = [];
for i = 1:height(nt)
    nt_single = nt(i,:);

    scope = nt_single.scope.cue(1:8);
    profile = nt_single.vars(scope) + nt_single.vars(nt_single.scope.("b2"));
    profile = [profile, nt_single.vars(nt_single.scope.("b2"))];

    profile = profile/nt_single.mean_fr;
    ma = max(profile);
    mi = min(profile);
    sel_ind = (ma-mi);
    cue_pres_sel = [cue_pres_sel; sel_ind];
    
    scope = nt_single.scope.cue(9:16);
    profile = nt_single.vars(scope) + nt_single.vars(nt_single.scope.("b3"));
    profile = [profile, nt_single.vars(nt_single.scope.("b3"))];
    profile = profile/nt_single.mean_fr;
    ma = max(profile);
    mi = min(profile);
    sel_ind = (ma-mi);
    cue_delay_sel = [cue_delay_sel; sel_ind];
end
nt.cue_pres_sel = cue_pres_sel;
nt.cue_delay_sel = cue_delay_sel;
end