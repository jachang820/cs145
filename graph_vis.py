from lightning import Lightning
import networkx as nx
from networkx.algorithms import approximation
import numpy as np
import pandas as pd

friends = pd.read_csv('friends.csv')
num_users = len(friends.index)


G = nx.Graph()
def generate_edges(G, friends):
	for index, user in friends.iterrows():
		if not pd.isnull(user['friends']):
			G.add_node(int(user['uid']))
			friend_list = user['friends'].split(',')
			for friend in friend_list:
				G.add_node(int(friend))
				G.add_edge(user['uid'], int(friend))

generate_edges(G, friends)
total = G.number_of_nodes()
max_cover = nx.algorithms.components.node_connected_component(G, 12990)
mc_str = [str(uid) for uid in max_cover]

open('max_cover.csv', 'w').writelines(",".join(mc_str))

print(num_users)
print(total)
print(len(max_cover))
print(len(max_cover) / total)

G.remove_nodes_from(max_cover)
largest_cc = max(nx.connected_components(G), key=len)
print(largest_cc)

mean_cc = np.mean([len(c) for c in nx.connected_components(G)])
print(mean_cc)

# lgn = Lightning(local=True)
# lgn.set_size(size='full')

# mat = nx.adjacency_matrix(G).todense()
# viz = lgn.force(mat)
# viz.save_html('force.html')

