program confirm_installed
    foreach ado_name of local 0 {
        capture findfile "`ado_name'.ado"
        local ado_find = _rc
        capture findfile "`ado_name'.mlib"
        local mlib_find = _rc
        if `ado_find' == 601 & `mlib_find' == 601 {
            display "  NOTE: installing required package `ado_name'."
            quietly ssc install `ado_name'
        }
    }
end confirm_installed
