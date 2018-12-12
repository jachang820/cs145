import pandas as pd

friends = pd.read_csv('../friends.csv').loc[:, "friends"]

def ratings_count(friends, freqs, limit=None):
	hash = {}
	
	# Create O(1) hash of frequencies, 
	# since pandas is O(n)
	for index, freq in freqs.iterrows():
		hash[str(freq['uid'])] = int(freq['n'])

	count = 0
	for friend in friends:
		if not pd.isnull(friend):
			f_list = friend.split(', ')

			# Limit friends per user
			if limit is not None:
				f_list = f_list[0:limit]

			# Count friends
			for uid in f_list:
				if uid in hash:
					count += hash[uid]

	return count

def report(limit=None):
	train_count = ratings_count(friends, pd.read_csv('../train_freq.csv'), limit)
	val_count = ratings_count(friends, pd.read_csv('../val_freq.csv'), limit)

	if limit is None:
		preface = "Considering all friends"
	else:
		preface = "If we limit each user to {0} friends".format(limit)

	out = "{0}, there will be {1} and {2}".format(preface, train_count, val_count)
	out = "{0} from training and validation, respectively.".format(out)
	print(out)

report()
report(3)
report(5)
report(10)
