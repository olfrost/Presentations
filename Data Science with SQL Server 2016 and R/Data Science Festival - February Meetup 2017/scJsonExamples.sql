/*
Author: Ollie Frost
Created: 21 Feb 2017
Description: Some examples of JSON support inside SQL Server 2016.

More information: https://blogs.msdn.microsoft.com/jocapc/2015/05/16/json-support-in-sql-server-2016/

*/

	/* Create some very simple JSON. */
	DECLARE @JSON nvarchar(max) = (
		SELECT
			'github/olfrost' as [GitHub], '@OFrost' as [Twitter],
			'@ConsolidataLtd' as [BetterTwitter], 'olliefrost' as [LinkedIn]
		FOR
			JSON PATH )

	PRINT @JSON;

/*
[
	{
		"GitHub":"github\/olfrost",
		"Twitter":"@OFrost",
		"BetterTwitter":"@ConsolidataLtd",
		"LinkedIn":"olliefrost"
	}
]
*/

	/* Table to JSON. */
	SELECT TOP 5
		[Hack_License],
		[Passenger_Count],
		[Fare_Amount]
	FROM
		[dbo].[nyctaxi_sample]
	FOR
		JSON AUTO;

/*
[
	{"Hack_License":"79C37DA10EA88D6B467F9FA2B29F8006","Passenger_Count":1,"Fare_Amount":5.500000000000000e+000},
	{"Hack_License":"59A32B69453C9E2EAAFC4C822A914DC9","Passenger_Count":1,"Fare_Amount":5.500000000000000e+000},
	{"Hack_License":"3BD04BB028B2145779C0D3F6DD42ACD6","Passenger_Count":1,"Fare_Amount":5.500000000000000e+000},
	{"Hack_License":"7D2921FDCC869190E736D3B731C66DC5","Passenger_Count":1,"Fare_Amount":5.500000000000000e+000},
	{"Hack_License":"0B071535952183F132EB38B643E2252E","Passenger_Count":1,"Fare_Amount":5.500000000000000e+000}
]
*/

	/* JSON to tables. */	
	DECLARE @JsonLarge nvarchar(max);
	SET @JsonLarge = '{"OrdersArray": [
   {"Number":1, "Date": "8/10/2012", "Customer": "Adventure works", "Quantity": 1200},
   {"Number":4, "Date": "5/11/2012", "Customer": "Adventure works", "Quantity": 100},
   {"Number":6, "Date": "1/3/2012", "Customer": "Adventure works", "Quantity": 250},
   {"Number":8, "Date": "12/7/2012", "Customer": "Adventure works", "Quantity": 2200}
	]}'; -- convert some data from an AdventureWorks query to a JSON structure.
			
	PRINT @JsonLarge; -- proof.

	SELECT
		*
	FROM
		OPENJSON(@JsonLarge, '$.OrdersArray')
	WITH (
        Number int, Quantity int
	) AS OrdersArray
	
		 