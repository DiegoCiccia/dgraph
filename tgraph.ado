cap program drop tgraph
program tgraph, rclass
version 13.0

#delimit ;
syntax varlist(min=1) [if] [in], by(string)
    [
        label
        long
        reverse
        echo

        ci(string)

        title(string)
        subtitle(string)
        
        lc(string)
        lp(string)
        lw(string)

        mc(string)
        msize(string)

        seplc(string)
        seplp(string)
        seplw(string)

        labsize(string)
        labangle(string)

        scheme(string)
        ysize(string)
        xsize(string)

        saving(string)
        replace

    ]
;
#delimit cr

token `varlist'
tempvar select
mark `select' `if' `in'

// Default Settings //
if length("`ci'") == 0 {
    local ci = 95
}
if length("`lc'") == 0 {
    local lc "black"
}
if length("`lw'") == 0 {
    local lw "0.5"
}
if length("`mc'") == 0 {
    local mc "black"
}
if length("`msize'") == 0 {
    local msize "small"
}
if length("`seplc'") == 0 {
    local seplc "red"
}
if length("`seplw'") == 0 {
    local seplw "0.25"
}
if length("`seplp'") == 0 {
    local seplp "-"
}
if length("`labangle'") == 0 {
    local labangle "0"
}

// Cleaning //

if missing("`by'") {
    dis as error "{bf:by()} option required"
    exit 100
}

local vars = 0
foreach v in `varlist' `by' {
    cap confirm var `v' 
    if !_rc == 0 {
        di as error "`v' not found"
        exit 111
    } 
    if "`v'" != "`by'" {
        if strpos("`:type `v''", "str") {
            di as error "type mismatch: `v' is a string var"
            exit 110
        }
        
        local vars = `vars' + 1
        local lab_`vars': var label `v'
        if "`lab_`vars''" == "" {
            local lab_`vars' = "`v'"
        }
    }
}

qui levelsof `by', local(groups)
if r(r) != 2 {
    di as error "{bf:by()} var is not dichotomous"
    exit 109
}

// Sample Selection (Optional) //
preserve
if length("`if'") > 0 | length("`in'") > 0 {
    qui keep if `select'
}
local N = _N

// Computation //

tempvar group
qui gen group = .
local j = 0 
foreach v of local groups {
    if strpos("`:type `by''", "str") == 0 {
       qui replace group = `j' if `by' == `v'
    }
    else {
       qui replace group = `j' if `by' == "`v'"
    }
    local j = `j' + 1
}

mata: mata clear
mata: st_view(X = ., ., "`varlist'")
mata: st_view(D = ., ., "group")
mata: D = D, J(rows(X), 1, 1)

forv i = 1/`vars' {
    mata: beta = invsym(cross(D,D)) * cross(D, X[., `i'])
    mata: st_numscalar("diff_`i'", beta[1,1])
    mata: sqerr = (X[., `i'] - D*beta):^2
    mata: std_err = sqrt(diagonal((sum(sqerr)/(rows(D) - cols(D))) * invsym(cross(D,D))))
    mata: st_numscalar("ste_`i'", std_err[1,1])
}

clear
qui set obs `vars'
tempvar name id beta se ci_ub ci_lb
qui gen name = ""
qui gen id = .
qui gen beta = .
qui gen ste = .
qui gen ci_ub = .
qui gen ci_lb = .
matrix define M = J(`vars', 3, .)
forv i=1/`vars' {
    {
        if length("`label'") == 0 {
            qui replace name = "`:word `i' of `varlist''" in `i'
        }
        else {
            qui replace name = "`lab_`i''" in `i'
        }
    }
    qui replace id = `i' in `i'
    qui replace ste = ste_`i' in `i'

    if length("`reverse'") != 0 {
        qui replace beta = diff_`i' in `i'
        qui replace ci_ub = beta[`i'] + ste[`i'] * invt(`N' - 2, `ci'/100 + ((100 - `ci') / 200)) in `i'
        qui replace ci_lb = beta[`i'] + ste[`i'] * invt(`N' - 2, (100 - `ci')/200) in `i'
    }
    else {
        qui replace beta = -1*diff_`i' in `i'
        qui replace ci_ub = beta[`i'] - ste[`i'] * invt(`N' - 2, (100 - `ci')/200) in `i'
        qui replace ci_lb = beta[`i'] - ste[`i'] * invt(`N' - 2, `ci'/100 + (100 - `ci')/200) in `i'
    }

    matrix M[`i', 1] = beta[`i'] 
    matrix M[`i', 2] = ci_lb[`i']
    matrix M[`i', 3] = ci_ub[`i']
}


matrix coln M = Diff Lb Ub
matrix rown M =  `varlist'
if length("`echo'") != 0 {
    matrix list M, format(%9.5fc) title("t-test by `by'")
}

local p = 1
drop ste
forv i=1/`vars' {
    local name_`i' = name[`i'] 
}
foreach v in ci_lb beta ci_ub {
    rename `v' p_`p' 
    local p = `p' + 1
}

qui reshape long p_, i(name) j(p)
qui sum id
local t = `p' - 1
sort id p


qui capture erase "graph.do"
qui capture file close graphcmd
qui file open graphcmd using "graph.do", write replace
file write graphcmd "qui "

if length("`long'") == 0 {
    forv j = 1/`vars' {
        file write graphcmd "line id p_ if id == `j', lc(`lc') lp(`lp') lw(`lw') ||"
    }
    forv i = 1/`t' {
        file write graphcmd "scatter id p_ if p == `i', mc(`mc') msize(`msize') ||"
    }
    file write graphcmd ", leg(off) ylabel(" 
    forv i = 1/`vars' {
        file write graphcmd "`i' "
        file write graphcmd `"`=char(34)'"'
        file write graphcmd "`name_`i''"
        file write graphcmd `"`=char(34)' "'
    }
    file write graphcmd ", nogrid labsize(`labsize') angle(`labangle')) xlabel(, grid) xline(0, lc(`seplc') lp(`seplp') lw(`seplw')) scheme(`scheme') "
}
else {
    forv j = 1/`vars' {
        file write graphcmd "line p_ id if id == `j', lc(`lc') lp(`lp') lw(`lw') ||"
    }
    forv i = 1/`t' {
        file write graphcmd "scatter p_ id if p == `i', mc(`mc') msize(`msize') ||"
    }
    file write graphcmd ", leg(off) xlabel(" 
    forv i = 1/`vars' {
        file write graphcmd "`i' "
        file write graphcmd `"`=char(34)'"'
        file write graphcmd "`name_`i''"
        file write graphcmd `"`=char(34)' "'
    }
    file write graphcmd ", nogrid labsize(`labsize') angle(`labangle')) ylabel(, grid) yline(0, lc(`seplc') lp(`seplp') lw(`seplw')) scheme(`scheme') "
}

foreach h in x y {
    file write graphcmd "`h'title("
    file write graphcmd `"`=char(34)'"'
    file write graphcmd `"`=char(34)'"'
    file write graphcmd ") "
}
file write graphcmd "title("
file write graphcmd `"`=char(34)'"'
file write graphcmd "`title'"
file write graphcmd `"`=char(34)'"'
file write graphcmd ") "
file write graphcmd "subtitle("
file write graphcmd `"`=char(34)'"'
file write graphcmd "`subtitle'"
file write graphcmd `"`=char(34)'"'
file write graphcmd ") "
file write graphcmd "xsize(`xsize') ysize(`ysize')"
if length("`replace'") == 0 {
    file write graphcmd " saving(`saving')"
}
else {
    file write graphcmd " saving(`saving', replace)"
}

file close graphcmd
qui include "graph.do"
erase "graph.do"
end
