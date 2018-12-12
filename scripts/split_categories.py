import pandas as pd
import numpy as np

# Determine headers.
categories = pd.read_csv('../cat_freq.csv').loc[:, "categories"]
categories = list(categories)

# Determine rows and create new dataframe.
business = pd.read_csv('../business_preclean1.csv')
nrow = len(business.index)
df = pd.DataFrame(0, index=np.arange(nrow), columns=categories, dtype='int64')

# Iterate businesses and count their categories.
for index, row in business.iterrows():
	if not pd.isnull(row['categories']):
		cat_list = row['categories'].split(', ')
		for cat in cat_list:
			df.loc[index, cat] += 1
	if index % 5000 == 0:
		print("Processing row {0}...".format(index))

# Change column names so they are more easily identifiable
cat_dict = {}
for cat in categories:
	new_cat = cat.replace(' ', '')
	new_cat = new_cat.replace('&', '')
	new_cat = new_cat.replace('/', '')
	new_cat = new_cat.replace('(', '')
	new_cat = new_cat.replace(')', '')
	new_cat = new_cat.replace("'", '')
	new_cat = new_cat.replace('-', '')
	new_cat = "cat_{0}".format(new_cat)
	cat_dict[cat] = new_cat
df = df.rename(index=str, columns=cat_dict)

# Save the result.
df.to_csv('../catframe.csv', index=False)
print("Completed!")
