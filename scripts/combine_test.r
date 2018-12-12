library(glmnet)
library(xgboost)
library(ranger)
library(RcppEigen)
library(h2o)
h2o.init()

setwd('C:/Users/jacha/Documents/CS145/Yelp/')
source('scripts/training_fcts.r')
source('scripts/error_analysis.r')

preds = matrix(nrow = 50078, ncol = 10)

submits = c('submit_glmnet_lalambda.min.csv',
            'submit_linreg_default.csv',
            'submit__final_1.8_1_0.1_15_0.1_11_0.95(5).csv',
            'submit_ranger_final_40_306_respec.csv',
            'submit_catboost_final_de8_l20.000886676190327853(2).csv',
            'submit_final_nn_hi10x4_acRe.csv',
            'submit_final_gbm_nt260.csv',
            'submit_knn_wv_final_k23.csv',
            'submit_final_user_mean.csv',
            'submit_final_business_mean.csv')

for (i in 1:length(submits)) {
  fname = paste('submit/', submits[i], sep='')
  preds[,i] = read.csv(fname)$stars
}

preds = as.data.frame(preds)
names(preds) = c('glm', 'linear', 'xgboost', 'ranger', 'catboost',
                 'neural', 'gbm', 'knn', 'user_mean', 'business_mean')

write.csv(preds, 'stack_final.csv', row.names = FALSE)
