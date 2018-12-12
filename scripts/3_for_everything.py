import pandas as pd
import numpy as np

# Read validation set.
val = pd.read_csv('../validate_queries.csv')

# Get number of samples in validation set.
n_val = len(val.index)

# RMSE formula
def RMSE(y_hat):
	err = val.loc[:, 'stars'] - y_hat
	return np.sqrt((err @ err) / n_val)

# RMSE against each star rating
rmse = []
for i in range(1,6):
	rmse.append(RMSE(i))
d = {'star': np.arange(1,6), 'rmse': rmse}
print("RMSE if you had just guessed the same star rating for everything:")
print(pd.DataFrame(data=d))

# Average given by all users and received by all businesses.
users = pd.read_csv('../users.csv')
business = pd.read_csv('../business.csv')
mean_user_rating = np.mean(users.loc[:, 'average_stars'])
print("\nMean user rating: {0}".format(mean_user_rating))
mean_business_rating = np.mean(business.loc[:, 'stars'])
print("Mean business rating: {0}\n".format(mean_business_rating))

print("RMSE by guessing the mean:")
print("User mean: {0}".format(RMSE(mean_user_rating)))
print("Business mean: {0}\n".format(RMSE(mean_business_rating)))

# Average stars per each user.
average_stars = {}
for i in range(len(users.index)):
	average_stars[users.loc[i, 'user_id']] = users.loc[i, 'average_stars']

# Assign rating based on the average star of the user.
ratings = [average_stars[val.loc[i, 'user_id']] 
						for i in range(len(val.index))]
print("RMSE if we use the average_stars\
 of the user in each prediction:\n  {0}".format(RMSE(ratings)))

# Create submission.
test = pd.read_csv('../test_queries.csv')
ratings = [average_stars[test.loc[i, 'user_id']] 
						for i in range(len(test.index))]
d = {'index': np.arange(len(test.index)), 'stars': ratings}
submit = pd.DataFrame(data = d)
#submit.to_csv('../submission.csv', index = False)