capture program drop shut_down
program shut_down
    timer off 100
    timer list 100
    log close _all
    clear all
    exit, STATA
end
