# tgraph
A Stata Package for t-test graphs 

net install tgraph, from("https://raw.githubusercontent.com/DiegoCiccia/tgraph/main") replace

syntax varlist(min=1) [if] [in], by(string)  [ label long reverse ci(string) title(string) subtitle(string) lc(string) lp(string) lw(string) mc(string)        msize(string) seplc(string) seplp(string) seplw(string) labsize(string) labangle(string) scheme(string) ysize(string) xsize(string) saving(string) replace]
