# udiff
Stata module to estimate the generalized unidiff model for individual-level data

`udiff` estimates parameters of the so-called unidiff model (Erikson
and Goldthorpe 1992: The Constant Flux. Oxford University Press), also known as
the log-multiplicative layer effect model (Xie 1992: The Log-Multiplicative
Layer Effect Model for Comparing Mobility Tables. American Sociological Review
57: 380–395), which is often used to study differences in intergenerational
class mobility between birth cohorts or countries. The original unidiff model
has been expressed as a log-linear model of cell frequencies in a three-way
contingency table (origin by destination by cohort or country). The model,
however, can also be expressed at the individual-level (similar to a
multinomial logit model). `udiff` estimates such a re-expressed unidiff model for
individual-level data. Furthermore, it generalizes the model to allow for
multiple layers and non-categorical predictors. For an implementation of the
classic log-linear unidiff model for aggregate data see Pisati (2000: sg142:
Uniform layer effect models for the analysis of differences in two-way
associations. Stata Technical Bulletin 55: 33-47).

To install the `udiff` package from the SSC Archive, type

    . ssc install udiff, replace

in Stata. Stata version 11 or newer is required.

---

Installation from GitHub:

    . net install udiff, replace from(https://raw.githubusercontent.com/benjann/udiff/master/)

---

Main changes:

    10apr2020
    - improved parsing such that "(x y)##z" is no longer mistaken as an 
      unidiff term

    03apr2020
    - estat kappa added
    - estat lambda added
    - mata optimizer used the wrong outcome as base outcome if the outcome 
      variable did not use consecutive numbers starting at 1 as values for the
      outcomes; this is fixed

    02apr2020
    - new implementatuon of -estat rescale-; no longer uses nlcom
    - udiff_estat now has replay functionality (common display routine)

    16nov2019
    - new -estat rescale- command
    - more verbose output
    - now storing unexpanded varlists in e()

    13nov2019
    - the mata likelihood evaluator had an error that could make estimation fail
      for models with multiple unidiff terms
    - fixed some minor issues in syntax parsing

    09nov2019
    - new syntax
    - new -cfonly- option

    06nov2019
    - now using option -continue- instead of copying of e(b) from initial model
    - now using a mata-based lf2 evaluator to estimates the model; use undocumented 
      option -lfado- to call an ado-based lf0 evaluator
    - now using a custom evaluator to estimate the constant fluidity model; this is
      a bit slower than mlogit, but it avoids complications due to different
      naming of the coefficients

    21aug2019
    - multiple layer() options may now contain same variables
    - added check for repeated variables in xvars and controls
