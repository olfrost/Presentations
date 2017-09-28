USE worldcities
GO

/*

Author: Ollie Frost
Created: 05-09-2017
Description: An example of Python inside SQL Server 2017.

Reading: 
	https://www.sqlshack.com/how-to-use-python-in-sql-server-2017-to-obtain-advanced-data-analytics/
	https://blogs.technet.microsoft.com/dataplatforminsider/2017/04/19/python-in-sql-server-2017-enhanced-in-database-machine-learning/

Relevant YouTube video:
	https://www.youtube.com/watch?v=FcoY795jTcc

*/

/* Can be configured in the same way that R services can. */

EXECUTE sp_configure 'external scripts enabled', 1;
RECONFIGURE;

/* Restart the instance and check that it has been configured. */

EXECUTE sp_configure

/* Declare an nvarchar(max) variable with your Python script. */

DECLARE @pythonscript nvarchar(max);

-- be careful of spaces versus tabs
SET @pythonscript = N'
from numpy import median

class oc:

    @staticmethod
    def medianstuff(x):
        return(median(x))

    @staticmethod
    def distinctvalues(x):
        return(len(set(x))) 

df = InputDataSet
row_count = df.count()
output = pandas.DataFrame(data = {"A":df.apply(oc.medianstuff), "B":row_count, "C":df.apply(oc.distinctvalues)})'

/* Execute system stored proc. */

EXECUTE sp_execute_external_script
	@language = N'Python',
	@script = @pythonscript,
	-- supports a wide range of data types, but not NUMERIC here. FLOAT used instead.
	@input_data_1 = N'SELECT CAST(Latitude AS FLOAT) as Latitude FROM worldcitiestest',
	@output_data_1_name = N'output'

WITH RESULT SETS ((
	ColumnMedian NUMERIC(10,4)
,	RowsCount int
,	UniqueValues bigint
));
