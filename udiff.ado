*! version 1.1.1  20aug2019  Ben Jann & Simon Seiler

program udiff, eclass
    version 11
    if replay() {
        if "`e(cmd)'" != "udiff" error 301
        Display `0'
        exit
    }
    local version : di "version " string(_caller()) ":"
    `version' _vce_parserun udiff : `0'
    if "`s(exit)'" != "" {
        ereturn local cmdline `"udiff `0'"'
        exit
    }
    Estimate `0'
    ereturn local cmdline `"udiff `0'"'
end

program Estimate, eclass
    // syntax
        syntax [anything] [if] [in] [fw iw pw aw] [, ///
            /// model
            CONTrols(varlist numeric fv)             ///
            Baseoutcome(passthru)                    ///
            noConstant                               ///
            /// estimation
            vce(passthru)                            ///
            CLuster(passthru) Robust                 ///
            svy SUBpop(passthru)                     ///
            from(passthru)                           ///
            CONSTRaints(numlist int <=1 <=1999)      ///
            INITOPTs(str asis)                       ///
            /// display
            NOIsily noLOg noHeader                   ///
            ALLequations eform                       ///
            *                                        ///
            ]
    ParseVarlist `anything'          // returns depvar, xvars, xvars#, nunidiff
    ParseLayer `nunidiff' `options'  // returns layer, layer#, options
    local vceopt =  `:length local vce'      | ///
                    `:length local weight'   | ///
                    `:length local cluster'  | ///
                    `:length local robust'
    if `vceopt' {
        _vce_parse, argopt(CLuster) opt(OIM OPG Robust) old     ///
            : [`weight'`exp'], `vce' `robust' `cluster'
        local vce
        if "`r(cluster)'" != "" {
            local clustvar `r(cluster)'
            local vce vce(cluster `r(cluster)')
        }
        else if "`r(robust)'" != "" {
            local vce vce(robust)
        }
        else if "`r(vce)'" != "" {
            local vce vce(`r(vce)')
        }
    }
    _get_diopts diopts options, `options'
    local diopts `diopts' `header'
    mlopts mlopts, `options' `vce'
    if "`weight'" != "" {
       local wgt "[`weight'`exp']" 
    }
    
    // mark sample
    marksample touse
    markout `touse' `depvar' `xvars' `layer' `controls' `clustvar'
    if "`svy'"!="" svymarkout `touse'
    
    // check depvar
    capt assert (`depvar'==abs(int(`depvar'))) if `touse'
    if _rc {
        di as err "{it:depvar} may not contain negative or noninteger values"
        exit 498
    }
    
    // collect information on outcomes and check for collinearity
    // - expand factor variables (so that terms can be matched after _rmcoll)
    local xvars
    local layer
    forv i=1/`nunidiff' {
        fvexpand `xvars`i'' if `touse'
        local xvars`i' `r(varlist)'
        local xvars `xvars' `r(varlist)'
        fvexpand `layer`i'' if `touse'
        local layer`i' `r(varlist)'
        local layer `layer' `r(varlist)'
    }
    if `"`controls'"'!="" {
        fvexpand `controls' if `touse'
        local controls `r(varlist)'
    }
    // - run _rmcoll
    _rmcoll `depvar' `xvars' `layer' `controls' `wgt' if `touse', ///
            `constant' noskipline mlogit `baseoutcome' expand
    // - rebuild variable lists
    local vlist `r(varlist)'
    local xvars
    gettoken depvar vlist : vlist
    forv j=1/`nunidiff' {
        local n: list sizeof xvars`j'
        local xvars`j'
        forv i=1/`n' {
            gettoken term vlist : vlist
            local xvars`j' `xvars`j'' `term'
            local xvars `xvars' `term'
        }
    }
    local layer
    forv j=1/`nunidiff' {
        local n: list sizeof layer`j'
        local layer`j'
        forv i=1/`n' {
            gettoken term vlist : vlist
            local layer`j' `layer`j'' `term'
            local layer `layer' `term'
        }
    }
    local n: list sizeof controls
    local controls
    forv i=1/`n' {
        gettoken term vlist : vlist
        local controls `controls' `term'
    }

    // - process info on outcomes
    tempname OUT
    matrix `OUT' = r(out)
    local nout = r(k_out)
    if (`nout' == 1) error 148
    local ibase = r(ibaseout)
    local baseout = r(baseout)
    local out
    forval i = 1/`nout' {
        local val = `OUT'[1,`i']
        local out `out' `val'
    }
    local out_labels
    if "`: val lab `depvar''"!="" {
        forval i = 1/`nout' {
            local val: word `i' of `out'
            local lbl: lab (`depvar') `val', strict
            local out_labels `"`out_labels'`"`lbl'"' "'
        }
        local out_labels: list clean out_labels
        tempvar depvar2
        qui gen `: type `depvar'' `depvar2' = `depvar' if `touse'
    }
    else local depvar2 `depvar'
    
    // unidiff equation names
    local Phi "Phi"
    local Psi "Psi"
    local Theta "Theta"
    
    // starting values
    if `"`from'"'=="" {
        if "`svy'"!="" {
            if `"`subpop'"'!="" local svyprefix `"svy, `subpop':"'
            else                local svyprefix "svy:"
        }
        if "`noisily'"!="" di as txt _n "Constant fluidity model"
        nobreak {
            local initconstr
            if `"`constraints'"'!="" { // => translate constraints for mlogit
                InitoptsHasConstraint, `initopts'
                if `inithasconstr'==0 {
                    foreach i of local constraints {
                        constraint get `i'
                        if r(defined)==0 continue
                        local constr `"`r(contents)'"'
                        if `nunidiff'==1 {
                            if strpos(`"`constr'"', "`Phi'") continue
                        }
                        else {
                            local break
                            forv j=1/`nunidiff' {
                                if strpos(`"`constr'"', "`Phi'`j'") {
                                    local break break
                                    continue, break
                                }
                            }
                            if "`break'"!="" continue
                        }
                        if `nunidiff'==1 {
                            local constr: subinstr local constr "`Psi'_" "", all
                        }
                        else {
                            forv j=1/`nunidiff' {
                                local constr: subinstr local constr "`Psi'`j'_" "", all
                            }
                        }
                        local constr: subinstr local constr "`Theta'_" "", all
                        constraint free
                        local j = r(free)
                        constraint `j' `constr'
                        local initconstr `initconstr' `j'
                    }
                    local initopts `initopts' constraints(`initconstr')
                }
            }
            capture `noisily' break {
                `svyprefix' mlogit `depvar2' `xvars' `layer' `controls' ///
                    `wgt' if `touse', collinear `baseoutcome' `constant' ///
                    `vce' `initopts'
            }
            local rc = _rc
            if `"`initconstr'"'!="" {
                constraint drop `initconstr'
            }
            if `rc' exit `rc'
        }
        tempname b0
        matrix `b0' = e(b)
        local lf0 = e(ll)
        if `lf0'<. {
            local lf0opt = e(rank)
            local lf0opt lf0(`lf0opt' `lf0')
        }
        mata: udiff_b0("`b0'","`Psi'", "`Theta'", `ibase', `nunidiff')
        local init init(`b0') search(off)
    }
    else {
        local init `"init(`from')"'
    }

    // put equations together
    local eqnames
    forv j=1/`nunidiff' {
        if (`nunidiff'==1) local term `Phi'
        else               local term `Phi'`j'
        local phi `phi' (`term': `depvar'=`layer`j'', nocons)
        local eqnames `eqnames' `term'
    }
    forv j=1/`nunidiff' {
        if (`nunidiff'==1) local term `Psi'
        else               local term `Psi'`j'
        forval i = 1/`nout' {
            if `i' == `ibase' continue
            local val: word `i' of `out'
            local psi `psi' (`term'_`val': `xvars`j'', nocons)
            local eqnames `eqnames' `term'_`val'
        }
    }
    forval i = 1/`nout' {
        if `i' == `ibase' continue
        local val: word `i' of `out'
        local theta `theta' (`Theta'_`val': `layer' `controls', `constant')
        local eqnames `eqnames' `Theta'_`val'
    }
    
    // optimize
    nobreak {
        global UDIFF_nout     `nout'
        global UDIFF_out      `out'
        global UDIFF_ibase    `ibase'
        global UDIFF_nunidiff `nunidiff'
        capture noisily break {
            ml model lf udiff_lf `phi' `psi' `theta' ///
                if `touse' `wgt', maximize missing collinear `log' `lf0opt' /// 
                constraints(`constraints') `mlopts' `init' `svy' `subpop'
        }
        global UDIFF_nout
        global UDIFF_out
        global UDIFF_ibase
        global UDIFF_nunidiff
        if _rc exit _rc
    }

    // returns
    eret scalar k_eform    = e(k_eq)
    eret scalar ibaseout   = `ibase'
    eret scalar k_out      = `nout'
    eret scalar k_unidiff  = `nunidiff'
    eret local predict    "udiff_p"
    eret local cmd        "udiff"
    eret local out        "`out'"
    eret local baseout    "`baseout'"
    eret local out_labels `"`out_labels'"'
    eret local eqnames    `"`eqnames'"'
    eret local controls   `"`controls'"'
    forv j=1/`nunidiff' {
        if `nunidiff'==1 {
            eret local layer      `"`layer`j''"'
            eret local indepvars  `"`xvars`j''"'
        }
        else {
            eret local layer`j'      `"`layer`j''"'
            eret local indepvars`j'  `"`xvars`j''"'
        }
    }
    eret local title      "Individual-level unidiff estimator"

    // display
    Display, `diopts' `eform' `allequations'
end

program ParseVarlist
    syntax varlist(numeric fv min=2) // basic check
    gettoken depvar vlist : 0, parse(" (")
    _fv_check_depvar `depvar'
    c_local depvar `depvar'
    local i 0
    local xvars
    gettoken varlist : vlist, match(par)
    if (`"`par'"'!="(") {
        local ++i
        local 0 `"`vlist'"'
        syntax varlist(numeric fv)
        c_local xvars1 `varlist'
        local xvars `xvars' `varlist'
    }
    else {
        while (`"`vlist'"'!="") {
            local ++i
            gettoken varlist vlist : vlist, match(par)
            if (`"`par'"'!="(") error 198
            local 0 `"`varlist'"'
            syntax varlist(numeric fv)
            c_local xvars`i' `varlist'
            local xvars `xvars' `varlist'
        }
    }
    c_local xvars    `xvars'
    c_local nunidiff `i'
end

program ParseLayer
    gettoken nunidiff options : 0
    local layers
    forv i=1/`nunidiff' {
        local 0 `", `options'"'
        syntax, layer(varlist numeric fv) [ * ]
        c_local layer`i' `"`layer'"'
        local layers `layers' `layer'
    }
    c_local layer `layers'
    c_local options `options'
end

program InitoptsHasConstraint
    syntax [, Constraints(passthru) * ]
    c_local inithasconstr = `"`constraints'"'!=""
end

program Display
    syntax [, ALLequations noHeader * ]
    if "`allequations'"=="" local first neq(`e(k_unidiff)')
    if "`header'"=="" {
        _coef_table_header
        if "`allequations'"!="" {
            local lbls `"`e(out_labels)'"'
            if `:list sizeof lbls' {
                local out "`e(out)'"
                local depvar "`e(depvar)'"
                di as txt ""
                foreach o of local out {
                    gettoken lbl lbls : lbls
                    di as txt %13s "`o'" ": `depvar' = " as res `"`lbl'"'
                }
            }
        }
    }
    di ""
    ml display, noheader `first' `options'
end

version 11
mata:
mata set matastrict on

void udiff_b0(string scalar b, string scalar psi, string scalar theta,
    real scalar ibase, real scalar nunidiff)
{
    real scalar    i, j, k, l, sn, r
    string scalar  eq, eq0
    string matrix  cstripe
    real colvector p
    real rowvector R

    R = J(1, nunidiff, .)
    for (l=1; l<=nunidiff; l++) {
        R[l] = length(tokens(st_local("xvars"+strofreal(l))))
    }
    cstripe = st_matrixcolstripe(b)
    n = rows(cstripe)
    p = J(n,1,1)
    k = 0; eq0 = ""
    for (i=1; i<=n; i++) {
        eq = cstripe[i,1]
        if (eq!=eq0) {
            k++
            j = 0
            l = 1
            r = R[l]
            eq0 = eq
        }
        if (k==ibase) {
            p[i] = 0
            continue
        }
        j++
        if (j>r) {
            if (l<nunidiff) {
                l++
                r = r + R[l]
            }
            else {
                cstripe[i,1] = theta + "_" + eq
                continue
            }
        }
        cstripe[i,1] = psi + (nunidiff==1 ? "" : strofreal(l))  + "_" + eq
    }
    st_matrix(b, select(st_matrix(b)', p)')
    st_matrixcolstripe(b, select(cstripe, p))
}

end

