#### Author: Ollie Frost
#### Description: Trying out RevoScaleR again.

library(RevoScaleR)

# 0. Make script dynamic --------------------------------------------------
setwd("C:/OF")
files <- dir(getwd(), pattern = "*.tsv")

# 1. Import a data frame and create an XDF --------------------------------

## Convert a flat file into an external data frame.
wcaResultsXdf <- rxImport(
    inData = files[1], 
    outFile = "wcaResults.xdf",
    stringsAsFactors = TRUE, 
    missingValueString = "M", 
    rowsPerRead = 200000
    )

## Read in an Xdf into memory if you prefer.
wcaResults <- rxReadXdf("wcaResults.xdf")

# 2. Get some information about an Xdf. -----------------------------------
  
  ## Get Xdf info.
  rxGetInfo(wcaResultsXdf, getVarInfo = TRUE)

  ## Get a summary around a set of factors.
  output <- rxSummary( ~ ., wcaResultsXdf) ### You can actually use this object for stuff.

  