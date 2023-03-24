# tgraph
A Stata Package for t-test graphs 

This package generates a stacked coefficient plot for two-tailed t-tests. It is very useful to showcase, through a very simple line of code, a graphical representation of covariates imbalance between groups. 

To install the package, copy and paste the following line in your Stata prompt: 
```s
net install tgraph, from("https://raw.githubusercontent.com/DiegoCiccia/tgraph/main") replace
```

# Syntax 
```s
syntax varlist(min=1) [if] [in], by(string)  
  [ label long reverse ci(string) 
    title(string) subtitle(string) 
    lc(string) lp(string) lw(string) 
    mc(string) msize(string) 
    seplc(string) seplp(string) seplw(string) 
    labsize(string) labangle(string) 
    scheme(string) ysize(string) xsize(string) 
    saving(string) replace
   ]
```
## Baseline 
+ varlist: (required) numeric outcome variables.
+ by():    (required) dummy variable defining two estimation groups. It can be numeric or string, but it must take only two distinct values.
+ label:   variable labels are used in place of variable names.
+ long:    confidence intervals are stacked horizontally (starting from the left side);. By default, confidence intervals are stacked vertically (starting from the bottom).
+ reverse: point estimates show average y(1) - y(0). As in the Stata ttest command, by default y(0) - y(1) is shown.
+ ci():    level of confidence. By default, ci(95) is specified.
 
