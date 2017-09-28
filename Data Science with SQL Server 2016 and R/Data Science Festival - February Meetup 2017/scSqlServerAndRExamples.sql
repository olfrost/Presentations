USE nyctaxi
GO

/*
Author: Ollie Frost
Description: Presentation for Data Science Festival
Date: 21 Feb 2017

Twitter: @ConsolidataLtd
Website: http://www.consolidata.co.uk
GitHub: GitHub/olfrost

*/

SELECT @@VERSION as [What version are we using?];

/*
0. Setting up R inside SQL Server 2016.
*/

EXECUTE sp_configure 'external scripts enabled', 1;
RECONFIGURE;

-- You will need to restart SQL Server, including the LaunchPad service.
-- However, you can create a machine on Azure with Microsoft R Server ready to go on a SQL Instance.

/*
1. How to execute R from a T-SQL script?

	a. Declare a script variable (must be nvarchar.)
	b. SET the value of the variable to the script you want.
	c. Call sp_execute_external_script with your parameters.

*/

DECLARE @Rscript nvarchar(512);

SET @Rscript = N'
df <- aggregate(Sepal.Length ~ Species, data = iris, FUN = median)';

EXEC sp_execute_external_script
	@language = N'R',
	@script = @Rscript,
	@output_data_1_name = N'df'; -- estimated time < 1s

/*

2. Install packages in R:

	See "scInstallLibraries.R"

	X - running "install.packages("pkg")" from a T-SQL query will not work.

*/

/*
3. Some data engineering to configure your environment.
*/

CREATE EXTERNAL RESOURCE POOL DeadPool
WITH
(
    MAX_CPU_PERCENT = 60,
    AFFINITY CPU = AUTO,
    MAX_MEMORY_PERCENT = 70
);
GO
 
ALTER RESOURCE GOVERNOR
RECONFIGURE;    
 
GO

/*
4. Use your external libraries and analyze the results in SQL.

	a. Build contained stored procedures or functions.
	b. Profile data.
	c. Combine relational and non-relational.

*/ 

EXEC [dbo].[spSearchTwitter] 
	@SearchTerm = N'trump', 
	@NumberOfTweets = N'200',
	@TweetAboutIt = 1;

/*
5. Perform tricky operations in R and return a table to work with in SQL.
Estimated run time = 6s.
*/

--DECLARE @Rscript nvarchar(max);

CREATE TABLE ##TweetTable (
	[Id] bigint,
	[ScreenName] nvarchar(140),
	[TweetBody] nvarchar(140),
	[Timestamp] nvarchar(140),
	[SearchTerm] nvarchar(140)
	);

INSERT INTO ##TweetTable
([Id], [ScreenName], [TweetBody], [Timestamp], [SearchTerm])

EXEC [dbo].[spSearchTwitter] 
	@SearchTerm = N'data science', 
	@NumberOfTweets = N'200',
	@TweetAboutIt = 0;

DECLARE @InputSql nvarchar(250) = N'SELECT * FROM ##TweetTable';

DECLARE @HashtagTable TABLE (
	Hashtag nvarchar(140),
	Freq int
	);

--DECLARE @Rscript nvarchar(512)
SET @Rscript = N'
# Split out words within tweets 
tweets.split <- unlist(strsplit(as.character(tweets$TweetBody), " "))
hashtags <- tolower(grep("^#", tweets.split, value = TRUE))
hashtags <- gsub("[^[:alnum:][:space:]#]", "", hashtags)

# Output hashtag table
output <- data.frame(table(hashtags))
';

INSERT INTO @HashtagTable
(Hashtag, Freq)
EXECUTE sp_execute_external_script 
	@language = N'R',
	@script = @Rscript,

--	@params = N'@r_rowsPerRead int = 50000',
--	@parallel = 1,
-- https://msdn.microsoft.com/en-GB/library/mt604368.aspx

	@input_data_1 = @InputSql,
	@input_data_1_name = N'tweets',
	@output_data_1_name = N'output';

SELECT
	Hashtag,
	Freq
FROM
	@HashtagTable
WHERE
	Freq >= 2
ORDER BY
	Freq DESC; -- estimated run time = 15s

/*
Clean up
*/

	DROP TABLE ##TweetTable;

/*
6. What is RevoScaleR?

	a. Open source R is single-threaded.
	b. Everything is done in memory, so depending on the package, you start to see performance drop with very large files.
		
		base = 10m rows.
		data.table = 100m rows.

	c. Microsoft has developed on open-source R so that R jobs can be processed:
	
		on large files
		in parallel
		data frames can be stored on the disk. (XDFs) 

*/

--DECLARE @RScript nvarchar(max);
SET @RScript = N'
df <- rxXdfToDataFrame("C:/OF/airOT201201.xdf")
dfSummary <- rxSummary(~., df) # 2-3 seconds.
output <- dfSummary$sDataFrame';

	/* Summarize a file using a stored proc. */
	EXEC sp_execute_external_script
		@language = N'R',
		@script = @Rscript,
		@output_data_1_name = N'output'
	WITH RESULT SETS ((
		ColumnName nvarchar(70),
		Mean numeric,
		StdDev numeric,
		MinValue numeric,
		MaxValue numeric, 
		ValidObs int,
		MissingObs int
	))
