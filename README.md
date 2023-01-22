# README

<p align="center">
  <img src="/misc/Reg.png" width="420">
</p>

## Description

A Stata package to ["wreck"](https://movies.disney.com/wreck-it-ralph) any regression with a variable being transformed according to log(+1) or IHS (when there are zeros in the data) by applying a scaling factor on the transformed variable to achieve an arbitrary coefficient.

## Requirements

- Stata

## Installation

From Stata:

```
   net install wreckitreg, from("https://raw.githubusercontent.com/tt-econ/wreckitreg/main/pkg")
```

## Example

In Stata, after installation:

```
   . sysuse nlsw88, clear
   . wreckitreg wage tenure grade, coefvar(tenure) value(10000) xvar ihs
   (setting technique to nr)
   Iteration 0:   f(p) =  1.878e+10
   Iteration 1:   f(p) =  6605253.3  (not concave)
   Iteration 2:   f(p) =  1384.9877
   Iteration 3:   f(p) =  125.00677
   Iteration 4:   f(p) =  9.5921847  (not concave)
   (switching technique to dfp)
   Iteration 5:   f(p) =  .77849023
   Iteration 6:   f(p) =   .0000251
   Iteration 7:   f(p) =  5.404e-07
   Iteration 8:   f(p) =  1.243e-09
   Iteration 9:   f(p) =  4.821e-12
   (switching technique to bfgs)
   Iteration 10:  f(p) =  1.017e-14
   Iteration 11:  f(p) =  2.995e-15
   Iteration 12:  f(p) =  6.084e-17


   Coefficient Value with a scale of   1.00000000e+50:     .00436957484
   Coefficient Value with a scale of   1.00000000e-10:       1470505000
   Note: Results may not be obtainable between the two coefficient values above due to machine precision


   Scaling tenure by a factor of .00001471 will yield a coefficient on tenure of 10000 for variable transformation
   > : ihs(.0000147 * tenure). Resulting regression:

         Source |       SS           df       MS      Number of obs   =     2,229
   -------------+----------------------------------   F(2, 2226)      =    159.60
          Model |  9291.77652         2  4645.88826   Prob > F        =    0.0000
       Residual |  64796.1912     2,226  29.1088011   R-squared       =    0.1254
   -------------+----------------------------------   Adj R-squared   =    0.1246
          Total |  74087.9678     2,228  33.2531274   Root MSE        =    5.3953

   ------------------------------------------------------------------------------------
              wage | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
   -------------------+----------------------------------------------------------------
   ___transformed_var |      10000   1422.184     7.03   0.000     7211.054    12788.95
                grade |    .704318    .045626    15.44   0.000     .6148441     .793792
                _cons |  -2.311109   .6063331    -3.81   0.000    -3.500146   -1.122071
   ------------------------------------------------------------------------------------
```

See the help file for more: In Stata, type `help wreckitreg` after installation.

## References

See "Rightly transforming right-skewed variables" (Thakral and Tô 2023)

&nbsp;

Ⓒ 2022 Neil Thakral and Linh T. Tô
