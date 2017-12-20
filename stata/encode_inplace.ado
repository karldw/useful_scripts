program encode_inplace
    version 12.1
    syntax varlist(min=1 max=1)
    rename `varlist' `varlist'_old
    encode `varlist'_old, gen(`varlist')
    drop `varlist'_old
end
