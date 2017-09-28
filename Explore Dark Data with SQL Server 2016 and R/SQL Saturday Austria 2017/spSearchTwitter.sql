USE [OLF]
GO

/****** Object:  StoredProcedure [feed].[spSearchTwitter]    Script Date: 01/12/2016 17:00:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [feed].[spSearchTwitter] (
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

	EXEC [OLF].[feed].[spSearchTwitter] 
		@SearchTerm = N'SQL Relay', 
		@NumberOfTweets = N'200',
		@TweetAboutIt = 1;

*/

BEGIN TRY
	DECLARE @Rscript nvarchar(max);

	SET @Rscript = N'
	library(twitteR)
	library(httr)
	library(dplyr)

	# Make the script somewhat dynamic.
	searchTerm <- "' + @SearchTerm + '"

	# Get my keys from a separate file.
	source("/path/to/file/keys.r")

	# Authenticate.
	setup_twitter_oauth(api_key, api_secret, access_token, access_token_secret)

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
END TRY

BEGIN CATCH
	PRINT 'Cheeck that the incoming rules on the firewall settings on your machine allow for the R Services module to get data from the internet. 
	Think of the security precautions - this is only for fun.
	
	Or perhaps you have no internet connection?
	
	Or perhaps your authentication details are incorrect?'
END CATCH

END

GO


