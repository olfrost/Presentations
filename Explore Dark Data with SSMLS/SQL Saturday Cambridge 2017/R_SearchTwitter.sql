USE worldcities
GO

ALTER PROC [dbo].[spSearchTwitter] (
	@SearchTerm nvarchar(140),
	@NumberOfTweets nchar(4),
	@TweetAboutIt bit = 0
	)
AS
BEGIN

/*
Author: Ollie Frost
Description: An integrated R script to retrieve tweets from the Twitter REST API.
Created: 06-09-2017

GitHub: GitHub/olfrost

Example:

	EXEC [dbo].[spSearchTwitter] 
		@SearchTerm = N'me irl', 
		@NumberOfTweets = N'100',
		@TweetAboutIt = 0;

*/


DECLARE @Rscript nvarchar(max);

SET @Rscript = N'
library(twitteR)
library(httr)

# Make the script somewhat dynamic.
searchTerm <- "' + @SearchTerm + '"

options(httr_oauth_cache = TRUE)

# Set working directory
source("C:/OF/ExploreDarkData/keys.r")

# Authenticate.
setup_twitter_oauth(api_key, api_secret, access_token, access_token_secret)

# Get data.
tweets <- searchTwitter(searchTerm, n = ' + @NumberOfTweets + ')
tweetsOutput <- twListToDF(tweets)
tweetsOutput$SearchTerm <- "' + @SearchTerm + '"

# Let''s tweet about it for fun.
' + CASE 
		WHEN @TweetAboutIt = 1 THEN '' 
		ELSE '#' /* if 0, then the updateStatus() function is commented out. */
		END + 'updateStatus(paste0("I just pulled ", nrow(tweetsOutput), " tweets about ", searchTerm, " for my demo!")) 
';

PRINT @Rscript;

/* Execute the system proc. */
EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @Rscript,
	@output_data_1_name = N'tweetsOutput'

/* Control the data types of your output. */
WITH RESULT SETS ((
    [text] nvarchar(140),
    [favorited] bit,
    [favoriteCount] bigint,
    [replyToSN] nvarchar(140),
    [created] datetime2,
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
))

END


GO


