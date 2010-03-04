"""
a module mainly handle the data which is constructted in tree structure.
"""
from tree import Node	
	
class TreeHandler:
	"""
	A class to construct a list to a tree structure.
	"""
	
	def __init__(self,nodesList, idIndex, parentIndex, rootId=None):
		""" Parameters:
		nodesList - the list to be constructed, each row in the nodesList should hold node's id and node's parent id bascally.
		idIndex -  the index of the node's id in each row in the list
		parentIndex -  the index of the parent node's id in each row in the list
		rootId - the id of the root node, if it's gived, the nodesList holds a root node's info.
		"""
		self.nodesList = nodesList
		self.idIndex = idIndex
		self.parentIndex = parentIndex
		
		# create a root node first, the root node is the tree in fact.
		if rootId:
			self.rootNode = self.make_node(rootId,self.idIndex,self.nodesList)
		else:
			self.rootNode = Node('root')
			self.rootNode.data = []
			
		self.make_tree()
		return
	
	def make_node(self,nodeId):
		"""
		Filters the row from self.nodesList by nodeId,
		and create a new Node.
		After node's creation,the row will be removed from the nodesList.
		"""
		row = filter( lambda i: i[self.idIndex]==nodeId , self.nodesList)[0]
		#print 'make_node,row is %s, node id is %s'%(row,nodeId)
		node = Node(nodeId)
		node.data = row
		self.nodesList.remove(row)		
		return node
		
	def make_tree(self):
		"""
		Constructs the tree by iterating nodesList.
		"""
		while self.nodesList:
			row = self.nodesList.pop(0)
			nodeId = row[self.idIndex]
			#print 'make_tree,row is %s, node id is %s'%(row,nodeId)
			
			try:
				node = self.rootNode.get_child_by_id(nodeId)
			except:
				node = None
			
			if not node:
				node = Node(nodeId)
				node.data = row
				#print 'make_tree,created a new node, id is ',node.id
				parentId = row[self.parentIndex]	
					
				# creates it's parent node and recursivelly creates the ancestor nodes of this node.
				self.parent(parentId, node)
				
				#print '****make_tree is end, maked branch is ******\n',self.rootNode
				#print 70*'-'
		
		return
			
	def parent(self, parentId, child):
		"""
		Recursivelly creates all the ancestor nodes of the child.
		"""
		#print 'parent,parent node id is %s, child node id is %s, root node id is %s'%(parentId,child.id,self.rootNode.id)
		if not parentId:
			parentNode = self.rootNode
		else:
			try:
				parentNode = self.rootNode.get_node_by_id(parentId)
			except:
				parentNode = None
		
		#print 'parent(),parent node is ',parentNode
		
		if parentNode:
			parentNode.append(child)
		else:			
			parentNode = self.make_node(parentId)		
			parentNode.append(child)
			grandpaId = parentNode.data[self.parentIndex]
			
			# recursive constructing this branch in the tree
			self.parent(grandpaId, parentNode)
			
		return
		
	def flatten(self):
		"""
		return the flatten tree nodes and transforming node to node's data
		"""
		l = self.rootNode.flatten()		
		return [item.data for item in l]
		#return l
		
if __name__ == '__main__':
	datalist = \
	[\
		['3.1.1','3.1','3.1.1 level'],\
		['1',None,'1 level'],\
		['1.1.2','1.1','1.1.2 level'],\
		['2',None,'2 level'],\
		['2.1','2','2.1 level'],\
		['2.1.1','2.1','2.1.1 level'],\
		['1.1','1','1.1 level'],\
		['2.1.2','2.1','2.1.2 level'],\
		['3',None,'3 level'],\
		['3.1','3','3.1 level'],\
		['1.1.1','1.1','1.1.1 level'],\
		['3.1.2','3.1','3.1.1 level'],\
	]
	
	tree = TreeHandler(datalist,0,1)
	#print tree.flatten()
	#print tree.nodesList
	print tree.rootNode
