ReadPairs <- function (fn) {
  # Read in a pairs file, and fill in a list with useful information. This also rebins the data in r
  # Args :
  #   fn : filename
  # Outputs :
  #     pairs : array (nmu, nr) of pair counts
  
  ff <- file(fn, "r")
  # Read in rbins
  rbins <- scan(ff,numeric(0),nlines=1)
  nrbins <- length(rbins)-1
  mubins <- scan(ff, numeric(0),nlines=1)
  nmubins <- length(mubins)-1
  pairs <- array(scan(ff, numeric(0)), c(nmubins, nrbins))
  close(ff)
  pairs
}

ref <- ReadPairs("reference-DD.dat")

Cmp <- function(fn) {
  test1 <- ReadPairs(fn)
  max(abs(test1-ref))
}

fns <- Sys.glob("corr?-??.dat")
library(plyr)
diffs<-aaply(fns,1,.fun=Cmp)
cat("MAD=",max(diffs))
cat("Min ref=",min(ref))
