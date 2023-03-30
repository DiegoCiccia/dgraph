# dgraph
A Stata package for t-test graphs - Update: tables with significance levels in Stata console and LaTeX

v. 2.1

This package generates a stacked coefficient plot for two-tailed t-tests. It is very useful for showcasing, through a very simple line of code, a graphical representation of covariates imbalance between groups. 

To install the package, copy and paste the following line in your Stata prompt: 
```s
net install dgraph, from("https://raw.githubusercontent.com/DiegoCiccia/dgraph/main") replace
```

## Syntax 
```s
syntax varlist(min=1) [if] [in], by(string)  
  [ 
    label long reverse echo suppress ci(num) 
    title(string) subtitle(string) 
    lc(string) lp(string) lw(num) 
    mc(string) msize(string) 
    sl(num) sw(num)
    seplc(string) seplp(string) seplw(num) 
    labsize(num) labangle(num) 
    scheme(string) ysize(num) xsize(num) 
    saving(string) replace tabsaving(string)
  ]
```
### Baseline Options
+ varlist: (required) outcome variables. Only numeric variables can be included in varlist.
+ by():    (required) dummy variable defining two estimation groups. It can be numeric or string, but it must take only two distinct values.
+ label:   use variable labels in place of variable names.
+ long:    stack confidence intervals horizontally (starting from the left side);. By default, confidence intervals are stacked vertically (starting from the bottom).
+ reverse: shown point estimates as the average y(1) - y(0). As in the Stata ttest command, by default y(0) - y(1) is shown.
+ echo: print in the Stata console a table with the numeric values of the average difference between groups and upper/lower bounds for the estimate for each of the variables in varlist.
+ suppress: (often used in combination with echo and tabsaving) the graph is not produced, while values can be still displayed in console or printed in file.
+ ci():    level of confidence. By default, ci(95) is specified.
### Graph Options
+ title(), subtitle(): specify title and subtitle of the graph. By default, no title nor subtitle.
+ lc(), lw(), lp(): change the color, width and patters of the lines in confidence intervals.
+ mc(), ms(): change color and size of scatter points for point estimates and upper/lower bounds.
+ sl(), sw(): change length and width of segments at the edges of confidence intervals.
+ seplc(), seplp(), seplw(): change the color, width and pattern of the separation line, by default at 0.
+ labsize(), labangle(): change size and angle orientation of variable labels on the graph.
+ scheme(): change the graph scheme.
+ ysize(), xsize(): change the axes sizes.
+ saving(): save the graph as a .gph file.
+ replace: replaces previous savings.
+ tabsaving(): saves the echo output as a TeX tabular (automatic replace).
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
dgraph var_*, by(D) long labangle(45) label scheme(white_tableau) title("Graph") reverse mc(black) msize(1) lw(0.2) ci(90) labsize(vsmall) saving(gr_sample) replace echo tabsaving(table)
```
Output:
- Figure

![gr_sample](https://user-images.githubusercontent.com/71022390/228767059-c76d2cce-9512-4bc1-81de-0b7787600d61.png)

- Console

![tab](https://user-images.githubusercontent.com/71022390/228756990-371dead9-efa5-4ac4-a294-dfc044451cee.png)

- TeX file

![tab_tex](https://user-images.githubusercontent.com/71022390/228757031-75ec33f1-17ba-4c0d-b253-c2be220c9158.png)

##
This is a beta version. Please report bugs in the Issues section.
For any other information, contact me by e-mail: cicciadiego99@gmail.com
