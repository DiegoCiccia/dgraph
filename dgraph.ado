cap program drop dgraph
program dgraph, rclass
version 13.0

#delimit ;
syntax varlist(min=1) [if] [in], by(string)
    [
        label
        long
        reverse

        echo
        suppress

        ci(string)

        title(string)
        subtitle(string)
        
        lc(string)
        lp(string)
        lw(string)

        mc(string)
        msize(string)

        sl(string)
        sw(string)

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
        tabsaving(string)

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
if length("`sl'") == 0 {
    local sl "0.5"
}
if length("`sw'") == 0 {
    local sw "0.1"
}
if length("`title'") == 0 {
    local title ""
}
if length("`subtitle'") == 0 {
    local subtitle " "
}


// Cleaning ////////////////////////////////////////////////////////////////////////////////////////

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

// Computation /////////////////////////////////////////////////////////////////////////////////////

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
mata: I = J(rows(X), 1, 1)
mata: D = D, I 


forv i = 1/`vars' {
    mata: beta = invsym(cross(D,D)) * cross(D, X[., `i'])
    mata: st_numscalar("diff_`i'", beta[1,1])

    mata: sqerr = (X[., `i'] - D*beta):^2
    mata: std_err = sqrt(diagonal((sum(sqerr)/(rows(D) - cols(D))) * invsym(cross(D,D))))
    mata: st_numscalar("ste_`i'", std_err[1,1])

    mata: mu_1 = cross(X[., `i'], D[.,1]) / cross(D[.,1], I)
    mata: st_numscalar("mu1_`i'", mu_1[1,1])
    mata: mu_2 = cross(X[., `i'], I - D[.,1]) / cross(I - D[.,1], I)
    mata: st_numscalar("mu2_`i'", mu_2[1,1])
}


// Table Output ////////////////////////////////////////////////////////////////////////////////////

clear
qui set obs `vars'
tempvar name id beta se ci_ub ci_lb
qui gen name = ""
qui gen id = .
qui gen beta = .
qui gen ste = .
qui gen mu_1 = .
qui gen mu_2 = .
qui gen ci_ub = .
qui gen ci_lb = .
qui gen lev = 0
matrix define M = J(`vars', 6, .)
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
        qui replace mu_1 = mu1_`i' in `i'
        qui replace mu_2 = mu2_`i' in `i'
        qui replace ci_ub = beta[`i'] + ste[`i'] * invt(`N' - 2, `ci'/100 + ((100 - `ci') / 200)) in `i'
        qui replace ci_lb = beta[`i'] + ste[`i'] * invt(`N' - 2, (100 - `ci')/200) in `i'
    }
    else {
        qui replace beta = -1*diff_`i' in `i'
        qui replace mu_1 = mu2_`i' in `i'
        qui replace mu_2 = mu1_`i' in `i'
        qui replace ci_ub = beta[`i'] - ste[`i'] * invt(`N' - 2, (100 - `ci')/200) in `i'
        qui replace ci_lb = beta[`i'] - ste[`i'] * invt(`N' - 2, `ci'/100 + (100 - `ci')/200) in `i'
    }

    matrix M[`i', 1] = mu_1[`i'] 
    matrix M[`i', 2] = mu_2[`i'] 
    matrix M[`i', 3] = beta[`i'] 
    matrix M[`i', 4] = ste[`i'] 
    matrix M[`i', 5] = ci_lb[`i']
    matrix M[`i', 6] = ci_ub[`i']
}
qui gen p_val = tprob(`N' - 2, beta / ste)
qui replace lev = 1 if p_val < 0.1
qui replace lev = 2 if p_val < 0.05
qui replace lev = 3 if p_val < 0.01

if length("`reverse'") != 0 {
    matrix coln M = Avg_Treated Avg_Control Diff Lb Ub
}
else {
    matrix coln M = Avg_Control Avg_Treated Diff Lb Ub
}
matrix rown M =  `varlist'

local wrow = 75
local wrow1 = 25
local rrow1 = 15
local wrow2 = `wrow' - `wrow1'
if length("`echo'") != 0 {
    local sp = " " * (`wrow1' - strlen("t test by `by'"))
    if length("`reverse'") != 0 {
        local t_1 "Y(1)"
        local t_2 "Y(0)"
    }
    else {
        local t_1 "Y(0)"
        local t_2 "Y(1)"
    }
    local t_3 "Diff"
    forv j=1/3{
        local sp_`j' = " " * (`rrow1' - strlen("`t_`j''"))
    }
    di as text ""
    di as text "{hline `wrow1'}{c TT}{hline `wrow2'}"
    di as text  abbrev("t test by `by'", `wrow1')  "`sp'{c |}" "`sp_1'" abbrev("`t_1'", `rrow1') "`sp_2'" abbrev("`t_2'", `rrow1') "`sp_3'" abbrev("`t_3'", `rrow1')
    di as text "{hline `wrow1'}{c +}{hline `wrow2'}"
    forv i = 1/`vars' {
        local v_name = strtrim(name[`i'])
        local sp = " " * (`wrow1' - strlen("`v_name'"))
        forv j=1/3 {
            local t_`j': di %9.4f M[`i', `j']
            local sp_`j' = " " * (`rrow1' - strlen(strtrim("`t_`j''")))
        }
        local level = "*" * lev[`i']
        di as text abbrev("`v_name'", `wrow1')  "`sp'{c |}" "`sp_1'" abbrev("`t_1'", `rrow1') "`sp_2'" abbrev("`t_2'", `rrow1') "`sp_3'" abbrev("`t_3'", `rrow1') "`level'"
    }
    di as text "{hline `wrow1'}{c BT}{hline `wrow2'}"
    di as text "* p < 0.1, ** p < 0.05, *** p < 0.01"
}

// TeX Table ///////////////////////////////////////////////////////////////////////////////////////
if length("`tabsaving'") != 0 {
    local ttitle = subinstr("`tabsaving'", ".tex", "", .)
    local nl = char(10)
    local byvar = subinstr("`by'", "_", " ", .)
    qui capture erase "`ttitle'.tex"
    qui capture file close texcmd
    qui file open texcmd using "`ttitle'.tex", write replace 
    qui file write texcmd "\begin{tabular}{lccc} `nl'"
    qui file write texcmd "\hline\hline `nl'"
    if length("`reverse'") != 0 {
        qui file write texcmd "t test by `byvar' & Y(1) & Y(0) & $\Delta$ \\ `nl'"
    }
    else {
        qui file write texcmd "t test by `byvar' & Y(0) & Y(1) & $\Delta$ \\ `nl'"
    }
    qui file write texcmd "\hline `nl'"
    forv i = 1/`vars' {
        local v_name = strtrim(name[`i'])
        forv j=1/3 {
            local t_`j': di %9.4f M[`i', `j']
        }
        local level = "*" * lev[`i']
        qui file write texcmd "`v_name' & `t_1' & `t_2' & `t_3'$^{`level'}$ \\ `nl'"
    }

    qui file write texcmd "\hline\hline `nl'"
    qui file write texcmd "\multicolumn{4}{l}{$^{*} p < 0.1, ^{**} p < 0.05, ^{***} p < 0.01$}"
    qui file write texcmd "\end{tabular} `nl'"
    file close texcmd

}

// Graph Output ////////////////////////////////////////////////////////////////////////////////////

local p = 1
drop ste p_val lev 
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

if length("`suppress'") == 0 {
    qui capture erase "graph.do"
    qui capture file close graphcmd
    qui file open graphcmd using "graph.do", write replace
    file write graphcmd "qui "

    if length("`long'") == 0 {
        forv j = 1/`vars' {
            file write graphcmd "line id p_ if id == `j', lc(`lc') lp(`lp') lw(`lw') ||"
        }
        forv i = 1/`t' {
            {
            if `i' == 2 {
                file write graphcmd "scatter id p_ if p == `i', mc(`mc') msize(`msize') ||"
            }
            else if `i' == 1 {
                forv j = 1/`vars' {
                    local y = p_[`t' * `j' - 2]
                    local x_lb = `j' - `sl'/2
                    local x_ub = `j' + `sl'/2
                    file write graphcmd "pci `x_lb' `y' `x_ub' `y', lc(`lc') lw(`sw') ||"
                }
            }
            else if `i' == 3 {
                forv j = 1/`vars' {
                    local y = p_[`t' * `j']
                    local x_lb = `j' - `sl'/2
                    local x_ub = `j' + `sl'/2
                    file write graphcmd "pci `x_lb' `y' `x_ub' `y', lc(`lc') lw(`sw')  ||"
                }
            }
            }
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
            {
            if `i' == 2 {
                file write graphcmd "scatter p_ id if p == `i', mc(`mc') msize(`msize') ||"
            }
            else if `i' == 1 {
                forv j = 1/`vars' {
                    local y = p_[`t' * `j' - 2]
                    local x_lb = `j' - `sl'/2
                    local x_ub = `j' + `sl'/2
                    file write graphcmd "pci `y' `x_lb' `y' `x_ub', lc(`lc') lw(`sw') ||"
                }
            }
            else if `i' == 3 {
                forv j = 1/`vars' {
                    local y = p_[`t' * `j']
                    local x_lb = `j' - `sl'/2
                    local x_ub = `j' + `sl'/2
                    file write graphcmd "pci `y' `x_lb' `y' `x_ub', lc(`lc') lw(`sw')  ||"
                }
            }
            }
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
}
end
