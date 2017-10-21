USE mushrooms
GO

/*

Author: Ollie Frost
Date: 21-10-2017
Description: A decision tree example in Python.

Reading:
    https://docs.microsoft.com/en-us/sql/advanced-analytics/python/what-is-revoscalepy
	https://docs.microsoft.com/en-us/r-server/python-reference/microsoftml/rx-predict
*/

/* Create some data. */
IF OBJECT_ID('dbo.iris', N'U') IS NOT NULL
	DROP TABLE dbo.iris;

CREATE TABLE dbo.iris (
	FlowerId INT IDENTITY(1,1),
	SepalLength FLOAT,
	SepalWidth  FLOAT,
	PetalLength FLOAT,
	PetalWidth  FLOAT,
	Species VARCHAR(20)
);

INSERT INTO dbo.iris
EXECUTE sp_execute_external_script
	@language = N'R',
	@script = N'df <- iris',
	@output_data_1_name = N'df'

/* Begin the Python script. */ 
DECLARE @pythonscript nvarchar(max);

SET @pythonscript = N'
from revoscalepy import rx_lin_mod, rx_summary, rx_predict

# Split up training and test data sets.
train = df.sample(frac = 0.8, random_state = 200)
test = df.drop(train.index)

# Perform a summary.
print(rx_summary(" ~ .", data = df))

# Linear regression.
model = rx_lin_mod("SepalLength ~ SepalWidth + PetalWidth + PetalLength", data = train)

# Predict results
predict = rx_predict(model, data = test, extra_vars_to_write=["FlowerId", "SepalLength"])'

EXECUTE sp_execute_external_script
	@language = N'Python',
	@script = @pythonscript,
	@input_data_1 = N'SELECT * FROM dbo.iris',
	@input_data_1_name = N'df',
	@output_data_1_name = N'predict'

WITH RESULT SETS ((
	Prediction DECIMAL(10,4),
	FlowerId INT,
	SepalLength DECIMAL(4,1)
));
