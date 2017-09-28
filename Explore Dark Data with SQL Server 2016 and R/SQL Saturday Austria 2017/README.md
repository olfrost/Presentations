# Explore Dark Data

The purpose of this repository is to house the code from my recent presentation titled "Explore Dark Data with SQL Server 2016 and R", which uses SQL Server 2016, R, Azure Streaming Analytics, Event Hubs and Power BI to create an end-to-end application for streaming tweets from the Twitter API.

# Prerequisites

You will need to create a Twitter app at https://apps.twitter.com in order to authenticate and pull data from the Twitter API. Some basic instructions and troubleshooting tips can be found here: http://www.consolidata.co.uk/explore/blog/twitterbot-in-r-and-neo4j-part-1/

# Description

This repo contains:

  1. SQL scripts for setting up the database and pulling tweets from the Twitter API.
  2. R scripts to stream tweets and send events to Azure Event Hub.
  3. A SQL query that sits inside Streaming Analytics and processes incoming events.
  
# Environment

I used SQL Server 2016 Developer Edition with SQL Server Management Studio 2016 to build the solution. This uses R version 3.2 as standard, but I would recommend using R version 3.3.0 + with RStudio to test out various R scripts.
