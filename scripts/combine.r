library(glmnet)
library(xgboost)
library(ranger)
library(RcppEigen)
library(h2o)
h2o.init()

setwd('C:/Users/jacha/Documents/CS145/Yelp/')
source('scripts/training_fcts.r')
source('scripts/error_analysis.r')

users = trainfuncs$read.csv('users_clean.csv')
business_onehot = trainfuncs$read.csv('business_onehot.csv')
business_wv = trainfuncs$read.csv('business_wv.csv')
business_cats = trainfuncs$read.csv('business_cats.csv')
train = trainfuncs$read.csv('reviews_clean.csv')
train = train[, c("uid", "bid", "stars")]
val = trainfuncs$read.csv('validate_simplified.csv')
val = rbind(train, val)
test = trainfuncs$read.csv('test_simplified.csv')

models = c('models/glmnet_default.rds',
           'models/linreg_default.rds',
           'models/xgboost_al1.8_co1_et0.05_ga15_la0.1_mi11_su0.95(2).rds',
           'models/ranger_mi40_mt306_respec.rds',
           'models/catboost_de8_l20.000886676190327853.rds',
           'models/aml/DeepLearning_model_R_1544406066476_40',
           'models/aml/GBM_model_R_1544406066476_3')

preds = matrix(nrow = nrow(val), ncol = 10)

# Get predictions for GLM and Linear
business = business_wv
val_lm = trainfuncs$join_sets(val, split=TRUE)
val_lm$X$compliment_cool = NULL
model = readRDS(models[1])
pred = predict.cv.glmnet(model, as.matrix(val_lm$X), s='lambda.min')
preds[,1] = pred
model = readRDS(models[2])
pred = as.matrix(val_lm$X) %*% coef(model)
preds[,2] = pred

# Get prediction for XGBoost
business = business_onehot
val_oh = trainfuncs$join_sets(val, split=TRUE)
val_oh = xgb.DMatrix(as.matrix(val_oh$X), label=val_oh$y) 
model = readRDS(models[3])
pred = predict(model, val_oh)
preds[,3] = pred

# Get predictions for ranger
business = business_cats
val_r = trainfuncs$join_sets(val, split=TRUE)
model = readRDS(models[4])
pred = predict(model, val_r$X)$predictions
preds[,4] = pred

# Get predictions for Catboost (must be done in Linux)
model = readRDS(models[5])
val_r = catboost.load_pool(data = val_r$X, label = val_r$y)
pred = catboost.predict(model, val_r)
preds[,5] = pred

# Import Catboost predictions
pred = read.csv('cb_pred.csv')[[1]]
preds[,5] = pred

# Get predictions for H2O models
business = business_onehot
val_oh = trainfuncs$join_sets(val, split=TRUE)
val_oh$X = as.h2o(val_oh$X)
val_oh$X = val_oh$X[-1,]
model = h2o.loadModel(models[6])
pred = h2o.predict(model, val_oh$X)
pred = as.vector(pred)
preds[,6] = pred
model = h2o.loadModel(models[7])
pred = h2o.predict(model, val_oh$X)
pred = as.vector(pred)
preds[,7] = pred

# Get prediction from knn
pred = read.csv('knn_23_wv_preds.csv')$pred
preds[,8] = pred

# Get predictions from averages
users = read.csv('users_simplified.csv')
val_oh = trainfuncs$join_sets(val, split = TRUE)
pred = val_oh$X$average_stars
preds[,9] = pred
pred = val_oh$X$business_stars
preds[,10] = pred

preds = as.data.frame(preds)
names(preds) = c('glm', 'linear', 'xgboost', 'ranger', 'catboost',
                 'neural', 'gbm', 'knn', 'user_mean', 'business_mean')

write.csv(preds, 'stack.csv', row.names = FALSE)
