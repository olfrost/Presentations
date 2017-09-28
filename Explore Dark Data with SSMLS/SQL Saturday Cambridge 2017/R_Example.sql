USE worldcities
GO

/*

Author: Ollie Frost
Description: Presentation for Data Science Festival
Date: 06-09-2017

*/

/*
0. Setting up R inside SQL Server 2016.
*/
SELECT @@VERSION as [What version are we using?];

EXECUTE sp_configure 'external scripts enabled', 1;
RECONFIGURE;

-- You will need to restart SQL Server, including the LaunchPad service.
EXECUTE sp_configure;

/*
1. How to execute R from a T-SQL script?

	a. Declare a script variable (must be nvarchar.)
	b. SET the value of the variable to the script you want.
	c. Call sp_execute_external_script with your parameters.

*/

DECLARE @Rscript nvarchar(128);

SET @Rscript = N'
df <- aggregate(Sepal.Length ~ Species, data = iris, FUN = median)';

EXEC sp_execute_external_script
	@language = N'R',
	@script = @Rscript,
	@output_data_1_name = N'df'; -- estimated time < 1s

/*
2. Some data engineering to configure your environment.
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
3. Use your external libraries and analyze the results in SQL.

	a. Build contained stored procedures or functions.
	b. Profile data.
	c. Combine relational and non-relational.

*/ 

EXEC [dbo].[spSearchTwitter] 
	@SearchTerm = N'trump', 
	@NumberOfTweets = N'200',
	@TweetAboutIt = 0;

/*
5. Perform tricky operations in R and return a table to work with in SQL.
Estimated run time = 6s.
*/

--DECLARE @Rscript nvarchar(max);

CREATE TABLE dbo.TweetTable (
    [TweetBody] nvarchar(140),
    [favorited] bit,
    [favoriteCount] bigint,
    [replyToSN] nvarchar(140),
    [created] datetime,
    [truncated] bit,
    [replyToSID] nvarchar(140),
    [id] nvarchar(140),
    [replyToUID] nvarchar(140),
    [statusSource] nvarchar(255),
    [screenName] nvarchar(140),
    [retweetCount] bigint,
    [isRetweet] bit,
    [retweeted] bit,
    [longitude] decimal(10,4),
    [latitude] decimal(10,4),
	[searchTerm] nvarchar(70)
	);

INSERT INTO dbo.TweetTable
EXEC [dbo].[spSearchTwitter] 
	@SearchTerm = N'data science', 
	@NumberOfTweets = N'200',
	@TweetAboutIt = 0;

DECLARE @InputSql nvarchar(250) = N'SELECT * FROM dbo.TweetTable';

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

DROP TABLE dbo.TweetTable;

/*
5. What is RevoScaleR?

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
