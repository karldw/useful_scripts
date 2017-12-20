

capture program drop save_old
program save_old
    args filename
    // This will work fine if filename is not provided.

    // c(stata_version) gives the actual version of stata, not the version
    // that's poorly mimicked by the 'version' command. (Apparently saving isn't
    // one of the things 'version' will mimic...)
    local ver = c(stata_version)
    if `ver' >= 11 & `ver' < 13 {
        save "`filename'", replace
    }
    else if `ver' >= 13 & `ver' < 14 {
        saveold "`filename'", replace
    }
    else if `ver' >= 14 {
        // Untested:
        saveold "`filename'", replace version(12)
    }
    else {
        display as error "Use a newer Stata."
        exit
    }
end save_old
