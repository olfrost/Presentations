#### Author: Ollie Frost
#### Description: Performance comparisons.

library(data.table)
# library(RevoScaleR, lib = "C:/Program Files/Microsoft SQL Server/MSSQL13.MSSQLSERVER/R_SERVICES/library")

# Reading in with data.table.
df <- fread("C:/OF/airOT201201.csv") # 5 seconds

# Reading in with base.
df <- read.table("C:/OF/airOT201201.csv", header = TRUE, sep = ",") # 15-16 seconds

# Converting to XDF
df <- rxDataStep(inData = "C:/OF/airOT201201.csv", outFile = "C:/OF/airOT201201.xdf") # takes a while initially, but long term gains are key here.
df <- rxXdfToDataFrame("C:/OF/airOT201201.xdf") # 2-3 seconds.

# Final summary object.
dfSummary <- rxSummary(~., "C:/OF/airOT201201.xdf") # 2-3 seconds.

