capture program drop get_dropbox
program get_dropbox, rclass

    preserve
    clear
    confirm_installed insheetjson
    confirm_installed libjson
    local os = "`c(os)'"
    assert "`os'" != ""
    if "`os'" == "Windows" {
        local appdata : env APPDATA
        local info_path "`appdata'/Dropbox/info.json"
        capture confirm file "`info_path'"

        if _rc == 7 | _rc == 601 {
            local appdata : env LOCALAPPDATA
            local info_path "`appdata'/Dropbox/info.json"
        }
        else if _rc != 0 {
            // re-raise error
            error _rc
        }
    }
    else if "`os'" == "MacOSX" | "`os'" == "Unix" {
        local info_path "~/.dropbox/info.json"
    }
    else {
        display as error "Unknown operating system: `os'."
    }
    capture confirm file "`info_path'"
    if _rc != 0 {
        display as error "Could not find the Dropbox info.json file! (If Dropbox is installed, it should be here: `info_path')"
        error 601
    }
    quietly set obs 1
    // Linux paths can be longer than Stata's max length, (4096 vs 2045).
    // I'll use a strL instead, if available. (strL was introduced in stata 13).
    // Windows paths are max 260 characters, so that's probably fine anyway.
    // strL should work in versions >= 13, but insheetjson doesn't play nicely
    // Just use the max length for normal strings instead.
    quietly generate str`c(maxstrvarlen)' dropbox_path = ""

    quietly insheetjson dropbox_path using "`info_path'", col("business:path")
    quietly count if dropbox_path == ""
    if r(N) > 0 {
        quietly insheetjson dropbox_path using "`info_path'", col("personal:path")
    }
    quietly count if dropbox_path == ""
    if r(N) > 0 {
        display as error "Failed to parse `info_path'!"
        error 459
    }
    quietly count
    if r(N) != 1 {
        disp as error "Error in json parsing; got wrong number of results."
        error 459
    }

    // Get rid of the long string (we almost certainly didn't need it)
    quietly compress

    local dropbox_path = dropbox_path[1]
    return local dropbox_path `dropbox_path'
end get_dropbox


capture program drop confirm_installed
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
