*! version 1.0.0  09aug2019  Ben Jann & Simon Seiler

program udiff_lf
    version 11
    
    // collect information
    local nout  $UDIFF_nout
    local ibase $UDIFF_ibase
    local olist $UDIFF_olist
    forv i = 1/`nout' {
        if `i'==`ibase' continue
        local psilist `psilist' psi`i'
        local thetalist `thetalist' theta`i'
    }
    args lnf phi `psilist' `thetalist'
    
    // fill-in likelihood 
    qui replace `lnf' = 1 if $ML_samp
    forv i = 1/`nout' {
        if `i'==`ibase' continue
        qui replace `lnf' = `lnf' + exp(`theta`i'' + `psi`i'' * exp(`phi')) ///
            if $ML_samp
    }
    forv i = 1/`nout' {
        gettoken out olist : olist
        if `i'==`ibase' {
            qui replace `lnf' = -ln(`lnf') if $ML_samp & $ML_y1==`out'
            continue
        }
        qui replace `lnf' = `theta`i'' + `psi`i'' * exp(`phi') - ln(`lnf') ///
            if $ML_samp & $ML_y1==`out'
    }
end
