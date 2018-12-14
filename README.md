# Prediction of Yelp Reviews

## Final Results

Note that the easiest way to get something close to the final results of the class competition is to just run the *final_model.r* file under the *Scripts/* directory. Note that the script uses a slightly inferior model for the stacked GBM. The better one is 39MB, which might not have fit in the submission. If the exact score is to be reproduced, then please use *StackedEnsemble_AllModels_AutoML_20181202_021954* file instead of *StackedEnsemble_BestOfFamily_AutoML_20181202_021954*, both under the *Models/* directory.

## Dependencies

The code requires (R 3.5.1)[https://cran.r-project.org/bin/windows/base/] and preferably (RStudio)[https://www.rstudio.com/products/rstudio/download/] to run. Parts of it are also written in **Python 3.7**. There are numerous package dependences in **R**. Please run the following before anything else.

```{r}
install.packages('dplyr')              # Dataframe manipulation
install.packages('caret')              # Creates one-hot encodings
install.packages('ranger')             # Random forest 
install.packages('xgboost')            # XGBoost
install.packages('catboost')           # CatBoost
install.packages('h2o')                # GBM, neural networks, AutoML
install.packages('class')              # KNN
install.packages('RcppEigen')          # Linear regression
install.packages('glmnet')             # Regularized GLM
install.packages('ggplot2')            # Graphing
install.packages('aws.ec2metadata')    # Checking if AWS instance
install.packages('aws.s3')             # Getting files from AWS S3
```

There may be other packages. RStudio will prompt any dependencies to be downloaded.

The CatBoost library in R may not install on a Windows machine. In that case, an Amazon Image (AMI) was used with RStudio pre-installed obtained from Louis Aslett's (website)[http://www.louisaslett.com/RStudio_AMI/]. The particular image I used is (here)[https://console.aws.amazon.com/ec2/home?region=eu-west-1#launchAmi=ami-003a0987ccad642ec]. The general process in getting an EC2 instance running is detailed (here)[https://aws.amazon.com/blogs/big-data/running-r-on-aws/].

## Description

This was a class project for CS145. We were given Yelp datasets, which were a subset of the one on Kaggle. The datasets included user information, business information, and users' ratings of businesses in a given train, validation and test set. My final score was **1.03968** RMSE, first on public and private boards. The vast majority of the time was spent grid searching hyperparameters and setting up some code to make the training process neater. On the public board, simply using the users's *average_stars* field as a prediction yielded **1.13383**. The code could have been written in less than 20 lines:

```python

import pandas as pd
import numpy as np

# Read validation set.
val = pd.read_csv('validate_queries.csv')

# Average stars per each user.
average_stars = {}
for i in range(len(users.index)):
	average_stars[users.loc[i, 'user_id']] = users.loc[i, 'average_stars']

# Assign rating based on the average star of the user.
ratings = [average_stars[val.loc[i, 'user_id']] for i in range(len(val.index))]

# Predict on test and create submission.
test = pd.read_csv('test_queries.csv')
ratings = [average_stars[test.loc[i, 'user_id']] for i in range(len(test.index))]
d = {'index': np.arange(len(test.index)), 'stars': ratings}
submit = pd.DataFrame(data = d)
submit.to_csv('submission.csv', index = False)

```
Using a weighted mean of *average_stars* and businesses' *stars* field yielded **1.07687**. A simple search for the weights is shown below using a *ggplot*.

[logo]: https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/weighted.png "Weighted Mean"

With that as the reference, the rest of the distance is just chasing after minutiae. 

## The Journey

I kept a running documentation of my entire process, including some false starts. The following were created from R Markdown, which are basically Markdown scripts along with R and Python code. The original files are the *.rmd* files under the *Scripts/* directory, and can be run similar to Jupyter notebooks in RStudio. The following are outputs using Knit into html.

(Test Completeness of Reviews)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/test_reviews_completeness.html]

(Mean Modeling)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/mean_modeling.html]

(Simplifying IDs)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/simplifying_ids.html]

(Factor Review Set)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/factor_review_set.html]

(Clean Up Users)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/clean_up_users.html]

(Cleaning Business: Opening Hours (Part 1))[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/opening_hours.html]

(Cleaning Business: PCA With Categories (Part 2))[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/pca_with_categories.html]

(Cleaning Business: Attribute Objects (Part 3))[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/attribute_objects.html]

(Cleaning Business: Postal Codes and Neighborhoods (Part 4))[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/zips_and_hoods.html]

(Cleaning Business: Second Attempt at Feature Reduction (Part 5))[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/category2vec.html]

(Error Analysis)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/error_analysis.html]

(Streamline Training)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/streamline_training.html]

(Random Forest: That Was Random!)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/random_forest.html]

(XGBoost: So Extreme!)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/xgboost.html]

(CatBoost)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/catboost.html]

(H2O AutoML)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/automl.html]

(k-Nearest Neighbors)[https://s3-us-west-2.amazonaws.com/jchang-rstudio/html/clustering.html]


## The Group

It's just me, 
**Jonathan Chang** - [jachang820](https://github.com/jachang820)

Team name: *Omae wa mou shindeiru*

