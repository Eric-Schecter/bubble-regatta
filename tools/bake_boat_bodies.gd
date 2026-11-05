extends SceneTree
# Offline bake: identical surfaces and transforms, grouped by material.
# Re-run after changing static boat art: godot --headless --path . --script tools/bake_boat_bodies.gd
func _initialize():call_deferred('run')
func run():
	var art=load('res://scripts/cozy_art.gd').new()
	art.use_baked_boats=false
	var palette=load('res://scripts/game.gd').COLORS
	DirAccess.make_dir_recursive_absolute('res://assets/boats/baked')
	for i in range(1):
		var boat=art.make_boat(i,palette)
		var groups={}
		collect(boat,Transform3D.IDENTITY,groups)
		var expected=0
		for group in groups.values():
			for entry in group:expected+=entry[0].mesh.get_faces().size()
		var merged=ArrayMesh.new()
		var indexed_meshes={}
		for group in groups.values():
			var st=SurfaceTool.new()
			for entry in group:
				var source=entry[0].mesh
				var key=source.get_rid()
				if not indexed_meshes.has(key):
					var indexed=SurfaceTool.new()
					indexed.create_from(source,0)
					indexed.index()
					indexed_meshes[key]=indexed.commit()
				st.append_from(indexed_meshes[key],0,entry[1])
			st.set_material(group[0][0].material_override)
			st.commit(merged)
		assert(merged.get_faces().size()==expected,"Baking must preserve every triangle")
		var err=ResourceSaver.save(merged,'res://assets/boats/baked/body_%d.res'%i,ResourceSaver.FLAG_COMPRESS)
		assert(err==OK)
		print('BAKED BOAT ',i,' surfaces=',merged.get_surface_count())
		boat.free()
	quit()
func collect(node: Node3D,transform_v: Transform3D,groups: Dictionary):
	if node.name=='Captain':return
	if node is MeshInstance3D:
		var key=node.material_override.get_rid()
		if not groups.has(key):groups[key]=[]
		groups[key].append([node,transform_v])
	for child in node.get_children():
		if child is Node3D:collect(child,transform_v*child.transform,groups)
