program assert_verbose
    * Assert something and provide a more helpful error if it's not true
    * This isn't perfect; it would be better if I could see exactly what was written
    version 12.1
    capture noisily assert `0'
    if _rc != 0 {
        disp as error "  failed assertion: '`0''"
        error 9
    }
end
