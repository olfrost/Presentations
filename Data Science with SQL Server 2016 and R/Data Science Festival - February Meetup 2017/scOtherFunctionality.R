#### Author: Ollie Frost
#### Description: The cool functionality inside RevoScaleR.

library(RevoScaleR, lib = "C:/Program Files/Microsoft SQL Server/MSSQL13.MSSQLSERVER/R_SERVICES/library")


# 1. Hadoop ---------------------------------------------------------------
rxHadoopListFiles("/example/path")
rxHadoopCopyFromLocal("C:/OF/whatever.txt", "/example/path/on/cluster.txt")

# 2. Spark jobs -----------------------------------------------------------
?RxSpark

# 3. Sql Server integration (if you don't want to run SQL Server.) --------
RxSqlServerData("SELECT * FROM table", connectionString = sqlServerConnString)

# 4. Everything else! ------------------------------------------------

RevoScaleR::


