USE [nyctaxi]
GO

ALTER PROC [dbo].[spSearchTwitter] (
	@SearchTerm nvarchar(140),
	@NumberOfTweets nchar(5),
	@TweetAboutIt bit = 0
	)
AS
BEGIN

/*
Author: Ollie Frost
Description: Sql Saturday in Prague - get tweets from Twitter.
Created: 30 Nov 2016

Twitter: @ConsolidataLtd
Website: http://www.consolidata.co.uk
GitHub: GitHub/olfrost

Example:

	EXEC [nyctaxi].[dbo].[spSearchTwitter] 
		@SearchTerm = N'Data Science', 
		@NumberOfTweets = N'200',
		@TweetAboutIt = 0;

*/


	DECLARE @Rscript nvarchar(max);

	SET @Rscript = N'
	library(twitteR)
	library(httr)
	library(dplyr)

	options(httr_oauth_cache = FALSE)

	# Make the script somewhat dynamic.
	searchTerm <- "' + @SearchTerm + '"

	options(httr_oauth_cache = TRUE)

	# Set working directory
	source("C:/OF/ExploreDarkData/keys.r")

	print(paste(api_key, api_secret, access_token, access_token_secret, collapse = "\r\n"))

	# Authenticate.
	setup_twitter_oauth(api_key, api_secret, access_token, access_token_secret)

	print("test")

	# Get data.
	tweets <- searchTwitter(searchTerm, n = ' + @NumberOfTweets + ')
	tweetsDF <- twListToDF(tweets)
	tweetsOutput <- select(tweetsDF, 8, 11, 1, 5)
	tweetsOutput$SearchTerm <- "' + @SearchTerm + '"

	# Let''s tweet about it for fun.
	' + CASE 
			WHEN @TweetAboutIt = 1 THEN '' 
			ELSE '#' /* if 0, then the updateStatus() function is commented out. */
			END + 'updateStatus(paste0("I just pulled ", nrow(tweetsDF), " tweets about ", searchTerm, " for my demo!")) 
	';

	PRINT @Rscript;

	EXECUTE sp_execute_external_script
		@language = N'R',
		@script = @Rscript,
		@output_data_1_name = N'tweetsOutput'
	WITH RESULT SETS ((
		[Id] bigint,
		[ScreenName] nvarchar(140),
		[TweetBody] nvarchar(140),
		[Timestamp] datetime2,
		[SearchTerm] nvarchar(140)
		))

END


GO


