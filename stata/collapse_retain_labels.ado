program collapse_retain_labels
    // Taken from http://statadaily.com/2011/02/02/saving-variable-labels-be3-collapse/
    foreach var of varlist * {
        local vlab`var': var label `var'
    }
    // `0' says "input exactly what the user typed"
    collapse `0'
    foreach var of varlist * {
        label var `var' "`vlab`var''"
    }
end
