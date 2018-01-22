



checkBuilt <- TRUE

find_rcpp_deps <- function(CRAN = getOption("repos", default = "https://cran.rstudio.com")) {
  # Borrowed from https://github.com/RcppCore/rcpp-logs/blob/master/scripts/showReverseRcppDepends.r
  if (length(CRAN) > 1) {
    CRAN <- CRAN[1]
  }
  if (CRAN == "@CRAN@") {
    CRAN <- "https://cran.rstudio.com"
  }

  IP <- installed.packages()
  AP <- available.packages(contrib.url(CRAN), filters = list())[, "Package", drop = FALSE]

  depend_on_rcpp <- unique(c(
    grep("Rcpp", as.character(IP[, "Depends",   drop = TRUE]), fixed = TRUE),
    grep("Rcpp", as.character(IP[, "LinkingTo", drop = TRUE]), fixed = TRUE),
    grep("Rcpp", as.character(IP[, "Imports",   drop = TRUE]), fixed = TRUE)
    ))
  are_compiled <- grep("yes", as.character(IP[, "NeedsCompilation", drop = TRUE]))
  depend_on_rcpp_and_compiled <- intersect(depend_on_rcpp, are_compiled)

  rcppset <- sort(unique(unname(IP[depend_on_rcpp_and_compiled, "Package", drop = TRUE])))

  # TODO: check version numbers of the CRAN offering vs what's installed. If installed is newer, add it to `other`
  onCRAN <- intersect(rcppset, AP)

  other <- setdiff(rcppset, AP)
  if (length(other) > 0) {
    message("\n\n  There are possibly local / github packages that depend on Rcpp.\n",
      "Please update them manually.\n ",
      dput(other))
  }
  return(onCRAN)
}

outdated <- old.packages(checkBuilt = checkBuilt)
if (! is.null(outdated)) {
  outdated <- outdated[! grepl("^/usr/l", as.character(outdated[, "LibPath"])), , drop = FALSE]
  if (NROW(outdated) == 0) {
    outdated <- NULL
  }
}

if (! is.null(outdated)) {
  pkg_to_update <- as.character(outdated[, "Package"])
  message("  Updating: ", paste(pkg_to_update, collapse = ", "), "\n")
  if ("Rcpp" %in% pkg_to_update) {
    rcpp_deps <- find_rcpp_deps()
    additional_rcpp_updates <- setdiff(rcpp_deps, pkg_to_update)
    if (length(additional_rcpp_updates) > 0) {
      message("  Also updating Rcpp-depending packages: ",
        paste(additional_rcpp_updates, collapse = ", "), "\n")
    }
    pkg_to_update <- union(pkg_to_update, rcpp_deps)
  }
  install.packages(pkg_to_update)
} else {
    message("  R packages are up to date.")
}
