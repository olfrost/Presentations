#### Author: Ollie Frost
#### Created: 12-05-2016
#### Description: Live stream tweets.

library(streamR) # install.packages(c("streamR","dplyr", ROAuth","RJSONIO","httr","tm","slam","sqldf"))
library(ROAuth) 
library(RJSONIO) 
library(httr)
library(tm)
library(slam)
library(sqldf)
library(dplyr)

#### Make script dynamic -----------------------------------------------------

# What shall we search?
searchString <- "trump"

# How long shall we stream to Power BI for?
timeoutSecs <- 1200 

# Authenticate using the streamR package by creating an R Workspace file.
# Follow the steps in this blog: https://github.com/pablobarbera/streamR
load("/path/to/file/my_oauth.Rdata")

# Specify our Service Bus namespaces and Event Hub names.
namespace <- "Namespace-NS"
eventHub <- "EventHubsName"

# Generate an access token from https://github.com/sandrinodimattia/RedDog/releases/tag/0.2.0.1
sas <- "SharedAccessSignature"


#### Create functions ------------------------------------------------------------
getTweets <- function(x){
    
    # Get data
    data <- filterStream(file.name = "",
             track = searchString, 
             language = "en",
             timeout = 6,
             oauth = my_oauth) 
    
    # Parse the JSON this data arrives in.
    tweets <- try(parseTweets(data), silent = TRUE)
    
    # If no tweets, return "", otherwise split out the text from each tweet and combine.
    if(is(tweets,"try-error")){
      
      json <- ""
      
    } else {
      
    tweets <- select(tweets, 1)
    words <- unlist(strsplit(tweets$text, " "))
    
    words <- Corpus(VectorSource(words))
    
    # Apply some text manipulation techniques and filter out the interesting words.
    words <- tm_map(words, removeNumbers)
    words <- tm_map(words, removePunctuation)
    words <- tm_map(words, tolower)
    words <- tm_map(words, removeWords, c("rt")) 
    words <- tm_map(words, stripWhitespace)
    words <- tm_map(words, removeWords, stopwords("english")) 
    words <- tm_map(words, PlainTextDocument)
    
    dtm <- DocumentTermMatrix(words)
    colTotals <- col_sums(dtm)
    
    # Get a count of these words
    final <- data.frame(
      word = names(colTotals), 
      Freq = colTotals
    )
    
    # Get the most frequently used words.
    df <- sqldf("SELECT * FROM final WHERE word <> 'amp' AND Freq >= 3;")
    
    # Output as JSON where the data is contained in arrays.
    json <- toJSON(df)
    
    }
    
    return(json)
 
}

# A function to send a POST request to Event Hubs.
sendTweetTo <- function(body, sas){
  
  # If no tweets were parsed, don't send a POST request.
  if(body == ""){
    
    print("No POST request sent due to API limit being reached.")
    
  } else {

  POST(
    url = paste0("https://", namespace, ".servicebus.windows.net/", eventHub, "/publishers/manage/messages"), 
    add_headers(
      Authorization = sas,
      `Content-Type` = "application/atom+xml;type=entry;charset=utf-8",
      Host = paste0(namespace, ".servicebus.windows.net")
    ),
    
    # Attach your new JSON.
    body = body
  )
    
  }
  
}

#### For x seconds, run both functions. -------------------------------------

# Get the current time and add 30 seconds
nowPlus30 <- as.numeric(Sys.time()) + timeoutSecs

# Run a while which retrieves a tweet via the live stream, sends it via a HTTP request, and repeats for 30s.
while(as.numeric(Sys.time()) < nowPlus30) {
  
  # Get tweets
  tweetsToPost <- getTweets()
  
  # Send the POST request.
  sendTweetTo(body = tweetsToPost, sas = sas)
  
}




