{smcl}
{* *! version 1.1.0  19aug2019  Ben Jann & Simon Seiler}{...}
{vieweralsosee "[R] mlogit" "help mlogit"}{...}
{viewerjumpto "Syntax" "udiff##syntax"}{...}
{viewerjumpto "Description" "udiff##description"}{...}
{viewerjumpto "Options" "udiff##options"}{...}
{viewerjumpto "Postestimation" "udiff##postest"}{...}
{viewerjumpto "Examples" "udiff##examples"}{...}
{viewerjumpto "Methods and formulas" "udiff##methods"}{...}
{viewerjumpto "Saved results" "udiff##saved_results"}{...}
{viewerjumpto "References" "udiff##references"}{...}
{viewerjumpto "Authors" "udiff##authors"}{...}
{hi:help udiff}
{hline}

{title:Title}

{pstd}{hi:udiff} {hline 2}  Command to estimate an unidiff model from individual-level data


{marker syntax}{...}
{title:Syntax}

{pstd}
    Single-layer syntax

{p 8 15 2}
    {cmd:udiff} {depvar} {help varlist:{it:xvars}} {ifin} {weight}{cmd:,} {opth layer(varlist)}
    [ {it:options} ]

{pstd}
    Multiple-layer syntax

{p 8 15 2}
    {cmd:udiff} {depvar}
    {cmd:(}{help varlist:{it:xvars1}}{cmd:)} 
    {cmd:(}{help varlist:{it:xvars2}}{cmd:)} [ ... ] 
    {ifin} {weight}{cmd:,}
    {cmd:layer(}{help varlist:{it:varlist1}}{cmd:)}
    {cmd:layer(}{help varlist:{it:varlist2}}{cmd:)}
    [ ...  {it:options} ]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opth layer(varlist)}}layer variable(s); this option is required{p_end}
{synopt :{opth cont:rols(varlist)}}constant-effect control variables{p_end}
{synopt :{opt b:aseoutcome(#)}}value of {depvar} that will be the base outcome{p_end}
{synopt :{opt nocons:tant}}suppress constant term{p_end}
{synopt :{opth constr:aints(numlist)}}apply specified linear constraints{p_end}

{syntab :SE/Robust}
{synopt :{opth vce(vcetype)}}{it:vcetype} may be {opt oim},
   {opt r:obust}, {opt cl:uster} {it:clustvar}, {opt boot:strap}, or
   {opt jack:knife}{p_end}
{synopt :{opt r:obust}}synonym for {cmd:vce(robust)}{p_end}
{synopt :{opt cl:uster(clustvar)}}synonym for {cmd:vce(cluster} {it:clustvar}{cmd:)}{p_end}
{synopt :{opt svy}}take account of survey design as set by {helpb svyset}{p_end}
{synopt :{opth sub:pop(varname)}}compute estimates for a subpopulation; requires {cmd:svy}{p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt all:equations}}report results for all equations; by default only the unidiff parameters are displayed{p_end}
{synopt :{opt eform}}report coefficients in exponentiated form{p_end}
{synopt :{opt noh:eader}}suppress header display above coefficient table{p_end}
{synopt :{it:{help estimation_options##display_options:display_options}}}standard display options{p_end}
{synopt :{opt coefl:egend}}display legend instead of statistics{p_end}
{synopt :{opt noi:sily}}display output from initial constant-mobility model{p_end}

{syntab :Maximization}
{synopt :{it:{help maximize:maximize_options}}}maximization options{p_end}
{synopt :{opt initopt:s(options)}}options to be passed through to initial {helpb mlogit}{p_end}
{synoptline}
{p 4 6 2}{it:xvars}, {cmd:layer()}, and {cmd:controls()} may contain factor variables; see {help fvvarlist}.{p_end}
{p 4 6 2}{cmd:fweight}s, {cmd:aweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see help {help weight}.{p_end}
{p 4 6 2}{helpb udiff##postest:predict} and other postestimation commands are available after {cmd:udiff}; see {help udiff##postest:below}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
    {cmd:udiff} estimates parameters of the so-called unidiff model (Erikson
    and Goldthorpe 1992), also known as the log multiplicative layer effects
    model (Xie 1992), which is often used to study differences in
    intergenerational class mobility between birth cohorts or countries.

{pstd}
    The original unidiff model has been expressed as a log-linear model of cell
    frequencies in a three-way contingency table (origin by destination by
    cohort or country). The model, however, can also be expressed at the individual-level
    as a type of a multinomial logit regression. {cmd:udiff} estimates such a
    re-expressed unidiff model for individual-level data. For details see
    {help udiff##methods:Methods and Formulas} below. For an implementation
    of the log-linear unidiff model for aggregate data see Pisati (2000).

{pstd}
    {it:depvar} is the (categorical) destination variable (e.g. class of
    respondent); {it:xvars} specifies the origin variable(s) (e.g. class of
    respondent's parents). Typically, {it:xvars} only contains a single
    categorical variable specified as {cmd:i.}{it:varname}, although multiple
    or continuous origin variables are allowed.


{marker options}{...}
{title:Options}

{phang}
    {opt layer(varlist)} specifies one or more layer variables. {it:varlist}
    may contain factor variables; see {help fvvarlist}. Typically,
    {cmd:layer()} only contains a single categorical variable specified as
    {cmd:i.}{it:varname} (e.g. countries or birth-cohort categories). However,
    multiple variables or continuous variables are allowed. For example,
    specify {cmd:layer(c.cohort##c.cohort)} to model the unidiff scaling factor
    as a quadratic function of variable {cmd:cohort}.

{phang}
    {opt controls(varlist)} specifies control variables whose effects are
    assumed to be constant across layers. {it:varlist} may contain factor
    variables; see {help fvvarlist}.

{phang}
    {opt baseoutcome(#)} specifies the value of {depvar} to be treated as the base
    outcome. The default is to choose the most frequent outcome.

{phang}
    {opt noconstant} suppresses the constant (outcome-specific intercepts)
    in the model.

{phang}
    {opth constraints(numlist)} applies linear constraints to 
    the estimation. {it:numlist} specifies the constraints by number, after 
    they have been defined using the {helpb constraint} command. An  
    {help udiff##exconstr:example} is provided below.

{phang}
    {opt vce(vcetype)} specifies the type of variance estimation to be used
    to determine the standard errors. {it:vcetype} may be {opt oim},
   {opt r:obust}, {opt cl:uster} {it:clustvar}, {opt boot:strap}, or
   {opt jack:knife}; see {help vce_option:[R] {it:vce_option}}.

{phang}
    {opt robust} is a synonym for {cmd:vce(robust)}.

{phang}
    {opt cluster(clustvar)} is a synonym for {cmd:vce(cluster} {it:clustvar}{cmd:)}.

{phang}
    {opt svy} indicates that survey-design settings set by {helpb svyset} should
    be taken into account. {cmd:svy} may not be specified with {cmd:vce()} or weights.

{phang}
    {opth subpop(varname)} specifies that estimates be computed for the subpopulation defined
    by {it:varname}!=0. Typically, {it:varname} = 1 defines the subpopulation, and {it:varname} = 0
    indicates observations not belonging to the subpopulation. This option
    requires the {cmd:svy} option.

{phang}
    {opt level(#)} specifies the confidence level, as a percentage, for
    confidence intervals. The default is {cmd:level(95)}
    or as set by {helpb set level}.

{phang}
    {opt allequations} reports results for all equations of the model. By default,
    only the first equation containing the unidiff parameters is displayed.

{phang}
    {opt eform} displays the coefficients in exponentiated form. That is, for each coefficient,
    exp({it:b}) rather than {it:b} is displayed, and standard errors and
    confidence intervals are transformed accordingly.

{phang}
    {opt noheader} suppresses the header above the coefficient table 
    that displays the final log-likelihood value, the number of observations, 
    and the unidiff significance test.

{phang}
    {it:display_options} are standard display options; see
    {helpb estimation_options##display_options:[R] estimation options}.

{phang}
    {opt coeflegend} specifies that the legend of the coefficients and how
    to specify them in an expression be displayed rather than displaying the
    statistics for the coefficients.

{phang}
    {opt noisily} displays the {helpb mlogit} output of the initial
    constant-mobility model. By default, the initial model is not displayed.

{phang}
    {it:maximize_options} are maximization options such as {cmd:iterate()} or 
    {cmd:difficult}. See {helpb maximize:[R] maximize}. These options will only 
    be applied to the unidiff model, but not to the initial constant-mobility model.

{marker initopts}{...}
{phang}
    {opt initopts(options)} specifies options to be passed through to the 
    {helpb mlogit} call that is used to estimate the initial 
    constant-mobility model; see {helpb mlogit:[R] mlogit}.


{marker postest}{...}
{title:Postestimation commands}

{pstd}
    Usual postestimation commands such as {helpb predict}, {helpb test}, 
    {helpb lincom}, {helpb nlcom}, {helpb margins}, or {helpb suest} are available
    after {cmd:udiff}. The syntax for {helpb predict} is as follows:

{p 8 15 2}
    {cmd:predict} [{it:{help datatypes:type}}] {newvar} {ifin} [{cmd:,} {opt xb} {opt e:quation(equation)} ]

{p 8 15 2}
    {cmd:predict} [{it:{help datatypes:type}}] {newvar} {ifin}{cmd:,} {opt p:r} [ {opt o:utcome(outcome)} ]

{p 8 15 2}
    {cmd:predict} [{it:{help datatypes:type}}] {c -(}{it:stub}{cmd:*} | {help newvarlist:{it:newvarlist}}{c )-}  {ifin}{cmd:,}
    {opt sc:ores} [ {opt e:quation(equation)} ]

{pstd}
    Options:

{phang2}
    {opt xb} calculates linear predictions for the equation specified by
    {cmd:equation()}. {cmd:xb} is the default unless {cmd:pr} or {cmd:scores}
    is specified. If {opt equation()} is omitted, linear predictions are calculated
    for the first equation.

{phang2}
    {opt equation(equation)} specifies the equation for which linear
    predictions are to be calculated. {it:equation} can be an equation name, or
    an equation index specified as {cmd:#1}, {cmd:#2}, etc. Option
    {opt equation()} is not allowed with {cmd:pr}.

{phang2}
    {opt pr} calculates predicted probabilities for the outcome specified by
    {cmd:outcome()}. If {opt outcome()} is omitted, predicted probabilities are
    calculated for the first outcome.

{phang2}
    {opt outcome(outcome)} specifies the outcome for which predicted
    probabilities are to be calculated. {it:outcome} can be an
    outcome value, or an outcome index specified as {cmd:#1}, {cmd:#2}, etc. Option
    {opt outcome()} is only allowed with {cmd:pr}.

{phang2}
    {opt scores} calculates equation-level score variables (first derivative
    of the log likelihood). If {opt equation()} is omitted, score variables
    are generated for all equations (one variable per equation; if {it:k} is
    the number of outcomes, then the number of equations is equal to ({it:k}-1)*2+1).


{marker examples}{...}
{title:Examples}

{dlgtab:Basic example}

{pstd}
    The unidiff model in Example 2 in Pisati (2000) can be reproduced as follows:

        . {stata "use http://www.stata.com/stb/stb55/sg142/example2.dta, clear"}
        . {stata udiff son i.father [fweight=obs], layer(i.country)}

{pstd}
    A likelihood-ratio test against the constant-mobility model is included in the
    header of the output table. The test is highly significant and confirms that
    there are differences in the unidiff parameters between the countries.

{pstd}
    By default, {cmd:udiff} omits the base category from the output
    (Australia in this example) and displays the unidiff parameters in logarithmic form. To
    include the base category in the output, specify {cmd:baselevels}; to
    report unidiff parameters as multipliers, add the {cmd:eform} option:

        . {stata udiff, eform baselevels}

{pstd}
    Furthermore, by default only the unidiff scaling parameters are reported. To
    report all parameters of the model, specify option {cmd:all}:

        . {stata udiff, all}

{marker exconstr}{...}
{dlgtab:Specifying constraints}

{pstd}
    In case of empty cells or similar problems, it may be necessary to specify 
    constraints for the model to converge. Using the same data as above, assume 
    that the combinations of father = "NonManual" and son = "Farm" is missing:

        . {stata "use http://www.stata.com/stb/stb55/sg142/example2.dta, clear"}
        . {stata replace obs = 0 if son==3 & father==1}

{pstd}
    To make {cmd:udiff} converge in this example, we can set the parameter
    for "NonManual" in the psi-equation for "Farm" to zero (while at the same time
    making sure that "NonManual" is not used as the base category). The following
    commands would do:

        . {stata "constraint 1 [Psi_3]: 1.father"}
        . {stata udiff son ib2.father [fweight=obs], layer(i.country) constraints(1)}


{marker methods}{...}
{title:Methods and formulas}

{dlgtab:The unidiff model}

{pstd}
    The unidiff model is typically used to study differences in
    intergenerational social mobility between birth cohorts or countries. Let
    {it:mu}(x,y,z) be the cell frequencies in a three-way table of X (origin
    class, e.g. class of parents) by Y (destination class, e.g. class of
    children) by Z (e.g. cohort). Lowercase x, y, and z denote the
    levels of X, Y, and Z. In a saturated log-linear model the cell
    frequencies are parametrized as

        ln {it:mu}(x,y,z) = {it:a} + {it:a}(x) + {it:a}(y) + {it:a}(z) + {it:a}(x,y) + {it:a}(x,z) + {it:a}(y,z) + {it:a}(x,y,z)

{pstd}
    where {it:a} is an overall intercept capturing the average cell frequency,
    {it:a}(x), {it:a}(y), and {it:a}(z) are factors capturing the marginal distributions
    of X, Y, and Z, {it:a}(x,y), {it:a}(x,z), and {it:a}(y,z)
    capture two-way associations, and {it:a}(x,y,z) captures the three-way
    association. For example, if X, Y, and Z are independent from each other,
    {it:a}(x,y), {it:a}(x,z), {it:a}(y,z), and {it:a}(x,y,z) will be zero for
    all x, y, and z. Likewise, if the association between X and Y is
    constant over cohorts, {it:a}(x,y,z) will be zero for all x, y, and z,
    such that

        ln {it:mu}(x,y,z) = {it:a} + {it:a}(x) + {it:a}(y) + {it:a}(z) + {it:a}(x,y) + {it:a}(x,z) + {it:a}(y,z)

{pstd}
    This is the so-called constant-mobility model. The saturated
    model accurately describes the data, but has too many parameters
    to be informative; the constant-mobility model is too
    simplistic because it assumes away any change in mobility. The unidiff
    model takes a middle ground in that it allows the association between X and Y
    to vary with Z, but places a specific restriction on the form of this
    variation. In particular, the unidiff model introduces a scaling factor
    {it:b}(z) such that

        ln {it:mu}(x,y,z) = {it:a} + {it:a}(x) + {it:a}(y) + {it:a}(z) + {it:a}(x,z) + {it:a}(y,z) + {it:b}(z) * {it:a}(x,y)

{pstd}
    That is, the unidiff model assumes that there is a common association pattern
    between X and Y, but the "strength" of the pattern can differ across
    cohorts.

{dlgtab:Re-expression at the individual level}

{pstd}
    Traditionally, the unidiff model has been estimated from tabular data.
    However, the model (or, at least, the interesting part of it) can also be
    expressed such that it takes the form of a regression model fitted to
    individual-level data. From a perspective with Y as the "dependent"
    variable, the saturated log-linear model is equivalent to a multinomial
    logit of Y on X, Z, and the interaction between X and Z, where X and Z are
    treated as factor variables. Likewise, the constant-mobility model is a
    multinomial logit of Y on X and Z, without interaction between X and Z.
    Furthermore, the unidiff model is equivalent to a multinomial logit written
    as

        Pr(Y = y| X, Z) = exp(W'{it:theta}(y) + exp(Z'{it:phi}) * X'{it:psi}(y)) / Q

{pstd}
    where Q is the sum of the expression in the numerator across all levels of
    Y, and W is equal to Z augmented by a constant, i.e. W = (1,Z')' (again, X
    and Z are treated as factor variables, i.e. think of X and Z as vectors
    of dummy variables). {it:theta}(y), {it:phi},
    and {it:psi}(y) are parameter vectors; {it:phi} is common to all levels of
    Y, {it:theta}(y) and {it:psi}(y) are level-specific. In this model,
    {it:theta}(y) represents {it:a}(y) and {it:a}(y,z) (the marginal
    distribution of Y as well as the main effects of Z, i.e. how the marginal
    distribution of Y depends on Z), exp({it:phi}) represents {it:b}(z) (the
    unidiff scaling factors), and {it:psi}(y) represents {it:a}(x,y) (the
    association between X and Y). Terms {it:a}(x) (marginal distribution of X),
    {it:a}(z) (marginal distribution of Z), {it:a}(x,z) (association between X
    and Z) are not represented in the model (i.e., the model only contains
    parameters that are related to Y).

{dlgtab:Multiple-layer generalization}

{pstd}
    Generally seen, the unidiff model is just a multinomial logit model
    that contains a special kind of interaction terms. The model may thus be
    useful also for research questions that have nothing to do with social
    mobility. Furthermore, the model can be generalize so that it contains
    multiple layer dimensions. Let X1 and X2 be two sets of independent
    variables, Z1 and Z2 two sets of layer variables, and C a set of
    control variables that are not interacted with Z1 or Z2. The model can then be
    written as:

{p 8 8 2}Pr(Y = y| X1, Z1, X2, Z2, C) ={p_end}
{p 12 12 2}exp(W'{it:theta}(y) + exp(Z1'{it:phi1}) * X1'{it:psi1}(y) + exp(Z2'{it:phi2}) * X2'{it:psi2}(y)) / Q{p_end}

{pstd}
    where W = (1, Z1', X1', Z2', X2', C')'. The model can be extended analogously 
    to accommodate more than two layer dimensions.

{dlgtab:Estimation}

{pstd}
    {cmd:udiff} estimates the unidiff model using {helpb ml}. To obtain good
    starting values, {cmd:udiff} first fits a constant-mobility model using
    {helpb mlogit}. A test of the unidiff model against the constant-mobility
    model is included in the output (as an LR test or a Wald test, depending on
    context).

{pstd}
    As usual in a multinomial logit, the coefficients are set to zero for one
    of the levels of Y to identify the model. Furthermore, as is usual for factor variables,
    {it:phi} is set to zero for one of the levels of Z if Z is a categorical variable. exp({it:phi})
    then expresses the unidiff scaling factors with respect to this base category.

{pstd}
    Estimating the unidiff model from individual-level data is more demanding
    than fitting the model to a contingency table (although note that, for 
    efficient computation, {cmd:fweight}s can be used on collapsed data),
    but it brings about enhanced flexibility. For example, it is easily
    possible to include continuous (rather than categorical) origin and layer
    variables, control variables whose effects as assumed constant over cohorts
    can be taken into account (by including them in W), and standard errors for
    the parameter estimates are readily available (including support for
    sampling weights or other characteristics of a complex survey design).


{marker saved_results}{...}
{title:Saved results}

{pstd}
    {cmd:udiff} stores results as described in {helpb ml##results:[R] ml},
    as well as the following elements:

{p2colset 7 22 26 2}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{p2col : {cmd:e(k_out)}}number of outcomes
    {p_end}
{p2col : {cmd:e(ibaseout)}}index of the base outcome
    {p_end}
{p2col : {cmd:e(k_layer)}}number of layers
    {p_end}
{p2col : {cmd:e(k_eform)}}number of equations to be affected by the {cmd:eform} option
    {p_end}

{p2col 5 22 26 2: Macros}{p_end}
{p2col : {cmd:e(layer)}}names of layer variables (if case of a single layer)
    {p_end}
{p2col : {cmd:e(layer1)}}names of layer 1 variables (in case of multiple layers)
    {p_end}
{p2col : {cmd:e(layer2)}}names of layer 2 variables (in case of multiple layers)
    {p_end}
{p2col : ...}
    {p_end}
{p2col : {cmd:e(xvars)}}names of independent variables (if case of a single layer).
    {p_end}
{p2col : {cmd:e(xvars1)}}names of layer 1 independent variables  (in case of multiple layers)
    {p_end}
{p2col : {cmd:e(xvars2)}}names of layer 2 independent variables (in case of multiple layers)
    {p_end}
{p2col : ...}
    {p_end}
{p2col : {cmd:e(controls)}}names of control variables
    {p_end}
{p2col : {cmd:e(eqnames)}}names of equations
    {p_end}
{p2col : {cmd:e(out)}}values of {it:depvar}
    {p_end}
{p2col : {cmd:e(baseout)}}value of {it:depvar} treated as the base outcome
    {p_end}
{p2col : {cmd:e(out_labels)}}value labels of {it:depvar} (if available)
    {p_end}


{marker references}{...}
{title:References}

{phang}
    Erikson, R., J.J. Goldthorpe. 1992. The Constant Flux: A Study of Class
    Mobility in Industrial Societies. Oxford: Oxford University Press.
    {p_end}
{phang}
    Pisati, M. 2000. {stata "net describe sg142, from(http://www.stata.com/stb/stb55)":sg142}: Uniform
    layer effect models for the analysis of differences in two-way associations. Stata
    Technical Bulletin 55: 33-47.
    {p_end}
{phang}
    Xie, Y. 1992. The Log-Multiplicative Layer Effect Model for Comparing Mobility
    Tables. American Sociological Review 57(3): 380–395.
    {p_end}


{marker authors}{...}
{title:Authors}

{pstd}
    Ben Jann, University of Bern, ben.jann@soz.unibe.ch
    {p_end}
{pstd}
    Simon Seiler, University of Bern, simon.seiler@icer.unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B., S. Seiler. 2019. udiff: Stata module to estimate an unidiff model 
    from individual-level data. Available from
    {browse "http://github.com/benjann/udiff"}.

