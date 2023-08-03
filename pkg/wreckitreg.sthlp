{smcl}
{* *! version 2.0 2 Aug 2023}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "wreckitreg##syntax"}{...}
{viewerjumpto "Description" "wreckitreg##description"}{...}
{viewerjumpto "Options" "wreckitreg##options"}{...}
{viewerjumpto "Remarks" "wreckitreg##remarks"}{...}
{viewerjumpto "Examples" "wreckitreg##examples"}{...}
{title:Title}
{phang}
{bf:wreckitreg} {hline 2} Scale a variable that is transformed according to log(+1) or ihs() to obtain arbitrary regression coefficient or semi-elasticity estimates

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:wreckitreg}
{help depvar}
[{help indepvars}]
[{help if}]
[{help in}]
[{help weight}],
{bf:value()}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:}
{synopt:{opt value}} desired value of the coefficient or semi-elasticity on {bf:coefvar}

{synopt:{opt coefvar(varname)}} independent variable whose coefficient or semi-elasticity is to be achieved; can be omitted if there is only one independent variable, which will be used as {bf:coefvar}

{synopt:{opt coefficient}} when specified, the command finds a scaling of the data to achieve the specified value for the coefficient on {cmd:coefvar}, otherwise for the semi-elasticity with respect to {bf:coefvar} evaluated at the means of the covariates

{synopt:{opt transform_x}} transform {bf:coefvar}, an independent variable; default is to transform the dependent variable

{synopt:{opt ihs}} use inverse hyperbolic sine function; default is to use log(+1) transformation

{synopt:{opt regopts}} options to pass to {bf:regress} or {bf:reghdfe}

{synopt:{opt absorb}} use {bf:reghdfe} with option {bf:absorb} to run the regression


{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:wreckitreg} solves for a scale factor on either the dependent variable or one of the independent variables ({cmd:coefvar()}) such that the coefficient value of a specified independent variable {cmd:coefvar()} or the semi-elasticity estimate with respect to {cmd:coefvar()} evaluated at the means of covariates is a certain value in a regression with log(+1) or ihs() transformation.
 By default, the value is obtained for the semi-elasticity estimate unless {bf:coefficient} is specified.
 The command reports the scale factor needed to scale {bf:depvar} or {bf:coefvar} by to yield a coefficient or semi-elasticity estimate on {bf:coefvar()} of {bf:value()}.
 The scaling factor is limited by machine precision, therefore a reasonable achievable range is also outputted.
 The scaling factor is restricted to be positive.
 The theoretical limits of the coefficient and semi-elasticity estimates when the scaling factor approaches 0 or infinity are computed.
 The coefficient and semi-elasticity estimates may not change monotonically with the scale, so values outside the theoretical limits can still be achieved.

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt coefvar(varname)} independent variable whose coefficient or semi-elasticity is to be achieved. If there is only one independent variable listed, then {bf:coefvar} can be omitted and will take the value of the independent variable. {bf:coefvar} is required if more than one independent variable is specified in {help indepvars}.

{phang}
{opt value} desired coefficient or semi-elasticity value of {cmd:coefvar}

{phang}
{opt coefficient} obtain coefficient {bf:value} instead of semi-elasticity {bf:value} (evaluated at the means of covariates) for {bf:coefvar}

{phang}
{opt ihs} use inverse hyperbolic sine function for transformation; default is to use log(+1) transformation

{phang}
{opt transform_x} transform {bf:coefvar}; default is to transform the dependent variable

{marker examples}{...}
{title:Examples}

{stata sysuse nlsw88, clear}
{stata replace wage = 0 if wage < 2}
{stata wreckitreg wage tenure grade, coefvar(tenure) value(.03) absorb(age)}
{stata wreckitreg wage tenure if age > 30, value(1) ihs transform_x coefficient}

{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(scale)}} the necessary scale factor to achieve the desired coefficient value {p_end}
{synopt:{cmd:e(obtained_value)}} the actual achievable coefficient value (subject to machine precision) {p_end}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(e_range)}} the powers of 10 for possible scaling factors (between -10 and 50) {p_end}
{synopt:{cmd:e(b_range)}} the corresponding coefficients or semi-elasticity estimates on {bf:coefvar} {p_end}


{title:Authors}
{p}

Neil Thakral, Brown University.
Email {browse "mailto:neil_thakral@brown.edu":neil_thakral@brown.edu}

Linh Tô, Boston University.
Email {browse "mailto:linhto@bu.edu":linhto@bu.edu}

Michael Briskin contributed to this package.
