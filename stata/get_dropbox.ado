
program get_dropbox, rclass
    version 12.1
    local dropbox_path : env DROPBOX_PATH
    // Dropbox doesn't set this DROPBOX_PATH variable, but if you don't have
    // dropbox installed or want to override the info.json file, you can set it
    // yourself.
    // If it hasn't been set, the code below goes through the trouble of finding
    // the proper path.
    if "`dropbox_path'" == "" {
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
            display as error "You can set the DROPBOX_PATH environment variable to specify the path manually."
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
    }
    else {
        // This is the case where the DROPBOX_PATH environment variable was set
        capture confirm file "`dropbox_path'"
        if _rc != 0 {
            disp as error "The manually specified Dropbox path does not exist:" _n "`dropbox_path'"
            error 601
        }
    }
    return local dropbox_path `dropbox_path'
end get_dropbox
