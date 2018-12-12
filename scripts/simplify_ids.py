import pandas as pd

uid_map = pd.read_csv('user_id_map.csv')
bid_map = pd.read_csv('business_id_map.csv')

uid = {}
for index, row in uid_map.iterrows():
	uid[row['user_id']] = str(row['uid'])
print("Completed building user id map.")

bid = {}
for index, row in bid_map.iterrows():
	bid[row['business_id']] = str(row['bid'])
print("Completed building business id map.")

def simplify(infile, outfile):
	data = pd.read_csv('{0}.csv'.format(infile))
	for index in range(len(data.index)):
		data.at[index, 'user_id'] = uid[data.at[index, 'user_id']]
		data.at[index, 'business_id'] = bid[data.at[index, 'business_id']]
	data.rename(columns={'user_id': 'uid', 'business_id': 'bid'}, inplace=True)
	data.to_csv('{0}.csv'.format(outfile), index=False)

simplify('train_reviews', 'reviews_simplified')
simplify('validate_queries', 'validate_simplified')
simplify('test_queries', 'test_simplified')