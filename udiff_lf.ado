*! version 1.1.0  19aug2019  Ben Jann & Simon Seiler

program udiff_lf
    version 11
    
    // collect information
    local nout    $UDIFF_nout
    local olist   $UDIFF_out
    local ibase   $UDIFF_ibase
    local nlayer  $UDIFF_nlayer
    forv j = 1/`nlayer' {
        local philist `philist' phi`j'
        forv i = 1/`nout' {
            if `i'==`ibase' continue
            local psilist `psilist' psi`j'_`i'
        }
    }
    forv i = 1/`nout' {
        if `i'==`ibase' continue
        local thetalist `thetalist' theta`i'
    }
    args lnf `philist' `psilist' `thetalist'
    
    // fill-in likelihood
    tempvar tmp
    qui gen double `tmp' = .
    qui replace `lnf' = 1 if $ML_samp
    forv i = 1/`nout' {
        if `i'==`ibase' continue
        qui replace `tmp' = `psi1_`i'' * exp(`phi1') if $ML_samp
        forv j=2/`nlayer' {
            qui replace `tmp' = `tmp' + `psi`j'_`i'' * exp(`phi`j'') if $ML_samp
        }
        qui replace `lnf' = `lnf' + exp(`theta`i'' + `tmp') if $ML_samp
    }
    forv i = 1/`nout' {
        gettoken out olist : olist
        if `i'==`ibase' {
            qui replace `lnf' = -ln(`lnf') if $ML_samp & $ML_y1==`out'
            continue
        }
        qui replace `tmp' = `psi1_`i'' * exp(`phi1') if $ML_samp & $ML_y1==`out'
        forv j=2/`nlayer' {
            qui replace `tmp' = `tmp' + `psi`j'_`i'' * exp(`phi`j'') if $ML_samp & $ML_y1==`out'
        }
        qui replace `lnf' = `theta`i'' + `tmp' - ln(`lnf') if $ML_samp & $ML_y1==`out'
    }
end
