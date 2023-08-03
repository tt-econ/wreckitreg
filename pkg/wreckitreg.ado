cap program drop run_reg
program define run_reg, rclass
    syntax, [ scale(real 1) xy(string) type(string) depvar(name) coefvar(name) cnames(string) coefficient ifinweight(string) regopts_reghdfe(string) ]

    quietly {

        if `scale' > 5.93*10^43 {
            local scale = 5.93*10^43
        }

        local count_indepvars: word count `cnames'
        if (`count_indepvars' == 1) & ("`coefvar'" == "") {
            local coefvar = "`cnames'"
        }

        * Transformed variables
        if ("`xy'" == "y") {
            tempvar y
            if ("`type'" == "log") {
                gen `y' = ln(`scale' * `depvar' + 1)
            }
            else {
                gen `y' = ln(`scale' * `depvar' + sqrt((`scale' * `depvar')^2 + 1))
            }
        }
        else {
            tempvar x
            if ("`type'" == "log") {
                gen `x' = ln(`scale' * `coefvar' + 1)
            }
            else {
                gen `x' = ln(`scale' * `coefvar' + sqrt((`scale' * `coefvar')^2 + 1))
            }
        }

        * Run the regression
        if strpos("`regopts_reghdfe'", "absorb") {
            local reg_command reghdfe
        }
        else {
            local reg_command reg
        }
        if ("`xy'" == "y") {
            `reg_command' `y' `coefvar' `cnames' `ifinweight', `regopts_reghdfe'
        }
        else {
            `reg_command' `depvar' `x' `cnames' `ifinweight', `regopts_reghdfe'
        }

        * Return the coefficient OR semi-elasticity depending on "coefficient option"
        if ("`xy'" == "y") {
            local xvar `coefvar'
        }
        else {
            local xvar `x'
        }

        * Return coefficient
        if "`coefficient'"!="" {
            return scalar b = _b[`xvar']
        }

        * Return semi-elasticity at the means
        else {
            margins
            scalar ybar = r(b)[1, 1]
            if ("`type'" == "log") {
                return scalar b = _b[`xvar'] * (ybar + 1) / (ybar)
            }

            else {
                return scalar b = _b[`xvar'] * sqrt(ybar^2 + 1) / ybar
            }
        }
    }
end


cap program drop wreckitreg
program define wreckitreg, eclass sortpreserve
    version 11

    syntax varlist(numeric ts fv) [if] [in] [aw fw iw pw], value(real) ///
        [ihs transform_x coefvar(varname numeric)] ///
        [coefficient] [regopts(string)] [absorb(string)]

    capture : which estout
    if (_rc) {
        display as result in smcl `"Please install package {it:estout} from SSC in order to run this command;"' _newline ///
            `"you can do so by clicking this link: {stata "ssc install estout":auto-install estout}"'
        exit 199
    }

    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'

    local ifinweight `if' `in' [`weight'`exp']
    if "`absorb'"!="" {
        local regopts_reghdfe "`regopts' absorb(`absorb')"
    }
    else {
        local regopts_reghdfe `regopts'
    }

    * Make coefvar optional if only 1 X variable specified (make it the coefvar)
    local count_indepvars: word count `indepvars'
    if (`count_indepvars' == 1) & ("`coefvar'" == "") {
        local coefvar = "`indepvars'"
    }
    if (`count_indepvars' > 1) & ("`coefvar'"=="") {
        display as err "option coefvar() required when there are more than one covariates listed"
        error 197
        exit
    }

    * Check if coefvar is one of the listed Xs
    * If not, warn that it is not listed and add it to the list of indepvars
    local intersection: list coefvar & indepvars
    if ("`intersection'" == "") {
        display as result "Warning: coefvar is not listed as an independent variable and is automatically added to the independent variable list"
        local indepvars `indepvars' `coefvar'
    }

    if ("`ihs'" == "") {
        local type "log"
    }
    else {
        local type "ihs"
    }
    if ("`transform_x'" == "") {
        local totransformed_var "`depvar'"
        local xy "y"
    }
    else {
        local totransformed_var "`coefvar'"
        local xy "x"
    }

    local exclude "`coefvar'"
    local indepvars: list indepvars - exclude

    fvexpand `indepvars'
    local cnames `r(varlist)'

    tempname min_b min_b_scale max_b max_b_scale e_range b_range scale obtained_value error_code error_text ___transformed_var

    mata: mata clear
    mata: wreckit(`value', "`xy'", "`type'", "`depvar'", "`coefvar'", "`cnames'", "`regopts_reghdfe'", ///
                    "`coefficient'", "`ifinweight'", "`min_b'", "`min_b_scale'", "`max_b'", "`max_b_scale'", "`e_range'", "`b_range'", ///
                    "`scale'", "`obtained_value'", "`error_code'", "`error_text'")

    local p = `scale'

    if ("`type'" == "log") {
        local disp_type = "ln(1 + " + string(`scale') + " * `totransformed_var')"
    }
    else {
        local disp_type = "ihs(" + string(`scale') + " * `totransformed_var')"
    }

    if ("`xy'" == "y") {
        local lab_y: variable label `depvar'
        label var `___transformed_var' "`lab_y'"
    }
    else {
        local lab_x: variable label `coefvar'
        label var `___transformed_var' "`lab_x'"
    }

    display _newline

    if "`coefficient'"=="" {
        display as text "Note: Results may not be obtainable outside the range between the two semi-elasticity values below due to machine precision:"
        display as result "Semi-Elasticity Value with a scale of " %16.9g `min_b_scale' ": " %16.9g `min_b'
        display as result "Semi-Elasticity Value with a scale of " %16.9g `max_b_scale' ": " %16.9g `max_b'
        display _newline
        display as result "Scaling `totransformed_var' by a factor of " `scale' " will yield a semi-elasticity with respect to `coefvar' (evaluated at the means of covariates) of " `obtained_value' " for variable transformation: `disp_type'. Resulting regression:"
    }
    else {
        display as text "Note: Results may not be obtainable outside the range between the two coefficient values below due to machine precision:"
        display as result "Coefficient Value with a scale of " %16.9g `min_b_scale' ": " %16.9g `min_b'
        display as result "Coefficient Value with a scale of " %16.9g `max_b_scale' ": " %16.9g `max_b'
        display _newline
        display as result "Scaling `totransformed_var' by a factor of " `scale' " will yield a coefficient on `coefvar' of " `obtained_value' " for variable transformation: `disp_type'. Resulting regression:"
    }

    eststo clear
    if "`absorb'"!="" {
        local reg_command reghdfe
        local absorb_option "absorb(`absorb')"
    }
    else {
        local reg_command reg
        local absorb_option ""
    }

    if ("`xy'" == "y") {
        local xvar `coefvar'
        quietly eststo: `reg_command' `___transformed_var' `xvar' `cnames' `if' `in' [`weight'`exp'], `regopts' `absorb_option'
    }
    else {
        local xvar `___transformed_var'
        quietly eststo: `reg_command' `depvar' `xvar' `cnames' `if' `in' [`weight'`exp'], `regopts' `absorb_option'
    }
    quietly margins
    scalar ybar = r(b)[1, 1]

    if ("`type'" == "log") {
        qui eststo: nlcom (`xvar': _b[`xvar']*(ybar+1) / ybar), post
    }
    else {
        qui eststo: nlcom (`xvar': _b[`xvar'] * sqrt(ybar^2 + 1) / ybar), post
    }

    * Display results table
    esttab, noobs label mtitle("Coefficient" "Semi-Elasticity") modelwidth(25) noabbrev varwidth(35) ///
        star(* 0.10 ** 0.05 *** 0.01)
    capture drop _est*

    * Display min and max values
    tempvar sign_y sign_0
    gen `sign_y' = sign(`depvar')
    gen `sign_0' = `sign_y'==0

    scalar l_0 = 0

    quietly {
        * Outcome variable l(cy)
            `reg_command' `___transformed_var' `xvar' `cnames' `if' `in' [`weight'`exp'], `regopts' `absorb_option'
            scalar b_c = _b[`xvar']

            if ("`type'" == "log") {
                scalar semi_c = b_c * (ybar+1) / ybar
            }
            else {
                scalar semi_c = b_c * sqrt(ybar^2 + 1) / ybar
            }

        * Outcome variable y
            `reg_command' `depvar' `xvar' `cnames' `if' `in' [`weight'`exp'], `regopts' `absorb_option'
            scalar b_u = _b[`xvar']
            margins
            scalar y_bar_u = r(b)[1, 1]
            scalar semi_u = b_u / y_bar_u

        * Outcome variable sgn(y)
            `reg_command' `sign_y' `xvar' `cnames' `if' `in' [`weight'`exp'], `regopts' `absorb_option'
            scalar b_s = _b[`xvar']

        * Outcome variable L(y)
            tempvar L_y
            gen `L_y' = l_0
            replace `L_y' = `sign_y' * log(abs(`depvar')) if `depvar' != 0

            `reg_command' `L_y' `xvar' `cnames' `if' `in' [`weight'`exp'], `regopts' `absorb_option'
            scalar b_L = _b[`xvar']
            scalar semi_L = b_L

        * Min and Max coefficient:
            local min_b_c = 0
            local max_b_c = b_L

        * Min and Max semi-elasticity:
            local min_semi_c = semi_u
            local max_semi_c = semi_L
    }

    display _newline
    display as text "Theoretical limit cases:"

    * Display min and max
    if "`coefficient'"=="" {
        display as result "As scale -> 0, semi-elasticity -> `min_semi_c'"
        if b_s==0 {
            display as result "As scale -> infty, semi-elasticity -> `max_semi_c'"
        }
        else {
            display as result "As scale -> infty, abs(semi-elasticity) -> infty"
        }
        display as text "Note that the semi-elasticity estimate may not change monotonically with the scale."
    }
    else {
        display as result "As scale -> 0, coefficient -> `min_b_c'"
        if b_s==0 {
            display as result "As scale -> infty, coefficient -> `max_b_c'"
        }
        else {
            display as result "As scale -> infty, abs(coefficient) -> infty"
        }
        display as text "Note that the coefficient estimate may not change monotonically with the scale."
    }

    ereturn matrix e_range = `e_range'
    ereturn matrix b_range = `b_range'
    ereturn scalar scale = `scale'
    ereturn scalar obtained_value = `obtained_value'
    ereturn scalar error_code = `error_code'
    ereturn local error_text = `error_text'
end

mata:

void wreckit(value, string scalar xy, string scalar type, ///
                    string scalar depvar, string scalar coefvar, string scalar cnames, ///
                    string scalar regopts_reghdfe, string scalar coefficient, string scalar ifinweight, ///
                    string scalar min_b_name, string scalar min_b_scale_name, ///
                    string scalar max_b_name, string scalar max_b_scale_name, ///
                    string scalar e_range_name, string scalar b_range_name, ///
                    string scalar p_name, string scalar obtained_value_name, ///
                    string scalar error_code_name, string scalar error_text_name)
{
    init_value = testscale(value, xy, type, depvar, coefvar, cnames, ///
                            regopts_reghdfe, coefficient, ifinweight, ///
                            min_b_name, min_b_scale_name, ///
                            max_b_name, max_b_scale_name, ///
                            e_range_name, b_range_name)

    S = optimize_init()
    optimize_init_which(S, "min")
    optimize_init_evaluator(S, &optimfun())
    optimize_init_conv_ptol(S, 1e-15)
    optimize_init_conv_vtol(S, 1e-15)
    optimize_init_conv_nrtol(S, 1e-15)
    optimize_init_technique(S, "nr dfp bfgs")
    optimize_init_params(S, init_value)
    optimize_init_argument(S, 1, value)
    optimize_init_argument(S, 2, xy)
    optimize_init_argument(S, 3, type)
    optimize_init_argument(S, 4, depvar)
    optimize_init_argument(S, 5, coefvar)
    optimize_init_argument(S, 6, cnames)
    optimize_init_argument(S, 7, regopts_reghdfe)
    optimize_init_argument(S, 8, coefficient)
    optimize_init_argument(S, 9, ifinweight)

    error_code = _optimize(S)
    error_code_stata = optimize_result_returncode(S)
    error_text = optimize_result_errortext(S)
    p = optimize_result_params(S)
    b = get_b(p, xy, type, depvar, coefvar, cnames, regopts_reghdfe, coefficient, ifinweight)

    if (xy == "y") {
        st_view(Y, ., depvar)
        if (type == "log") {
            transformed_var = ln(p * Y :+ 1)
        }
        else {
            transformed_var = ln(p * Y + sqrt((p * Y):^2 :+ 1))
        }
    }
    else {
        st_view(X, ., coefvar)
        if (type == "log") {
            transformed_var = ln(p * X :+ 1)
        }
        else {
            transformed_var = ln(p * X + sqrt((p * X):^2 :+ 1))
        }
    }

    (void) st_addvar("double", st_local("___transformed_var"))
    st_store(., st_local("___transformed_var"), transformed_var)
    st_numscalar(p_name, p)
    st_numscalar(obtained_value_name, b)
    st_numscalar(error_code_name, error_code_stata)
    st_strscalar(error_text_name, error_text)

}

function testscale(value, string scalar xy, string scalar type, ///
                    string scalar depvar, string scalar coefvar, string scalar indepvars, ///
                    string scalar regopts_reghdfe, string scalar coefficient, string scalar ifinweight, ///
                    string scalar min_b_name, string scalar min_b_scale_name, ///
                    string scalar max_b_name, string scalar max_b_scale_name, ///
                    string scalar e_range_name, string scalar b_range_name)
{
    init_value = 1
    distance = 1e100
    min_b = 1e100
    max_b = -1e100
    min_b_scale = 1
    max_b_scale = 1
    min_e = -10
    max_e = 50
    e_range = min_e..max_e
    b_range = e_range
    for (i = 1; i <= cols(e_range); i++) {
        scale = 10^e_range[i]
        b = get_b(scale, xy, type, depvar, coefvar, indepvars, regopts_reghdfe, coefficient, ifinweight)
        b_range[i] = b

        if (abs(i <= 5) & (abs(b - value) < distance)) {
            init_value = scale
            distance = abs(b - value)
        }
        if (b < min_b) {
            min_b = b
            min_b_scale = scale
        }
        if (b > max_b) {
            max_b = b
            max_b_scale = scale
        }
    }

    st_numscalar(min_b_name, min_b)
    st_numscalar(min_b_scale_name, min_b_scale)
    st_numscalar(max_b_name, max_b)
    st_numscalar(max_b_scale_name, max_b_scale)
    st_matrix(e_range_name, e_range)
    st_matrix(b_range_name, b_range)

    return(init_value)
}

real scalar get_b(scale, string scalar xy, string scalar type, string scalar depvar, string scalar coefvar, string scalar cnames, string scalar regopts_reghdfe, string scalar coefficient, string scalar ifinweight){
    real scalar b
    stata("run_reg, scale(" + strofreal(scale) + ") xy(" + xy + ") type(" + type + ") depvar(" + depvar + ") coefvar(" + coefvar + ") cnames(" + cnames + ") regopts_reghdfe(" + regopts_reghdfe + ") " + coefficient + " ifinweight(" + ifinweight + ") " )

    b = st_numscalar("r(b)")

    return(b)
}

void optimfun(todo, p, desired_value, string scalar xy, string scalar type, string scalar depvar, string scalar coefvar, string scalar cnames, string scalar regopts_reghdfe, string scalar coefficient, string scalar ifinweight, fml, g, H)
{
    if (p > 0) {
        b   = get_b(p, xy, type, depvar, coefvar, cnames, regopts_reghdfe, coefficient, ifinweight)
        fml = (b - desired_value)^2
    }
    else {
        fml = 1e10
    }
}

end
