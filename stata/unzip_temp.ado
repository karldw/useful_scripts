

program unzip, rclass
    // Unzip a file to a temporary directory, return the file name as r(file)
    // Raise an error if more than one file is unzipped
    args zipfilename
    confirm file "`zipfilename'"
    tmpdir
    local tempdir = "`r(tmpdir)'"
    assert "`tempdir'" != ""
    local orig_dir = "`c(pwd)'"
    local stata_tempdir = "`tempdir'stata_unzip"
    remove_folder "`stata_tempdir'"
    mkdir "`stata_tempdir'"
    local temp_zipfile = "`stata_tempdir'/`zipfilename'"
    // Copy the zipfile to the temp dir because stata can only unzip in the same
    // directory as the zipfile.
    copy "`zipfilename'" "`temp_zipfile'"
    quietly cd "`stata_tempdir'/"
    capture unzipfile "`zipfilename'"
    if _rc != 0 {
        quietly cd `"`orig_dir'"'
        disp as error "Failed to unzip `zipfilename'"
        error 601
    }
    quietly cd "`orig_dir'"
    rm "`temp_zipfile'"
    quietly fs "`stata_tempdir'/*"
    local filelist = `"`r(files)'"'
    local numfiles : word count `filelist'
    if `numfiles' == 0 {
        disp as error "Failed to find unzipped files"
        ls "`stata_tempdir'/"
        error 9999
    }
    else if `numfiles' > 1 {
        disp as error "Unzipped multiple files, not sure which to return"
        ls "`stata_tempdir'/"
        error 9999
    }
    local to_return "`stata_tempdir'/" + `filelist'
    return local unzipped `"`to_return'"'
end


program remove_folder
    // Remove a folder and everything in it
    args foldername
    assert "`foldername'" != ""
    local actually_delete = 0
    capture confirm file "`foldername'"
    if _rc == 0 {
        capture confirm_folder "`foldername'"
        if _rc == 0 {
            local actually_delete = 1
        }
    }
    if `actually_delete' {
        if "`c(os)'" == "Windows" {
            shell rmdir "`foldername'" /s
        }
        else {
            // Use -- to protect against weird folders that start with '-'
            shell rm --recursive -- "`foldername'"
        }
    }
end
