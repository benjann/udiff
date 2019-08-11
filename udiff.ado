*! version 1.0.0  11aug2019  Ben Jann & Simon Seiler

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
    syntax varlist(numeric fv min=2)      ///
        [if] [in] [fw iw pw aw],          ///
            /// model
            layer(varlist numeric fv)     /// 
            [                             ///
            CONTrols(varlist numeric fv)  ///
            Baseoutcome(passthru)         ///
            noConstant                    ///
            /// estimation
            vce(passthru)                 ///
            CLuster(passthru) Robust      ///
            svy SUBpop(passthru)          ///
            ITERate(passthru)             /// 
            from(passthru)                ///
            /// display
            NOIsily ALLequations eform    ///
            *                             ///
            ]
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
    mlopts mlopts, `options' `vce' `iterate'
    if "`weight'" != "" {
       local wgt "[`weight'`exp']" 
    }
    
    // mark sample
    marksample touse
    markout `touse' `layer' `controls' `clustvar'
    if "`svy'"!="" svymarkout `touse'
    
    // parse varlist
    gettoken destin origin : varlist
    local origin `origin'
    _fv_check_depvar `destin'
    
    // run mlogit to collect info on outcomes and get starting values
    if "`svy'"!="" {
        if `"`subpop'"'!="" local svyprefix `"svy, `subpop':"'
        else                local svyprefix "svy:"
    }
    if "`noisily'"!="" di as txt _n "Constant mobility model"
    else di as txt _n "Fitting constant mobility model ..." _c
    qui `noisily' `svyprefix' ///
        mlogit `destin' `origin' `layer' `controls' `wgt' ///
        if `touse', `baseoutcome' `constant' `vce' `iterate'
    if "`noisily'"=="" di as txt " done."
    tempname b0 out
    matrix `b0' = e(b)
    matrix `out' = e(out)
    local nout = e(k_out)
    local ibase = e(ibaseout)
    local baseout = e(baseout)
    local outnames `"`e(eqnames)'"'
    local eqlist `"`e(eqnames)'"'
    local baselab `"`e(baselab)'"'
    local lf0 = e(ll)
    if `lf0'<. {
        local lf0opt = e(df_m) + (`nout' - 1) // #k
        local lf0opt lf0(`lf0opt' `lf0')
    }
    
    // starting values
    if `"`from'"'=="" {
        fvexpand `origin' if `touse'
        mata: udiff_b0("`b0'", "Psi_", `ibase', tokens(st_global("r(varlist)")))
        local init init(`b0') search(off)
    }
    else {
        local init `"init(`from')"'
    }

    // put equations together
    local eqnames1
    local eqnames2
    forval i = 1/`nout' {
        gettoken eq eqlist : eqlist
        local val = `out'[1,`i']
        local olist `olist' `val'
        if `i' == `ibase' continue
        local theta `theta' (`eq': `layer' `controls', `constant')
        local eqnames1 `eqnames1' `eq'
        local psi `psi' (Psi_`eq': `origin', nocons)
        local eqnames2 `eqnames2' Psi_`eq'
    }
    local eqnames Phi `eqnames2' `eqnames1'

    // optimize
    nobreak {
        global UDIFF_nout  `nout'
        global UDIFF_ibase `ibase'
        global UDIFF_olist `olist'
        capture noisily break {
            ml model lf udiff_lf (Phi: `destin'=`layer', nocons) `psi' `theta' ///
                if `touse' `wgt', maximize missing `lf0opt' /// 
                `mlopts' `init' `svy' `subpop'
        }
        global UDIFF_nout
        global UDIFF_ibase
        global UDIFF_olist
        if _rc exit _rc
    }

    // returns
    eret scalar k_eform  = e(k_eq)
    eret scalar ibaseout = `ibase'
    eret scalar baseout  = `baseout'
    eret scalar k_out    = `nout'
    eret local predict   "udiff_p"
    eret local cmd       "udiff"
    eret matrix out      = `out'
    eret local outnames  `"`outnames'"'
    eret local eqnames   `"`eqnames'"'
    eret local controls  `"`controls'"'
    eret local layer     `"`layer'"'
    eret local indepvars `"`origin'"'
    eret local baselab   `"`baselab'"'
    eret local title     "Individual-level unidiff estimator"

    // display
    Display, `diopts' `eform' `allequations'
end

program Display
    syntax [, ALLequations * ]
    if "`allequations'"=="" local first neq(1)
    ml display, `first' `options'
end

version 11
mata:
mata set matastrict on

void udiff_b0(string scalar b, string scalar stub, real scalar ibase,
    string rowvector origin)
{
    real scalar    i, j, k, n, r, rc
    string scalar  eq, eq0
    string matrix  cstripe
    real colvector p

    rc = 0
    r = length(origin)
    cstripe = st_matrixcolstripe(b)
    n = rows(cstripe)
    p = J(n,1,1)
    k = 0; eq0 = ""
    for (i=1; i<=n; i++) {
        eq = cstripe[i,1]
        if (eq!=eq0) {
            k++
            j = 0
            eq0 = eq
        }
        if (k==ibase) {
            p[i] = 0
            continue
        }
        j++
        if (j<=r) {
            if (cstripe[i,2]!=origin[j]) {
                rc = 1
                p[i] = 0
                continue
            }
            cstripe[i,1] = stub + eq
        }
    }
    st_matrix(b, select(st_matrix(b)', p)')
    st_matrixcolstripe(b, select(cstripe, p))
    if (rc) printf("\n{txt}{bf:Warning: inconsistent vector of initial values}\n")
}

end

