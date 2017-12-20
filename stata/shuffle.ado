program shuffle
    version 12.1
    tempvar rand
    generate `rand' = runiform()
    sort `rand'
end shuffle
