setwd(YOUR_ROOT_DIR)
source('scripts/error_analysis.r')
source('scripts/training_fcts.r')
BUCKET_NAME = YOUR_S3_BUCKET

# Run these commands on AWS instance
users = trainfuncs$read.csv('users_clean.csv')
business = trainfuncs$read.csv('business_cats.csv')
test = trainfuncs$read.csv('test_simplified.csv')
test = trainfuncs$join_sets(test, split = FALSE)
test = catboost.load_pool(data = test)
cat_model = readRDS('models/catboost_de8_l20.000886676190327853(3).rds')
pred = catboost.predict(cat_model, test)
submit = data.frame(index = seq.int(length(pred)) - 1, 
                    stars = pred)
write.csv(submit, 'catmodel.csv', row.names = FALSE, quote = FALSE)

# Run the following in your local Windows machine
library(h2o)
h2o.init()
users = trainfuncs$read.csv('users_clean.csv')
business = trainfuncs$read.csv('business_cats.csv')
test = trainfuncs$read.csv('test_simplified.csv')
test = trainfuncs$join_sets(test, split = FALSE)
gbm_model = h2o.loadModel('models/StackedEnsemble_BestOfFamily_AutoML_20181202_021954')
pred = h2o.predict(gbm, as.h2o(test))
pred = as.vector(pred)
submit = data.frame(index = seq.int(length(pred)) - 1, 
                    stars = pred)
write.csv(submit, 'gbmmodel.csv', row.names = FALSE, quote = FALSE)

# Download your catboost submission to root dir, then
cat_model = trainfuncs$read.csv('catmodel.csv')$stars
gbm_model = trainfuncs$read.csv('gbmmodel.csv')$stars
pred = (cat_model + gbm_model) / 2
submit = data.frame(index = seq.int(length(pred)) - 1, 
                    stars = pred)
write.csv(submit, 'finalmodel.csv', row.names = FALSE, quote = FALSE)