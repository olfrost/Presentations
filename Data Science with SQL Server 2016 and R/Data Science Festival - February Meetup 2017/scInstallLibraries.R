#### Author: Ollie Frost
#### Description: How to install libraries for your R Server.

path <-"C:/Program Files/Microsoft SQL Server/MSSQL13.MSSQLSERVER/R_SERVICES/library"
pkgs <- c("data.table","dplyr","tidyr","twitteR","base64enc","httr","DBI","Rcpp")

## Add path to an R internal that specifies which directory to install libraries in.
.libPaths(path)

## Install.
install.packages(pkgs)

## Or install directly.
install.packages(pkgs, lib = path)
