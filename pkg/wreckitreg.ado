program define wreckitreg, eclass sortpreserve
    version 8

    syntax varlist(numeric ts fv) [if] [in] [, noCONStant ihs xvar coefvar(varname numeric)]  value(real)
    marksample touse

    gettoken depvar indepvars : varlist
    _fv_check_depvar `depvar'

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
    if ("`xvar'" == "") {
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

    capture drop ___transformed_var

    tempname min_b min_b_scale max_b max_b_scale e_range b_range scale obtained_value error_code error_text

    mata: mata clear
    mata: wreckit(`value', "`xy'", "`type'", "`depvar'", "`coefvar'", "`cnames'", "`touse'", "`constant'", ///
                  "`min_b'", "`min_b_scale'", "`max_b'", "`max_b_scale'", "`e_range'", "`b_range'", ///
                  "`scale'", "`obtained_value'", "`error_code'", "`error_text'")

    local p = `scale'

    if ("`type'" == "log") {
        local disp_type = "ln(1 + " + string(`scale') + " * `totransformed_var')"
    }
    else {
        local disp_type = "ihs(" + string(`scale') + " * `totransformed_var')"
    }

    if ("`type'" == "log") {
        label var ___transformed_var "log_`xy'plus1"
    }
    else {
        label var ___transformed_var "ihs_`xy'"
    }

    display _newline
    display "Coefficient Value with a scale of " %16.9g `min_b_scale' ": " %16.9g `min_b'
    display "Coefficient Value with a scale of " %16.9g `max_b_scale' ": " %16.9g `max_b'
    display "Note: Results may not be obtainable between the two coefficient values above due to machine precision"
    display _newline
    display as result "Scaling `totransformed_var' by a factor of " `scale' " will yield a coefficient on `coefvar' of " `obtained_value' " for variable transformation: `disp_type'. Resulting regression:"

    if ("`xy'" == "y") {
        reg ___transformed_var `coefvar' `cnames' if `touse', `constant'
    }
    else {
        reg `depvar' ___transformed_var `cnames' if `touse', `constant'
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
                   string scalar depvar, string scalar coefvar, string scalar indepvars, ///
                   string scalar touse, string scalar constant, ///
                   string scalar min_b_name, string scalar min_b_scale_name, ///
                   string scalar max_b_name, string scalar max_b_scale_name, ///
                   string scalar e_range_name, string scalar b_range_name, ///
                   string scalar p_name, string scalar obtained_value_name, string scalar error_code_name, string scalar error_text_name)
{
    init_value = testscale(value, xy, type, depvar, coefvar, indepvars, ///
                           touse, constant, ///
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
    optimize_init_argument(S, 6, indepvars)
    optimize_init_argument(S, 7, touse)
    optimize_init_argument(S, 8, constant)
    error_code = _optimize(S)
    error_code_stata = optimize_result_returncode(S)
    error_text = optimize_result_errortext(S)
    p = optimize_result_params(S)
    b = myreg(p, xy, type, depvar, coefvar, indepvars, touse, constant)

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
    (void) st_addvar("double", "___transformed_var")
    st_store(., "___transformed_var", transformed_var)
    st_numscalar(p_name, p)
    st_numscalar(obtained_value_name, b)
    st_numscalar(error_code_name, error_code_stata)
    st_strscalar(error_text_name, error_text)
}

function testscale(value, string scalar xy, string scalar type, ///
                   string scalar depvar, string scalar coefvar, string scalar indepvars, ///
                   string scalar touse, string scalar constant, ///
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
        b = myreg(scale, xy, type, depvar, coefvar, indepvars, touse, constant)
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

function myreg(scale, string scalar xy, string scalar type, string scalar depvar, string scalar coefvar, string scalar indepvars, string scalar touse, string scalar constant)
{

    real vector y, b, e, e2
    real matrix X, XpXi, other_X
    real scalar n, k

    st_view(y, ., depvar, touse)
    st_view(X, ., coefvar, touse)
    if (xy == "y") {
        if (type == "log") {
            y = ln(scale * y :+ 1)
        }
        else {
            y = ln(scale * y + sqrt((scale * y):^2 :+ 1))
        }
    }
    else {
        if (type == "log") {
            X = ln(scale * X :+ 1)
        }
        else {
            X = ln(scale * X + sqrt((scale * X):^2 :+ 1))
        }
    }
    if (indepvars != "") {
        st_view(other_X, ., indepvars, touse)
        X = X,other_X
    }
    n    = rows(X)

    if (constant == "") {
        X = X,J(n,1,1)
    }

    XpXi = quadcross(X, X)
    XpXi = invsym(XpXi)
    b = XpXi*quadcross(X, y)
    return(b[1])
}

void optimfun(todo, p, desired_value, string scalar xy, string scalar type, string scalar depvar, string scalar coefvar, string scalar indepvars, string scalar touse, string scalar constant, fml, g, H)
{
    if (p > 0) {
        b   = myreg(p, xy, type, depvar, coefvar, indepvars, touse, constant)
        fml = (b - desired_value)^2
    }
    else {
        fml = 1e10
    }
}

end
