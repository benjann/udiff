*! version 1.1.4  06nov2019  Ben Jann & Simon Seiler

program udiff, eclass byable(recall) properties(svyb svyj svyr mi)
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
            from(passthru)                           ///
            CONSTRaints(numlist int <=1 <=1999)      ///
            lfado                           /// undocumented; for certification
            /// display
            NOIsily noLOg noHeader                   ///
            ALLequations eform                       ///
            *                                        ///
            ]
    if "`lfado'"=="" local lfspec lf2 udiff_lf2()
    else             local lfspec lf  udiff_lf
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
        local layer`i': list uniq layer`i'
        local layer: list layer | layer`i'
    }
    if `"`controls'"'!="" {
        fvexpand `controls' if `touse'
        local controls `r(varlist)'
    }
    local vlist `depvar' `xvars' `layer' `controls'
    local vlist0: list uniq vlist
    if `: list sizeof vlist'!=`: list sizeof vlist0' {
        di as err "inconsistent list of variables; xvars and controls must be" ///
            " unique; layer must not contain xvars or controls"
        exit 198
    }
    // - run _rmcoll
    _rmcoll `vlist' `wgt' if `touse', `constant' noskipline mlogit `baseoutcome' expand
    // - get coefficients and ll of empty model
    if `"`from'"'=="" {
        if "`constant'"=="" {
            tempname b0
            matrix `b0' = r(b0)
            local lf0 = r(ll_0)
        }
        else  local lf0 = .
    }
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
    local vlist0 `layer'
    local layer
    local n: list sizeof vlist0
    forv i=1/`n' {
        gettoken term0 vlist0 : vlist0
        gettoken term vlist : vlist
        local layer `layer' `term'
        if "`term'"!="`term0'" {
            forv j=1/`nunidiff' {
                local layer`j': subinstr local layer`j' "`term0'" "`term'", word
            }
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
    }

    // put equations together
    local Phi "Phi"
    local Psi "Psi"
    local Theta "Theta"
    local eqnames
    forv j=1/`nunidiff' {
        if (`j'==1) local thedepvar "`depvar'="
        else        local thedepvar
        if (`nunidiff'==1) local term `Phi'
        else               local term `Phi'`j'
        local phi `phi' (`term': `thedepvar'`layer`j'', nocons)
        local eqnames `eqnames' `term'
    }
    local thedepvar "`depvar'="
    forv j=1/`nunidiff' {
        if (`nunidiff'==1) local term `Psi'
        else               local term `Psi'`j'
        forval i = 1/`nout' {
            if `i' == `ibase' continue
            local val: word `i' of `out'
            local psi0 `psi0' (`term'_`val': `thedepvar'`xvars`j'', nocons)
            local thedepvar
            local psi `psi' (`term'_`val': `xvars`j'', nocons)
            local eqnames `eqnames' `term'_`val'
        }
    }
    forval i = 1/`nout' {
        if `i' == `ibase' continue
        local val: word `i' of `out'
        local theta `theta' (`Theta'_`val': `layer' `controls', `constant')
        local thetalist `thetalist' `Theta'_`val'
    }
    local eqnames `eqnames' `thetalist'
    
    // starting values (constant fluidity model)
    if `"`from'"'=="" {
        if "`noisily'"!="" di as txt _n "Constant fluidity model"
        else if "`log'"=="" di as txt _n "fitting constant fluidity model ..." _c
        mat coleq `b0' = `thetalist'
        local initopt init(`b0') 
        if !missing(`lf0') {
                local initopt `initopt' lf0(`=`nout'-1' `lf0')
        }
        nobreak {
            global UDIFF_mtype    0
            global UDIFF_nout     `nout'
            global UDIFF_out      `out'
            global UDIFF_ibase    `ibase'
            global UDIFF_nunidiff `nunidiff'
            capture `noisily' break {
                ml model `lfspec' `psi0' `theta' if `touse' `wgt', ///
                   `initopt' `mlopts' `log' search(off) collinear ///
                    constraints(`constraints') maximize missing
            }
            global UDIFF_mtype
            global UDIFF_nout
            global UDIFF_out
            global UDIFF_ibase
            global UDIFF_nunidiff
            if _rc exit _rc
        }
        if "`noisily'"!="" ml display
        else if "`log'"=="" di as txt " done"
        local initopt continue
    }
    else {
        local initopt `"init(`from')"'
    }
    
    // estimate unidiff model
    nobreak {
        global UDIFF_mtype    1
        global UDIFF_nout     `nout'
        global UDIFF_out      `out'
        global UDIFF_ibase    `ibase'
        global UDIFF_nunidiff `nunidiff'
        capture noisily break {
            ml model `lfspec' `phi' `psi' `theta' if `touse' `wgt', ///
                `initopt' `mlopts' `log' search(off) collinear ///
                constraints(`constraints') maximize missing
        }
        global UDIFF_mtype
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

