# tgraph
A Stata Package for t-test graphs 

This package generates a stacked coefficient plot for two-tailed t-tests. It is very useful to showcase, through a very simple line of code, a graphical representation of covariates imbalance between groups. 

To install the package, copy and paste the following line in your Stata prompt: 
```s
net install tgraph, from("https://raw.githubusercontent.com/DiegoCiccia/tgraph/main") replace
```

** Syntax 
syntax varlist(min=1) [if] [in], by(string)  [ label long reverse ci(string) title(string) subtitle(string) lc(string) lp(string) lw(string) mc(string)        msize(string) seplc(string) seplp(string) seplw(string) labsize(string) labangle(string) scheme(string) ysize(string) xsize(string) saving(string) replace]
