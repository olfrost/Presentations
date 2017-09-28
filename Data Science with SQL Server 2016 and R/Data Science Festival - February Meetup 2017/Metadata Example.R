#### Author: Ollie Frost
#### Description: Extract the metadata from SPSS files for data modelling.

library(RevoScaleR)

#### 0. Setting up. ----------------------------------------------------------

# Create a directory for your .SAV files. Place them all in the single directory.
# In header #### 1 below, change setwd() to the path of your SPSS directory.
# Run the entire statement. You will have a vector with all of the file names.

#### 1. Get files. -----------------------------------------------------------
setwd("/path/to/savs"); files <- dir(pattern = "*.sav")

# Pick a file.
spss <- files[2]

#### 2. Pipe the data into an XDF file. --------------------------------------

# Prepare - create an output directory and an XDF file name.
if(!dir.exists("XDFs")) dir.create("XDFs")
outFile <- paste0("XDFs/", gsub(".sav",".xdf", spss))

# Use rxDataStep to pipe the data from the SPSS file into an XDF and include the Variable View.
df <- RxSpssData(
    spss, 
    stringsAsFactors = TRUE, # Set this to true to get categorical info in the rxSummary object.
    labelsAsInfo = TRUE, 
    labelsAsLevels = FALSE, 
    mapMissingCodes = "none" # Change to all to set missing values as NA.
    )

dfObj <- rxDataStep(df, outFile = outFile, overwrite = TRUE)

#### 3. Explore the object when the XDF is read. -----------------------------

# In piping the output, you also create a RxXdfData object that you can reuse.
# df <- rxImport(dfObj)
# dfSummary <- rxSummary(~., dfObj)

#### 4. Let's model the metadata. --------------------------------------------
dfVariables <- rxGetVarInfo(dfObj)

# Here's one way to do it from the rxGetVarInfo() function.
dfVariablesTbl <- data.frame(
  VariableNames = names(dfVariables), # What are the variable names?
  VarType = sapply(dfVariables, function(x){x$varType}), # data type
  MinValue = sapply(dfVariables, function(x){x$low}), # smallest answer value
  MaxValue = sapply(dfVariables, function(x){x$high}), # largest answer value
  Storage = sapply(dfVariables, function(x){x$storage}), # storage type
  Levels = sapply(dfVariables, function(x){paste0(x$levels[1:20], collapse = ",")}) # Summarize the answer labels.
)

# The data is also available as attributes in the main data.
# attr(dfVariables$anxiety, ".rxValueInfoCodes")
# attr(dfVariables$anxiety, ".rxValueInfoLabels")

#### 5. For more detail: -----------------------------------------------------

# You don't need to read in the whole data frame. All the data is in the VarInfo of the XDF.
# We can create a table of the remaining metadata and join with the simpler metadata table.

# Use the count of unique answers per question to build a list.
lens = sapply(dfVariables, function(x){length(x$valueInfoCodes)}); lens[lens == 0] <- 1 

# Cleanly get the desriptions and replicate as required.
dfVariableLabels = sapply(dfVariables, function(x){ifelse(is.null(x$description), "", x$description)})
dfVariableLabels = rep(dfVariableLabels, lens)

# Replicating and creating VariableLabels also does the work for VariableNames for us.
dfVariableNames <- names(dfVariableLabels)

# Get the value numbers and value labels. 
# These will end up on separate rows in the final table.
dfValueNums = lapply(unname(dfVariables), function(x){x$valueInfoCodes}) 
dfValueNums[sapply(dfValueNums, is.null)] <- ""

dfValueLabels = lapply(unname(dfVariables), function(x){x$valueInfoLabels})
dfValueLabels[sapply(dfValueLabels, is.null)] <- ""

#### 6. Final data frame. ----------------------------------------------------
dfFinal <- data.frame(
  VariableNames = dfVariableNames,
  VariableLabels = dfVariableLabels,
  ValueNums = unlist(dfValueNums),
  ValueLabels = unlist(dfValueLabels)
)

# Perform a join on the two tables.
dfFinal <- rxMerge(
  inData1 = dfVariablesTbl, inData2 = dfFinal, # tables to join
  matchVars = "VariableNames", type = "left", # how to perform the join
  varsToDrop1 = c("MinValue","MaxValue","Levels") # remove some columns
  )

# View final output.
dfFinal[order(dfFinal$VariableNames + df$ValueNums),]


