{smcl}
{* *! version 1.0 20 Nov 2022}{...}
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
{bf:wreckitreg} {hline 2} Scale a variable that is transformed according to log(+1) or ihs() to obtain any regression coefficient

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:wreckitreg}
[{help depvar}]
{help indepvars}
[{help if}]
[{help in}],
{bf:coefvar(varname)}
{bf:value()}
[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:}
{synopt:{opt coefvar(varname)}} independentn variable whose coefficient is to be achieved; can be omitted if there is only one independent variable,which will be used as {bf:coefvar}

{synopt:{opt value}} desired value of the coefficient on {cmd:coefvar}

{synopt:{opt xvar}} transform {bf:coefvar}, an independent variable; default is to transform the dependent variable

{synopt:{opt ihs}} use inverse hyperbolic sine function; default is to use log(+1) transformation

{synopt:{opt nocons:tant}} suppress constant term



{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:wreckitreg} solves for a scale factor on either the dependent variable or one of the independent variables ({cmd:coefvar()}) such that the coefficient value of a specified independent variable {cmd:coefvar()} is a certain value in a log(+1) or ihs() transformation.
 The command reports the scale factor needed to scale {bf:depvar} or {bf:coefvar} by to yield a coefficient on {bf:coefvar()} of {bf:value()}.
 The scaling factor is limited by machine precision, therefore a reasonable achievable range is also outputted.
The scaling factor is restricted to be positive.

{marker options}{...}
{title:Options}
{dlgtab:Main}

{phang}
{opt coefvar(varname)} independent variable whose coefficient is to be achieved. If there is only one independent variable listed, then {bf:coefvar} can be omitted and will take the value of the independent variable. {bf:coefvar} is required if more than one independent variable is specified in {help indepvars}.

{phang}
{opt value} desired coefficient value of {cmd:coefvar}

{phang}
{opt ihs} use inverse hyperbolic sine function; default is to use log(+1) transformation

{phang}
{opt nocons:tant} suppresses the constant term (intercept) in the model

{phang}
{opt xvar} transform {bf:coefvar}; default is to transform the dependent variable

{marker examples}{...}
{title:Examples}

{stata sysuse nlsw88, clear}
{stata wreckitreg wage tenure grade, coefvar(tenure) value(.01)}
{stata wreckitreg wage tenure grade, coefvar(tenure) value(10000) xvar ihs}

{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(scale)}} the necessary scale factor to achieve the desired coefficient value {p_end}
{synopt:{cmd:e(obtained_value)}} the actual achievable coefficient value (subject to machine precision) {p_end}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:e(e_range)}} the powers of 10 for possible scaling factors (between -10 and 50) {p_end}
{synopt:{cmd:e(b_range)}} the corresponding coefficients on {bf:coefvar} {p_end}


{title:Authors}
{p}

Neil Thakral, Brown University.
Email {browse "mailto:neil_thakral@brown.edu":neil_thakral@brown.edu}

Linh Tô, Boston University.
Email {browse "mailto:linhto@bu.edu":linhto@bu.edu}
