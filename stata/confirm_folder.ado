

*! comfirm_folder Version 1.0
* Similar to Dan Blanchette's confirmdir, but actually raises an error.

program define confirm_folder
 version 8

 local cwd `"`c(pwd)'"'
 quietly capture cd `"`1'"'
 local confirmdir=_rc
 quietly cd `"`cwd'"'
 if `confirmdir' != 0 {
    display as error "Cannot access directory `1'"
    error `confirmdir'
 }
end
