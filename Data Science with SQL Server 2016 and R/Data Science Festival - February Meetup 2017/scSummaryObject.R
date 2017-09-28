#### Author: Ollie Frost
#### Description: The rxSummary list object.

library(RevoScaleR, lib = "C:/Program Files/Microsoft SQL Server/MSSQL13.MSSQLSERVER/R_SERVICES/library")

options(scipen = 100)

# Create summary object.
df <- RxXdfData("C:/OF/airOT201201.xdf", stringsAsFactors = TRUE)
dfSummary <- rxSummary(~., df) # 2-3 seconds.

View(dfSummary$sDataFrame)

