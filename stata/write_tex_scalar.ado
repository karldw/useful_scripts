program write_tex_scalar
    version 12.1
    args latex_name value other_args
    // A more sophisticated version could:
    // - check that the latex_name looks valid
    // - check that there's not already a definition for that command
    // - check that value is a number
    // - try to evaluate value if it's an expression
    if "`latex_name'" == "" {
        disp as error "Must provide the name you're going to use for the command in latex"
        exit 1000
    }
    if "`value'" == "" {
        disp as error "Must provide a value to write"
        exit 1000
    }
    if "`other_args'" != "" {
        disp as error "Sorry, write_tex_scalar isn't sophisticated enough " ///
            "to evaluate `value' `other_args'..." _n ///
            "Please provide simple arguments."
        exit 1000
    }

    // Get dropbox folder and the data_scalars.tex location
    // Save as a global so we don't have two look it up every time
    if "$write_tex_scalar_filename" == "" {
        get_dropbox
        global write_tex_scalar_filename = "`r(dropbox_path)'/KarlJim/Horizontal_equity/Outputs/data_scalars.tex"
        noisily display as error "NOTE: You want this as your latex scalars file: " _n ///
            "  $write_tex_scalar_filename" _n ///
            "If you want to save to a different file, set the " ///
            "\$write_tex_scalar_filename global"
    }
    // Sure would be nice if I could specify an encoding...
    quietly file open f using "$write_tex_scalar_filename", write text append
    // Write the \newcommand, then a new line.
    // Don't ask me why there's one \ for \newcommand and two for \\`latex_name'
    file write f "\newcommand{\\`latex_name'}{`value'}" _n
    file close f
end
