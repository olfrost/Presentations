/*

Author: Ollie Frost
Date: 21-10-2017
Description: Create a decision tree with RevoScaleR.

*/

DECLARE @rscript nvarchar(max);

SET @rscript = N'
library(RevoScaleR)
library(data.table)
library(RevoTreeView)

# Read in data. ----
df <- RxTextData("C:/OF/Mushroom/mushrooms.csv", stringsAsFactors = TRUE)
mushrooms <- rxDataStep(df)

# Tidy the data.
names(mushrooms) <- gsub("-", "", names(mushrooms))

# Perform a summary.
summ <- rxGetInfo(~., mushrooms)
print(summ$sDataFrame)

# Split up into training and test data.
train_ind <- sample(1:nrow(mushrooms), 6543)

train <- mushrooms[row.names(mushrooms) %in% train_ind,]
test <- mushrooms[!(row.names(mushrooms) %in% train_ind),]

# Build a model.
model <- rxDTree(
  formula = class ~ capshape + capsurface + capcolor + bruises + odor + gillattachment + 
    gillspacing + gillsize + gillcolor + stalkshape + stalkroot + stalksurfaceabovering + 
    stalksurfacebelowring + stalkcolorabovering + stalkcolorbelowring + veiltype + veilcolor + 
    ringnumber + ringtype + sporeprintcolor + population + habitat, 
  data = train
)

# Make predictions.
predictions <- rxPredict(model, test)

# Clean up and present.
predictions$orig <- test$class;
predictions$prediction <- ifelse(predictions[1] < predictions[2], "e", "p")
predictions$correct <- ifelse(predictions$prediction == predictions$orig, "Yes", "No")

output <- data.frame(table(predictions$correct))

#plot(createTreeView(model))'

EXECUTE sp_execute_external_script
	@language = N'R',
	@script = @rscript,
	@output_data_1_name = N'output'
