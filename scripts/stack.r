setwd('C:/Users/jacha/Documents/CS145/Yelp/')
source('scripts/training_fcts.r')
source('scripts/error_analysis.r')

library(glmnet)
stars = read.csv('reviews_clean.csv')
stars = c(stars, read.csv('validate_simplified.csv'))

set.seed(999)
train = read.csv('stack.csv')
nr = nrow(train)
test = 
models = c('glm', 'linear', 'xgboost', 'ranger', 'catboost',
           'neural', 'gbm', 'knn', 'user_mean', 'business_mean')
rowsamples = seq(0.4, 1.0, 0.1)
row_number = seq.int(1, nr)

for (m in 2:length(models)) {
  colsamples = 2*(length(models)) - m + 1
  for (n in 1:colsamples) {
    model_subset = sample(models, m)
    for (r in seq(0.4, 1.0, 0.1)) {
      for (k in 1:5) {
        sample_subset = sample(row_number, as.integer(r * nr))
        subtrain = train[sample_subset, model_subset]
        subtest = stars[sample_subset]
        # Run 5-fold CV on this subset with grid search
        # Average and save result
        # Use best combo on stack final.
        
      }
    }
  }
}

test = read.csv('stack_final.csv')
test$knn = NULL
y = trainfuncs$read.csv('reviews_clean.csv')$stars
val = trainfuncs$read.csv('validate_simplified.csv')$stars
y = c(y, val)
model = cv.glmnet(as.matrix(train), y, type.measure="mse")
pred = predict.cv.glmnet(model, as.matrix(test), s='lambda.min')
pred = as.vector(pred)
submit = list(index=seq.int(1,length(pred))-1, stars=pred)
write.csv(submit, 'submit/submit_final_stack_glm2.csv',
          row.names=FALSE, quote=FALSE)
