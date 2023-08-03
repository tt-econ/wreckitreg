# README

<p align="center">
  <img src="/misc/Reg.png" width="420">
</p>

## Description

A Stata package to ["wreck"](https://movies.disney.com/wreck-it-ralph) any regression with a variable being transformed according to log(+1) or IHS (when there are zeros or negative values in the data) by applying a scaling factor on the transformed variable to achieve an arbitrary coefficient or semi-elasticity estimate.

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
   (NLSW, 1988 extract)

   . replace wage = 0 if wage < 2
   (26 real changes made)

   . wreckitreg wage tenure grade, coefvar(tenure) value(.03) absorb(age)
   (setting technique to nr)
   Iteration 0:   f(p) =  .00011345
   Iteration 1:   f(p) =  .00011345
   Iteration 2:   f(p) =  .00011345  (not concave)
   Iteration 3:   f(p) =  .00011345  (not concave)
   Iteration 4:   f(p) =  .00011345  (not concave)
   (switching technique to dfp)
   Iteration 5:   f(p) =  .00011345
   Iteration 6:   f(p) =  .00011345
   Iteration 7:   f(p) =  .00011345
   Iteration 8:   f(p) =  .00011345
   Iteration 9:   f(p) =  6.240e-07
   (switching technique to bfgs)
   Iteration 10:  f(p) =  1.379e-11
   Iteration 11:  f(p) =  9.497e-15
   Iteration 12:  f(p) =  1.384e-16
   Iteration 13:  f(p) =  2.626e-18


   Note: Results may not be obtainable outside the range between the two semi-elasticity values be
   > low due to machine precision:
   Semi-Elasticity Value with a scale of   1.00000000e-10:      .0193485116
   Semi-Elasticity Value with a scale of   1.00000000e+44:       .155239028


   Scaling wage by a factor of .16653186 will yield a semi-elasticity with respect to tenure (eval
   > uated at the means of covariates) of .03 for variable transformation: ln(1 + .1665319 * wage)
   > . Resulting regression:

   ---------------------------------------------------------------------------------------------
                                                            (1)                          (2)
                                                   Coefficient              Semi-Elasticity
   ---------------------------------------------------------------------------------------------
   Job tenure (years)                                     0.0131***                    0.0300***
                                                         (11.57)                      (11.57)

   Current grade completed                                0.0473***
                                                         (19.35)

   Constant                                               0.0728**
                                                         (2.24)
   ---------------------------------------------------------------------------------------------
   t statistics in parentheses
   * p<0.10, ** p<0.05, *** p<0.01


   Theoretical limit cases:
   As scale -> 0, semi-elasticity -> .0193485117215812
   As scale -> infty, abs(semi-elasticity) -> infty
   Note that the semi-elasticity estimate may not change monotonically with the scale.
```

See the help file for more: In Stata, type `help wreckitreg` after installation.

## References

["When Are Estimates Independent of Measurement Units?" (Thakral and Tô 2023)](https://linh.to/files/papers/transformations.pdf)

&nbsp;

Ⓒ 2022–2023 Neil Thakral and Linh T. Tô
