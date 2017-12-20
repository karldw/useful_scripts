program coalesce
    // This is exactly the same as egen var = rowfirst(...), except it stops you
    // from making dumb mistakes with variables that don't exist (which rowfirst
    // ignores silently), and also allows the new variable to be the same as one
    // of the coalesced variables.
    // This makes it almost identical to the coalesce function in R or SQL.
    version 12.1
    syntax varlist(min=1), Generate(name)

    tempvar temp_egen_var
    egen `temp_egen_var' = rowfirst(`varlist')

    // check if it's valid to create a new variable with the name provided
    capture confirm new variable `generate'
    local rc = _rc
    if `rc' == 0 {
        // if the `generate' variable doesn't exist already, create it
        rename `temp_egen_var' `generate'
    }
    else if `rc' == 110 {
        // if the `generate' variable already exists, replace it
        // 110 means the variable is already defined.
        quietly replace `generate' = `temp_egen_var'
    }
    else {
        // Any other return code else should generate an actual error.
        error `rc'
    }
end
