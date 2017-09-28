USE OLF
GO

/*
Author: Ollie Frost
Description: Sql Saturday in Prague - Microsoft R Server examples.
Created: 30 Nov 2016

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
-- restart SQL Server!

/*
1. How to execute R from a T-SQL script?
*/

DECLARE @Rscript nvarchar(512);
SET @Rscript = N'

library(RevoScaleR)

# Get data.
wcaResults <- rxReadXdf("C:/OF/wcaResultsPivoted.xdf")

# Get a summary of a particular variable/group of variables.
wcaSummary <- rxSummary( ~ personCountryId , wcaResults)

# Export as a data frame.
wcaOutput <- wcaSummary$categorical[[1]]';

/* 
Output the summary by calling sp_execute_external_script again.
Estimated run time = 5s 
*/
EXEC sp_execute_external_script
	@language = N'R',
	@script = @Rscript,
	@output_data_1_name = N'wcaOutput'
WITH RESULT SETS ((
	Country varchar(70),
	Freq int
	));
	
/*
NB: Using packages in R

The best way to install the packages you want is to spin up a local R session and use the install.packages() function.
Install the libraries into the ./library directory inside the MSSQLSERVER directories.

>	.libPaths("C:/Program Files/Microsoft SQL Server/MSSQL13.MSSQLSERVER/R_SERVICES/library")
>   install.packages(c("dplyr","base64enc","tm"))
*/

/*
2. Increased flexibility in what you can do from SQL.
Estimated run time = 7s.
*/ 

EXEC [feed].[spSearchTwitter] 
	@SearchTerm = N'Microsoft', 
	@NumberOfTweets = N'200',
	@TweetAboutIt = 1;

/*
3. Perform tricky operations in R and return a table to work with in SQL.
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

EXEC [OLF].[feed].[spSearchTwitter] 
	@SearchTerm = N'Prague', 
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
	@input_data_1 = @InputSql,
	@input_data_1_name = N'tweets',
	@output_data_1_name = N'output';

SELECT
	Hashtag,
	Freq
FROM
	@HashtagTable
WHERE
	Freq >= 3
ORDER BY
	Freq DESC;

/*
Clean up
*/

DROP TABLE ##TweetTable;