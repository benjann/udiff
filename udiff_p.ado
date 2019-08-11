*! version 1.0.0  09aug2019  Ben Jann & Simon Seiler

program define udiff_p
    if "`e(cmd)'" != "udiff" {
        error 301
    }
    version 11
    ParseNewVars `0'
    local varspec `s(varspec)'
    local varlist `s(varlist)'
    local typlist `s(typlist)'
    local nvars : list sizeof varlist
    local if `"`s(if)'"'
    local in `"`s(in)'"'
    local options `"`s(options)'"'
    ParseOptions, `options'
    local outcome `"`s(outcome)'"'
    local hasout : length local outcome
    local equation `"`s(equation)'"'
    local haseq : length local equation
    local type `s(type)'
    if `:length local type'==0 {
        if `hasout' {
            local type pr
            di as txt "(option {bf:pr} assumed; predicted probability)"
        }
        else if `haseq' {
            local type xb
            di as txt "(option {bf:xb} assumed; linear predictor)"
        }
        else {
            local type xb
            local equation "#1"
            local haseq 1
            di as txt "(option {bf:xb} assumed; linear predictor)"
            di as txt "(option {bf:equation(#1)} assumed)"
        }
    }
    if "`type'"=="pr" {
        if `haseq' {
            di as err "option {bf:equation()} not allowed with {bf:pr}"
            exit 198
        }
        else if `hasout'==0 {
            local outcome "#1"
            local hasout 1
            di as txt "(option {bf:outcome(#1)} assumed)"
        }
    }
    else if "`type'"=="xb" {
        if `hasout' {
            di as err "option {bf:outcome()} not allowed with {bf:xb}"
            exit 198
        }
        else if `haseq'==0 {
            local equation "#1"
            local haseq 1
            di as txt "(option {bf:equation(#1)} assumed)"
        }
    }
    else if "`type'"=="scores" {
        if `hasout' {
            di as err "option {bf:outcome()} not allowed with {bf:scores}"
            exit 198
        }
    }
    if `nvars' > 1 {
        if !inlist("`type'","scores") {
            di as err "option `type' requires that you specify 1 new variable"
            error 103
        }
    }
    if `hasout' {
        OutNo `outcome'
        local outno `"`s(outno)'"'
        local outlab `"`s(outlab)'"'
    }
    else if `haseq' {
        EqNo `equation'
        local eqoptno  `"equation(#`s(eqno)')"'
        local eqlab `"`s(eqlab)'"'
        local eqoptnm `"equation(`"`eqlab'"')"'
    }
    
    // xb
    if `"`type'"' == "xb" {
        _predict `typlist' `varlist' `if' `in', xb `eqoptno'
        label var `varlist' `"Linear prediction from [`eqlab']"'
        sreturn clear
        exit
    }
    
    // scores
    if `"`type'"' == "scores" {
        local nout = e(k_out)
        local ibase = e(ibaseout)
        forval i = 1/`nout' {
            local val = el(e(out), 1,`i')
            local olist `olist' `val'
        }
        local vlist
        foreach var of local varlist {
            gettoken vtyp typlist : typlist
            local vlist `vlist' `vtyp' `var'
        }
        nobreak {
            global UDIFF_nout  `nout'
            global UDIFF_ibase `ibase'
            global UDIFF_olist `olist'
            capture noisily break {
                ml score `vlist' `if' `in', `eqoptnm'
            }
            global UDIFF_nout
            global UDIFF_ibase
            global UDIFF_olist
            if _rc exit _rc
            sreturn clear
            exit
        }
    }
    
    // probability
    tempvar touse den xb phi psi theta
    mark `touse' `if' `in'
    quietly {
        _predict double `phi' if `touse', eq(#1) xb
        replace `phi' = exp(`phi') if `touse'
        gen double `den' = 1 if `touse'
        local kout = e(k_out)
        local j 0
        forval i = 1/`kout' {
            if `i' == e(ibaseout) continue
            local ++j
            local eqno = 1 + `j'
            _predict double `psi' if `touse', eq(#`eqno') xb
            local eqno = 1 + (`nout'-1) + `j'
            _predict double `theta' if `touse', eq(#`eqno') xb
            gen double `xb' = `theta' + `phi'*`psi' if `touse'
            drop `theta' `psi'
            // note from mlogit_p.ado:
            // If `den'<0, then `den'==+inf.
            // If `den'==-1, then there is just one +inf: p=0 if
            // exp(`xbsel')<., and p=1 if exp(`xbsel')>=.
            // (i.e., requested category gave the +inf).
            // If `den' < -1, then there are two or more +inf: p=0
            // if exp(`xbsel')<.; and p=. if exp(`xbsel')>=.
            // (since we cannot say what its value should be).
            replace `den' = cond(`xb'<. & exp(`xb')>=., ///
                cond(`den'<0,`den'-1,-1), `den'+exp(`xb')) if `touse'
            if `i'==`outno' {
                tempvar xbsel
                rename `xb' `xbsel'
            }
            else drop `xb'
        }
    }
    if `outno' == e(ibaseout) {
        gen `typlist' `varlist' = cond(`den'>0,1/`den',0) if `touse'
    }
    else {
        gen `typlist' `varlist' = cond(`den'>0,exp(`xbsel')/`den', /*
            */ cond(exp(`xbsel')<.,0,cond(`den'==-1,1,.))) if `touse'
    }
    label var `varlist' `"Pr(`e(depvar)'==`outlab')"'
    sreturn clear
end

program ParseNewVars, sclass
    syntax [anything(name=vlist)] [if] [in] [, *]
    local myif `"`if'"'
    local myin `"`in'"'
    local myopts `"`options'"'

    if `"`vlist'"' == "" {
        di as err "varlist required"
        exit 100
    }
    local varspec `"`vlist'"'
    local neq = e(k_eq)
    local stub 0
    if index("`vlist'","*") {
        _stubstar2names `vlist', nvars(`neq')
        local varlist `s(varlist)'
        local typlist `s(typlist)'
        confirm new var `varlist'
    }
    else {
        syntax newvarlist [if] [in] [, * ]
    }
    sreturn clear
    sreturn local varspec `varspec'
    sreturn local varlist `varlist'
    sreturn local typlist `typlist'
    sreturn local if `"`myif'"'
    sreturn local in `"`myin'"'
    sreturn local options `"`myopts'"'
end

program ParseOptions, sclass
    syntax [,             ///
        Equation(string)  ///
        Outcome(string)   ///
        XB                ///
        Pr                ///
        SCores            ///
    ]

    // check options that take arguments
    local rc 0
    if `"`equation'"' != "" & `"`outcome'"' != "" {
        opts_exclusive "equation() outcome()"
    }

    // check switch options
    local type `xb' `pr' `scores'
    opts_exclusive "`type'"

    // save results
    sreturn clear
    sreturn local type    `type'
    sreturn local equation `"`equation'"'
    sreturn local outcome `"`outcome'"'
end

program define OutNo, sclass
    sreturn clear
    local outlab = trim(`"`0'"')
    local kout = e(k_out)
    local outlist `"`e(outnames)'"'
    if substr(`"`outlab'"',1,1)=="#" {
        local i = substr(`"`outlab'"',2,.)
        capt confirm integer number `i'
        if _rc==0 capt assert (`i'>0)
        if _rc {
            di as err `"invalid outcome(): `outlab'"'
            exit 198
        }
        if `i'<=`kout' {
            sreturn local outno "`i'"
            sreturn local outlab : word `i' of `outlist'
            exit
        }
    }
    else {
        capture confirm number `outlab'
        if _rc == 0 {
            forv i = 1/`kout' {
                if (reldif(el(e(out),1,`i'),`outlab') < 1e-7) {
                    sreturn local outno "`i'"
                    sreturn local outlab : word `i' of `outlist'
                    exit
                }
            }
        }
        else {
            if `:list outlab in outlist' {
                local i : list posof `"`outlab'"' in outlist
                sreturn local outno "`i'"
                sreturn local outlab `"`outlab'"'
                exit
            }
        }
    }
    di as error `"outcome `outlab' not found"'
    exit 303
end

program define EqNo, sclass
    sreturn clear
    local eqlab = trim(`"`0'"')
    local keq = e(k_eq)
    local eqlist `"`e(eqnames)'"'
    if bsubstr(`"`eqlab'"',1,1)=="#" {
        local i = substr(`"`eqlab'"',2,.)
        capt confirm integer number `i'
        if _rc==0 capt assert (`i'>0)
        if _rc {
            di as err `"invalid equation(): `eqlab'"'
            exit 198
        }
        if `i'<=`keq' {
            sreturn local eqno "`i'"
            sreturn local eqlab : word `i' of `eqlist'
            exit
        }
    }
    else if `:list eqlab in eqlist' {
        local i : list posof `"`eqlab'"' in eqlist
        sreturn local eqno "`i'"
        sreturn local eqlab `"`eqlab'"'
        exit
    }
    di as error `"equation `eqlab' not found"'
    exit 303
end




