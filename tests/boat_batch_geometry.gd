extends SceneTree
func _initialize():
	var art=load('res://scripts/cozy_art.gd').new()
	art.use_baked_boats=false
	var original=art.make_boat(0,load('res://scripts/game.gd').COLORS)
	var expected=count_faces(original)
	var baked=load('res://assets/boats/baked/body_0.res')
	var actual=baked.get_faces().size()
	print('BAKE triangles original=',expected/3,' merged=',actual/3)
	assert(expected==actual,'Static boat geometry must be preserved exactly')
	original.free()
	quit()
func count_faces(node: Node)->int:
	if node.name=='Captain':return 0
	var total=node.mesh.get_faces().size() if node is MeshInstance3D else 0
	for child in node.get_children():total+=count_faces(child)
	return total
