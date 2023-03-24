# dgraph
A Stata Package for t-test graphs 

This package generates a stacked coefficient plot for two-tailed t-tests. It is very useful to showcase, through a very simple line of code, a graphical representation of covariates imbalance between groups. 

To install the package, copy and paste the following line in your Stata prompt: 
```s
net install tgraph, from("https://raw.githubusercontent.com/DiegoCiccia/dgraph/main") replace
```

## Syntax 
```s
syntax varlist(min=1) [if] [in], by(string)  
  [ 
    label long reverse echo ci(string) 
    title(string) subtitle(string) 
    lc(string) lp(string) lw(string) 
    mc(string) msize(string) 
    seplc(string) seplp(string) seplw(string) 
    labsize(string) labangle(string) 
    scheme(string) ysize(string) xsize(string) 
    saving(string) replace
  ]
```
### Baseline Options
+ varlist: (required) outcome variables. Only numeric variables can be included in varlist.
+ by():    (required) dummy variable defining two estimation groups. It can be numeric or string, but it must take only two distinct values.
+ label:   use variable labels in place of variable names.
+ long:    stack confidence intervals horizontally (starting from the left side);. By default, confidence intervals are stacked vertically (starting from the bottom).
+ reverse: shown point estimates as the average y(1) - y(0). As in the Stata ttest command, by default y(0) - y(1) is shown.
+ echo: print in the Stata console a table with the numeric values of the average difference between groups and upper/lower bounds for the estimate for each of the variables in varlist.
+ ci():    level of confidence. By default, ci(95) is specified.
### Graph Options
+ title(), subtitle(): specify title and subtitle of the graph. By default, no title nor subtitle.
+ lc(), lw(), lp(): change the color, width and patters of the lines in confidence intervals.
+ mc(), ms(): change color and size of scatter points for point estimates and upper/lower bounds.
+ seplc(), seplp(), seplw(): change the color, width and pattern of the separation line, by default at 0.
+ labsize(), labangle(): change size and angle orientation of variable labels on the graph.
+ scheme(): change the graph scheme.
+ ysize(), xsize(): change the axes sizes.
+ saving(): save the graph as a .gph file.
+ replace: replaces previous savings.
## Example
```s
clear
set seed 0
set obs 20000
forv i = 1/30 {
    gen var_`i' = rnormal()
    label var var_`i' "Dep Var `i'"
}
gen D = runiform() > 0.5
tostring D, replace
```
The previous block of code generates a dataset of 20,000 observations with 30 random variables (from a normal distribution). The group variable (D) is drawn from a random uniform distribution and indicates values above 0.5. To showcase that the command works for any by() variable as long as only two values are in its support, the variable D is reformatted as a string.
```s
dgraph var_*, by(D) long labangle(45) label scheme(white_tableau) title("Graph") reverse mc(blue) lw(0.2) ci(90) labsize(vsmall) saving(gr_sample) replace
```
Output:

![gr_sample](https://user-images.githubusercontent.com/71022390/227477700-3136dbf9-b0ca-4f4d-afcb-1012354e1bec.png)
##
This is a beta version. Please report bugs in the Issue section.
For any other information, contact me by e-mail: cicciadiego99@gmail.com
