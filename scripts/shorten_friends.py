import pandas as pd

uid_map = pd.read_csv('user_id_map.csv')
hash = {}
for index, row in uid_map.iterrows():
	hash[row['user_id']] = str(row['uid'])
print("Completed building map.")

data = pd.read_csv('users.csv')
friends_list = data['friends'].values
for index, friends in enumerate(friends_list):
	if friends != "None":
		friends = friends.split(', ')
		length = len(friends)
		f_new = []
		for i in range(length):
			try:
				if friends[i] in hash:
					f_new.append(hash[friends[i]])
			except:
				print("Error on...\nFriends: {0}\nIndex: {1}".format(friends, i))
				exit()
		if len(f_new) == 0:
			data.at[index, 'friends'] = "None"
		else:
			data.at[index, 'friends'] = ', '.join(f_new)

	if index % 1000 == 0:
		print("On row {0}...".format(index))
data.to_csv('users_simplified.csv', index=False)