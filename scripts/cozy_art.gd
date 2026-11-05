extends RefCounted
# Shared toy-art primitives. Geometry is smooth and bevelled in world space.
var materials={}
var meshes={}
var prefabs={}
var use_baked_boats=true
const IVORY=Color('#fff0d1')
const NAVY=Color('#334d70')
const CORAL=Color('#e38c7c')

func mat(c: Color,rough: float=0.72)->StandardMaterial3D:
	var key=str(c)+str(rough)
	if materials.has(key):return materials[key]
	var m=StandardMaterial3D.new()
	m.albedo_color=c
	m.roughness=rough
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	materials[key]=m
	return m

func mesh_node(parent: Node3D,mesh: Mesh,p: Vector3,col: Color)->MeshInstance3D:
	var n=MeshInstance3D.new()
	n.mesh=mesh
	n.position=p
	n.material_override=mat(col)
	parent.add_child(n)
	return n

func sphere(parent: Node3D,p: Vector3,size_v: Vector3,c: Color)->MeshInstance3D:
	if not meshes.has('sphere'):
		var mesh=SphereMesh.new()
		mesh.radius=0.5
		mesh.height=1.0
		mesh.radial_segments=40
		mesh.rings=24
		meshes.sphere=mesh
	var n=mesh_node(parent,meshes.sphere,p,c)
	n.scale=size_v
	n.set_meta("detail_range",detail_distance(size_v))
	return n

func rounded(parent: Node3D,p: Vector3,size_v: Vector3,radius: float,c: Color)->MeshInstance3D:
	var key=str(size_v)+str(radius)
	if not meshes.has(key):
		var st=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var half=size_v*0.5
		var radius_v=minf(radius,minf(half.x,minf(half.y,half.z))*0.95)
		var core=half-Vector3.ONE*radius_v
		for axis in range(3):
			for sign_v in [-1,1]:
				var grid=[]
				for y in range(9):
					for x in range(9):
						var raw=Vector3.ZERO
						raw[axis]=half[axis]*sign_v
						raw[(axis+1)%3]=lerpf(-half[(axis+1)%3],half[(axis+1)%3],float(x)/8)
						raw[(axis+2)%3]=lerpf(-half[(axis+2)%3],half[(axis+2)%3],float(y)/8)
						var near=raw.clamp(-core,core)
						var norm=(raw-near).normalized()
						grid.append([near+norm*radius_v,norm])
				for y in range(8):
					for x in range(8):
						var ids=[y*9+x,y*9+x+1,(y+1)*9+x+1,(y+1)*9+x]
						for j in ([0,2,1,0,3,2] if sign_v>0 else [0,1,2,0,2,3]):
							st.set_normal(grid[ids[j]][1])
							st.add_vertex(grid[ids[j]][0])
		meshes[key]=st.commit()
	var node=mesh_node(parent,meshes[key],p,c)
	node.set_meta("detail_range",detail_distance(size_v))
	return node

func tube(parent: Node3D,pts: Array,radii: Array,c: Color,sides: int=10)->MeshInstance3D:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts=[]
	for i in range(pts.size()):
		var direction: Vector3=(pts[mini(i+1,pts.size()-1)]-pts[maxi(0,i-1)]).normalized()
		var u=direction.cross(Vector3.UP).normalized()
		if u.length()<0.1:u=direction.cross(Vector3.RIGHT).normalized()
		var v=direction.cross(u).normalized()
		for j in range(sides):
			var normal=u*cos(j*TAU/sides)+v*sin(j*TAU/sides)
			verts.append([pts[i]+normal*radii[i],normal])
	for i in range(pts.size()-1):
		for j in range(sides):
			var ids=[i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j]
			for q in [0,2,1,0,3,2]:
				st.set_normal(verts[ids[q]][1])
				st.add_vertex(verts[ids[q]][0])
	return mesh_node(parent,st.commit(),Vector3.ZERO,c)

func torus(parent: Node3D,p: Vector3,r: float,thickness: float,c: Color)->MeshInstance3D:
	var key='torus:'+str(r)+':'+str(thickness)
	if not meshes.has(key):
		var mesh=TorusMesh.new()
		mesh.inner_radius=r-thickness
		mesh.outer_radius=r+thickness
		mesh.rings=32
		mesh.ring_segments=12
		meshes[key]=mesh
	var node=mesh_node(parent,meshes[key],p,c)
	node.set_meta("detail_range",detail_distance(Vector3.ONE*(r+thickness)*2))
	return node

func outline(a: float,scale_v: float=1.0)->Vector3:
	return Vector3(sin(a)*(1.45+0.18*cos(a))*scale_v,0,cos(a)*2.12*scale_v)

func shell(parent: Node3D,col: Color):
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid=[]
	var norms=[]
	for j in range(13):
		var t=float(j)/12*PI*0.5
		for i in range(65):
			var a=float(i)/64*TAU
			var p=outline(a,0.64+sin(t)*0.36)
			p.y=-0.38+(1-cos(t))*1.24
			grid.append(p)
			var radial=Vector3(sin(a)/1.45,0,cos(a)/2.12).normalized()
			norms.append((radial*sin(t)-Vector3.UP*cos(t)*0.30).normalized())
	for j in range(12):
		for i in range(64):
			var ids=[j*65+i,j*65+i+1,(j+1)*65+i+1,(j+1)*65+i]
			var normal: Vector3=norms[ids[0]]+norms[ids[1]]+norms[ids[2]]
			var cross_v: Vector3=(grid[ids[1]]-grid[ids[0]]).cross(grid[ids[2]]-grid[ids[0]])
			var order=[0,2,1,0,3,2] if cross_v.dot(normal)>0 else [0,1,2,0,2,3]
			for q in order:
				st.set_normal(norms[ids[q]])
				st.add_vertex(grid[ids[q]])
	mesh_node(parent,st.commit(),Vector3.ZERO,col)
	# The cockpit rim is one continuous rounded ivory tube, never disconnected pills.
	var pts=[]
	var radii=[]
	for i in range(65):
		var p=outline(float(i)/64*TAU)
		p.y=0.84
		pts.append(p)
		radii.append(0.105)
	tube(parent,pts,radii,IVORY,12)
	sphere(parent,Vector3(0,0.65,0),Vector3(2.58,0.44,3.65),IVORY)
	rounded(parent,Vector3(0,0.88,-1.18),Vector3(2.18,0.22,1.05),0.2,IVORY)
	rounded(parent,Vector3(0,0.85,0.24),Vector3(1.95,0.25,1.75),0.28,Color('#baaa89'))
	rounded(parent,Vector3(0,0.98,0.68),Vector3(1.64,0.40,0.70),0.19,IVORY)
	rounded(parent,Vector3(0,1.06,1.1),Vector3(1.74,0.62,0.25),0.12,IVORY)
	# Swept windshield, pale glass with a thick cream arch.
	var screen=rounded(parent,Vector3(0,1.14,-1.12),Vector3(2.05,0.63,0.12),0.08,Color('#b3deda'))
	screen.rotation.x=-0.20
	var frame=[]
	for i in range(17):
		var a=float(i)/16*PI
		frame.append(Vector3(-cos(a)*1.02,0.96+sin(a)*0.58,-1.19+sin(a)*0.04))
	tube(parent,frame,equal_radii(17,0.062),IVORY)

func equal_radii(n: int,r: float)->Array:
	var arr=[]
	for i in range(n):arr.append(r)
	return arr

func emblem(parent: Node3D,p: Vector3,scale_v: float):
	var badge=Node3D.new()
	badge.position=p
	badge.scale=Vector3.ONE*scale_v
	parent.add_child(badge)
	var r=torus(badge,Vector3(0,0.11,0),0.06,0.017,Color('#f5cf7b'))
	r.rotation.x=PI/2
	tube(badge,[Vector3(0,0.05,0),Vector3(0,-0.16,0)],equal_radii(2,0.019),Color('#f5cf7b'))
	tube(badge,[Vector3(-0.1,-0.02,0),Vector3(0.1,-0.02,0)],equal_radii(2,0.017),Color('#f5cf7b'))
	var arc=[]
	for i in range(13):
		var a=PI*float(i)/12
		arc.append(Vector3(-cos(a)*0.13,-0.04-sin(a)*0.13,0))
	tube(badge,arc,equal_radii(13,0.018),Color('#f5cf7b'))

func make_boat(index: int,palette: Array)->Node3D:
	var boat_root=Node3D.new()
	var body_path='res://assets/boats/baked/body_0.res'
	if use_baked_boats and ResourceLoader.exists(body_path):
		var body=MeshInstance3D.new()
		body.name='BoatBody'
		body.mesh=load(body_path)
		for surface_index in range(body.mesh.get_surface_count()):
			var original=body.mesh.surface_get_material(surface_index)
			if original.albedo_color.is_equal_approx(palette[0]):
				body.set_surface_override_material(surface_index,mat(palette[index],original.roughness))
		boat_root.add_child(body)
		captain(boat_root,index)
		return boat_root
	var col: Color=palette[index]
	shell(boat_root,col)
	# Round cream outboard, navigation lights, cloth fenders and lifebuoys.
	rounded(boat_root,Vector3(0,0.48,2.05),Vector3(0.62,0.84,0.58),0.18,NAVY)
	rounded(boat_root,Vector3(0,0.94,1.95),Vector3(0.88,0.70,0.73),0.20,col)
	rounded(boat_root,Vector3(0,1.17,1.95),Vector3(0.88,0.27,0.73),0.12,IVORY)
	for sign_x in [-1,1]:
		var life=torus(boat_root,Vector3(sign_x*1.47,0.51,0.53),0.36,0.10,IVORY)
		life.rotation.z=PI/2
		for a in [0,PI/2,PI,PI*1.5]:
			var p=Vector3(sign_x*1.48,0.51+sin(a)*0.36,0.53+cos(a)*0.36)
			var stripe=rounded(boat_root,p,Vector3(0.20,0.15,0.15),0.05,col)
			stripe.rotation.x=-a
		for z in [-0.7,1.05]:
			rounded(boat_root,Vector3(sign_x*1.39,0.52,z),Vector3(0.21,0.59,0.24),0.10,IVORY)
			tube(boat_root,[Vector3(sign_x*1.39,0.82,z),Vector3(sign_x*1.43,0.69,z)],equal_radii(2,0.025),Color('#a48b68'))
	captain(boat_root,index)
	return boat_root

func captain(root: Node3D,index: int):
	var c=Node3D.new()
	c.name='Captain'
	root.add_child(c)
	c.set_script(load('res://scripts/captain_motion.gd'))
	c.species=index
	var fur=[Color('#fff2de'),Color('#344e67'),Color('#bf917a'),Color('#eab288'),Color('#9fbcc6'),Color('#fff0df'),Color('#c99c72'),Color('#dcc7a6')][index]
	var cloth=[NAVY,Color('#deb960'),Color('#83ada7'),Color('#ac91bd'),Color('#72b6b0'),Color('#8dbcae'),Color('#a8b5c7'),Color('#c9a78e')][index]
	sphere(c,Vector3(0,1.36,0.16),Vector3(1.18,1.0,0.95),fur)
	var before_head=c.get_children()
	# The head is much larger than the torso, with tiny arms and rounded cheeks.
	sphere(c,Vector3(0,2.39,-0.05),Vector3(1.90,1.65,1.53),fur)
	if index in [0,3,5,6]:
		for sign_x in [-1,1]:
			var size_v=Vector3(0.61,0.65,0.43)
			var pos=Vector3(sign_x*0.73,3.02,-0.02)
			if index==5:size_v=Vector3(0.4,1.2,0.34);pos.y=3.27;pos.x=sign_x*0.54
			if index==3:size_v=Vector3(0.49,0.79,0.42)
			var ear=sphere(c,pos,size_v,fur)
			ear.rotation.z=sign_x*-0.12
			sphere(c,pos+Vector3(0,0,-size_v.z*0.38),size_v*Vector3(0.56,0.66,0.29),Color('#e8aaa3'))
	if index==1:
		sphere(c,Vector3(0,2.22,-0.60),Vector3(1.51,1.25,0.40),IVORY)
	if index==7:
		for x in [-0.40,0.40]:sphere(c,Vector3(x,2.41,-0.64),Vector3(0.82,0.87,0.28),IVORY)
	for sign_x in [-1,1]:
		var x=sign_x*0.36
		var eye_pivot=Node3D.new()
		eye_pivot.position=Vector3(x,2.48,-0.766)
		eye_pivot.set_meta('face_eye',sign_x)
		c.add_child(eye_pivot)
		var eye=sphere(eye_pivot,Vector3.ZERO,Vector3(0.19,0.24,0.12),Color('#493c3a'))
		eye.name='OpenEye'
		var glint=sphere(eye_pivot,Vector3(-0.029,0.05,-0.065),Vector3(0.056,0.066,0.031),Color('#fffdf4'))
		glint.name='Glint'
		var lid_points=[]
		for j in range(13):
			var t=float(j)/12
			lid_points.append(Vector3(lerpf(-0.095,0.095,t),sin(t*PI)*0.018-0.006,-0.075))
		var lid=tube(eye_pivot,lid_points,equal_radii(13,0.012),Color('#493c3a'),8)
		lid.name='ClosedLid'
		lid.hide()
		sphere(c,Vector3(sign_x*0.62,2.20,-0.651),Vector3(0.40,0.21,0.084),Color('#eeafa4'))
		var hand=sphere(c,Vector3(sign_x*0.56,1.45,-0.60),Vector3(0.42,0.43,0.44),fur)
		hand.set_meta('paw_side',sign_x)
	if index not in [1,7]:
		sphere(c,Vector3(-0.17,2.24,-0.79),Vector3(0.53,0.38,0.24),fur.lightened(0.08))
		sphere(c,Vector3(0.17,2.24,-0.79),Vector3(0.53,0.38,0.24),fur.lightened(0.08))
	sphere(c,Vector3(0,2.30,-0.964),Vector3(0.29,0.20,0.18),Color('#e7b65e') if index in [1,7] else Color('#63504a'))
	var mouth=Node3D.new()
	mouth.position=Vector3(0,2.045,-0.80)
	mouth.set_meta('face_mouth',true)
	c.add_child(mouth)
	sphere(mouth,Vector3.ZERO,Vector3(0.35,0.29,0.115),Color('#824b48'))
	sphere(mouth,Vector3(0,-0.053,-0.062),Vector3(0.21,0.10,0.035),Color('#e59793'))
	if index==2:
		for x in [-0.22,0.22]:sphere(c,Vector3(x,2.06,-0.93),Vector3(0.14,0.51,0.14),IVORY)
	if index==6:
		for sign_x in [-1,1]:
			var pts=[Vector3(sign_x*0.64,2.99,0.1),Vector3(sign_x*0.83,3.40,0.1),Vector3(sign_x*0.99,3.58,0.1)]
			tube(c,pts,[0.09,0.07,0.02],Color('#9b7656'))
			tube(c,[pts[1],pts[1]+Vector3(-sign_x*0.22,0.21,0)],[0.065,0.02],Color('#9b7656'))
	var head=Node3D.new()
	head.name='Head'
	head.position=Vector3(0,1.88,0)
	var head_parts=c.get_children().filter(func(n):return not before_head.has(n) and not n.has_meta('paw_side'))
	c.add_child(head)
	for n in head_parts:
		var old=n.position
		n.reparent(head,false)
		n.position=old-head.position
	# Soft sailor collar and a cap with an actual anchor emblem.
	rounded(c,Vector3(0,1.72,0.11),Vector3(1.13,0.15,0.90),0.06,cloth)
	for x in [-0.39,0.39]:
		var lapel=rounded(c,Vector3(x,1.54,-0.30),Vector3(0.32,0.54,0.11),0.05,cloth)
		lapel.rotation.z=-signf(x)*0.45
	tube(c,[Vector3(-0.44,1.69,-0.38),Vector3(0,1.29,-0.40),Vector3(0.44,1.69,-0.38)],equal_radii(3,0.025),IVORY)
	var ribbon=rounded(c,Vector3(0,1.27,-0.43),Vector3(0.19,0.42,0.10),0.04,cloth)
	ribbon.rotation.z=-0.13
	sphere(c,Vector3(0,3.10,0.06),Vector3(1.29,0.45,1.08),cloth)
	rounded(c,Vector3(0,2.985,-0.16),Vector3(1.3,0.14,1.12),0.065,cloth)
	sphere(c,Vector3(0,2.98,-0.63),Vector3(1.10,0.10,0.56),cloth)
	emblem(c,Vector3(0,3.15,-0.48),0.72)
	for n in c.get_children():
		if n!=head and n.position.y>2.8:
			var old=n.position
			n.reparent(head,false)
			n.position=old-head.position
	var torso=Node3D.new()
	torso.name='Torso'
	torso.position=Vector3(0,1.02,0.08)
	var body_parts=c.get_children()
	c.add_child(torso)
	for n in body_parts:
		if n.has_meta('paw_side'):continue
		var old=n.position
		n.reparent(torso,false)
		n.position=old-torso.position
	for sign_x in [-1,1]:
		var arm=Node3D.new()
		arm.name='ArmLeft' if sign_x<0 else 'ArmRight'
		arm.position=Vector3(sign_x*0.64,1.63,-0.36)-torso.position
		torso.add_child(arm)
		for n in c.get_children():
			if n.has_meta('paw_side') and n.get_meta('paw_side')==sign_x:
				var old=n.position
				n.reparent(arm,false)
				n.position=old-torso.position-arm.position
		var sleeve=sphere(torso,arm.position+Vector3(0,-0.1,-0.2),Vector3(0.36,0.40,0.36),fur)
		sleeve.name='SleeveLeft' if sign_x<0 else 'SleeveRight'
	var wheel=torus(c,Vector3(0,1.33,-0.75),0.33,0.044,Color('#9a7958'))
	wheel.rotation.x=PI*0.33
	for a in [0,TAU/3,TAU*2/3]:
		tube(c,[Vector3(0,1.33,-0.75),Vector3(sin(a)*0.31,1.33+cos(a)*0.16,-0.75+cos(a)*0.25)],equal_radii(2,0.025),Color('#9a7958'))
	c.bind_rig()

func mound(root: Node3D,p: Vector3,r: float,height: float,col: Color,seed_v: float):
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grid=[]
	for j in range(10):
		var t=float(j)/9
		for i in range(65):
			var a=float(i)/64*TAU
			var wobble=1+0.035*sin(a*5+seed_v)+0.035*sin(a*3+seed_v*0.7)
			var pos=Vector3(sin(a)*r*t*wobble,height*pow(maxf(0,1-t*t),0.65)-0.05,cos(a)*r*t*0.83*wobble)
			grid.append(pos)
	for j in range(9):
		for i in range(64):
			var ids=[j*65+i,j*65+i+1,(j+1)*65+i+1,(j+1)*65+i]
			for q in [0,1,2,0,2,3]:st.add_vertex(grid[ids[q]])
	st.generate_normals()
	mesh_node(root,st.commit(),p,col)

func island(root: Node3D,p: Vector3,r: float,index: int,with_house: bool=true):
	mound(root,p+Vector3.DOWN*0.15,r*1.08,1.4,Color('#e8cc91'),index)
	mound(root,p+Vector3.UP*0.1,r*0.85,2.0,Color('#9ecb83'),index)
	for j in range(2+index%2):
		var a=float(j)*2.3+index
		palm(root,p+Vector3(sin(a)*r*0.55,1.3,cos(a)*r*0.40),5.2+fposmod(index+j,3))
	if with_house and index%3==0:cottage(root,p+Vector3(0,1.6,0),index)
	for j in range(5):
		var a=j*2.4+index
		var pos=p+Vector3(sin(a)*r*0.89,0.35,cos(a)*r*0.73)
		sphere(root,pos,Vector3(2.3,1.8,1.7),Color('#b6c4aa'))
		if j%2==0:flowers(root,pos+Vector3(0,1.0,0),index+j)
	# Small shore scallops sit at the water line, broken rather than a uniform foam ring.
	for j in range(14):
		var a=j*TAU/14+0.15*sin(index+j)
		var pos=p+Vector3(sin(a)*r*1.07,0.11,cos(a)*r*0.89)
		var patch=sphere(root,pos,Vector3(2.6,0.08,0.55),Color('#d0ebe1'))
		patch.rotation.y=-a

func palm(root: Node3D,p: Vector3,h: float):
	var key='palm:'+str(h)
	if not prefabs.has(key):
		var template=Node3D.new()
		make_palm(template,Vector3.ZERO,h)
		own_template(template,template)
		var packed=PackedScene.new()
		packed.pack(template)
		prefabs[key]=packed
		template.free()
	var instance=prefabs[key].instantiate()
	root.add_child(instance)
	instance.position=p

func make_palm(root: Node3D,p: Vector3,h: float):
	var pts=[]
	for i in range(9):
		var t=float(i)/8
		pts.append(p+Vector3(sin(t*1.7)*0.55,h*t,0))
	tube(root,pts,[0.36,0.34,0.31,0.29,0.27,0.25,0.23,0.22,0.18],Color('#bd9565'),12)
	for i in range(7):
		var a=i*TAU/7
		var leaves=[]
		var radii=[]
		for j in range(13):
			var t=float(j)/12
			leaves.append(pts[-1]+Vector3(sin(a)*t*3.6,sin(t*PI)*0.72-t*t*1.25,cos(a)*t*3.6))
			radii.append(0.03+sin(t*PI)*0.40)
		var leaf=tube(root,leaves,radii,Color('#79b477') if i%2 else Color('#9ac56c'),8)
		# Flattening each curved frond leaves a thick central rib with a tapered tip.
	for x in [-0.30,0.30]:sphere(root,pts[-1]+Vector3(x,-0.45,0),Vector3(0.62,0.70,0.64),Color('#a58658'))

func flowers(root: Node3D,p: Vector3,index: int):
	var key='flowers:'+str(posmod(index,3))
	if not prefabs.has(key):
		var template=Node3D.new()
		make_flowers(template,Vector3.ZERO,index)
		own_template(template,template)
		var packed=PackedScene.new()
		packed.pack(template)
		prefabs[key]=packed
		template.free()
	var instance=prefabs[key].instantiate()
	root.add_child(instance)
	instance.position=p

func make_flowers(root: Node3D,p: Vector3,index: int):
	var colors=[Color('#eea3a0'),Color('#efd270'),Color('#f1baaa')]
	for j in range(3):
		var q=p+Vector3((j-1)*0.39,0,cos(j*2)*0.15)
		sphere(root,q+Vector3(0,-0.20,0),Vector3(0.65,0.35,0.54),Color('#81af75'))
		for i in range(5):
			var a=i*TAU/5
			sphere(root,q+Vector3(cos(a)*0.17,0.08,sin(a)*0.17),Vector3(0.26,0.13,0.26),colors[index%3])
		sphere(root,q+Vector3.UP*0.13,Vector3(0.14,0.14,0.14),Color('#f6d575'))

func cottage(root: Node3D,p: Vector3,index: int):
	var key='cottage:'+str(posmod(index,6))
	if not prefabs.has(key):
		var template=Node3D.new()
		make_cottage(template,Vector3.ZERO,index)
		own_template(template,template)
		var packed=PackedScene.new()
		packed.pack(template)
		prefabs[key]=packed
		template.free()
	var instance=prefabs[key].instantiate()
	root.add_child(instance)
	instance.position=p

func make_cottage(root: Node3D,p: Vector3,index: int):
	var house=Node3D.new()
	house.position=p
	root.add_child(house)
	var roof_cols=[Color('#df9d8e'),Color('#9cc4b1'),Color('#e5c16e')]
	var roof_col=roof_cols[posmod(index,3)]
	rounded(house,Vector3(0,2.0,0),Vector3(5.6,4.0,4.5),0.32,Color('#f8e4be'))
	# Gable wall fills the space beneath the pitched roof.
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in [-2.2,2.2]:
		var tri=[Vector3(-2.75,3.75,z),Vector3(2.75,3.75,z),Vector3(0,5.70,z)]
		for q in ([0,1,2] if z<0 else [0,2,1]):st.add_vertex(tri[q])
	st.generate_normals()
	mesh_node(house,st.commit(),Vector3.ZERO,Color('#f8e4be'))
	for sign_x in [-1,1]:
		var slab=rounded(house,Vector3(sign_x*1.58,4.71,0),Vector3(3.90,0.34,5.7),0.15,roof_col)
		slab.rotation.z=-sign_x*0.52
		for row in range(4):
			for tile in range(6):
				var t=(row+0.5)/4.0
				var x=sign_x*(0.10+t*3.28)
				var y=5.73-t*1.87
				var shingle=rounded(house,Vector3(x,y,-2.34+tile*0.94),Vector3(0.91,0.14,0.88),0.065,roof_col.lightened(0.025 if (row+tile)%2 else 0))
				shingle.rotation.z=-sign_x*0.52
	rounded(house,Vector3(0,5.78,0),Vector3(0.33,0.27,5.73),0.12,roof_col)
	# Layered window frames, shutters, balcony flower boxes.
	for x in [-1.64,1.64]:
		rounded(house,Vector3(x,2.55,-2.29),Vector3(1.34,1.57,0.20),0.14,IVORY)
		rounded(house,Vector3(x,2.55,-2.405),Vector3(1.02,1.23,0.055),0.08,Color('#80b7bd'))
		rounded(house,Vector3(x,2.55,-2.46),Vector3(0.09,1.26,0.07),0.03,IVORY)
		rounded(house,Vector3(x,2.55,-2.46),Vector3(1.07,0.09,0.07),0.03,IVORY)
		for sign_x in [-1,1]:rounded(house,Vector3(x+sign_x*0.81,2.55,-2.30),Vector3(0.27,1.45,0.12),0.05,roof_col)
		rounded(house,Vector3(x,1.58,-2.62),Vector3(1.40,0.30,0.45),0.10,Color('#bd946f'))
		flowers(house,Vector3(x,1.80,-2.64),index)
	rounded(house,Vector3(0,1.32,-2.29),Vector3(1.20,2.65,0.22),0.18,IVORY)
	rounded(house,Vector3(0,1.30,-2.43),Vector3(0.94,2.33,0.13),0.12,roof_col)
	sphere(house,Vector3(0.28,1.20,-2.53),Vector3(0.10,0.10,0.08),Color('#be975c'))
	for i in range(3):rounded(house,Vector3(0,0.1-i*0.13,-2.68-i*0.38),Vector3(1.7+i*0.2,0.24,0.43),0.08,Color('#dcc8a3'))
	# A striped shop awning, visible from the racing waterway.
	if index%2==0:
		for j in range(8):
			var awning=rounded(house,Vector3(-2.36+j*0.67,3.31,-2.99),Vector3(0.67,0.17,1.35),0.06,roof_col if j%2 else IVORY)
			awning.rotation.x=0.16
			sphere(house,Vector3(-2.36+j*0.67,3.06,-3.60),Vector3(0.66,0.38,0.14),roof_col if j%2 else IVORY)
	for face in [0,1,2]:
		var wall=Node3D.new()
		house.add_child(wall)
		if face==0:wall.rotation.y=PI
		elif face==1:wall.rotation.y=PI/2;wall.position.x=0.50
		else:wall.rotation.y=-PI/2;wall.position.x=-0.50
		for x in [-1.4,1.4]:
			rounded(wall,Vector3(x,2.5,-2.29),Vector3(1.18,1.45,0.17),0.12,IVORY)
			rounded(wall,Vector3(x,2.5,-2.40),Vector3(0.9,1.14,0.06),0.07,Color('#80b7bd'))
			rounded(wall,Vector3(x,2.5,-2.46),Vector3(0.08,1.17,0.07),0.02,IVORY)
			rounded(wall,Vector3(x,2.5,-2.46),Vector3(0.93,0.08,0.07),0.02,IVORY)
			rounded(wall,Vector3(x,1.62,-2.58),Vector3(1.30,0.25,0.40),0.07,Color('#bd946f'))
			flowers(wall,Vector3(x,1.83,-2.60),index)
	# Round attic porthole and chimney.
	var window=torus(house,Vector3(0,4.46,-2.26),0.35,0.07,IVORY)
	window.rotation.x=PI/2
	sphere(house,Vector3(0,4.46,-2.25),Vector3(0.57,0.57,0.08),Color('#91b7bd'))
	rounded(house,Vector3(1.7,5.37,1.10),Vector3(0.63,1.55,0.71),0.12,Color('#e6ccb0'))
	rounded(house,Vector3(1.7,6.15,1.10),Vector3(0.79,0.21,0.85),0.08,roof_col)

func lighthouse(root: Node3D,p: Vector3):
	for j in range(5):
		var mesh=CylinderMesh.new()
		mesh.top_radius=2.30-j*0.16
		mesh.bottom_radius=2.46-j*0.16
		mesh.height=1.9
		mesh.radial_segments=48
		mesh_node(root,mesh,p+Vector3.UP*(0.95+j*1.9),Color('#e9a394') if j%2 else IVORY)
		if j in [1,3]:
			rounded(root,p+Vector3(0,1.2+j*1.9,-(2.35-j*0.16)),Vector3(0.77,1.02,0.17),0.18,IVORY)
			rounded(root,p+Vector3(0,1.2+j*1.9,-(2.44-j*0.16)),Vector3(0.49,0.74,0.08),0.12,Color('#91b7bd'))
	var balcony=torus(root,p+Vector3.UP*9.55,2.10,0.17,IVORY)
	for i in range(12):
		var a=i*TAU/12
		rounded(root,p+Vector3(sin(a)*2.1,10.0,cos(a)*2.1),Vector3(0.12,0.85,0.12),0.05,IVORY)
	torus(root,p+Vector3.UP*10.4,2.1,0.10,IVORY)
	var glass=CylinderMesh.new()
	glass.top_radius=1.67
	glass.bottom_radius=1.67
	glass.height=1.5
	glass.radial_segments=32
	mesh_node(root,glass,p+Vector3.UP*10.35,Color('#efd291'))
	for i in range(8):
		var a=i*TAU/8
		rounded(root,p+Vector3(sin(a)*1.73,10.35,cos(a)*1.73),Vector3(0.11,1.6,0.11),0.04,IVORY)
	sphere(root,p+Vector3.UP*11.3,Vector3(4.4,1.25,4.4),CORAL)
	sphere(root,p+Vector3.UP*12.1,Vector3(0.45,0.58,0.45),CORAL)

func pier(root: Node3D,p: Vector3,angle: float,length_v: int=14):
	var dock=Node3D.new()
	dock.position=p
	dock.rotation.y=angle
	root.add_child(dock)
	for i in range(length_v):
		rounded(dock,Vector3(0,0.82,i*0.58),Vector3(4.2,0.25,0.54),0.07,Color('#cda77d') if i%3 else Color('#ddbb91'))
		if i%3==0:
			for x in [-1.8,1.8]:
				rounded(dock,Vector3(x,0.51,i*0.58),Vector3(0.35,2.4,0.35),0.14,Color('#b88f69'))
				sphere(dock,Vector3(x,1.75,i*0.58),Vector3(0.46,0.22,0.46),IVORY)
	for x in [-1.8,1.8]:
		var pts=[]
		for i in range(length_v):pts.append(Vector3(x,1.62-abs(sin(float(i)/3*PI))*0.20,i*0.58))
		tube(dock,pts,equal_radii(pts.size(),0.035),Color('#f0d9aa'))

func buoy(root: Node3D,p: Vector3,index: int):
	var colors=[CORAL,Color('#eac96d'),Color('#93c5ad')]
	var col=colors[posmod(index,3)]
	var group=Node3D.new()
	group.position=p
	root.add_child(group)
	if not meshes.has('buoy_base'):
		var shape=CylinderMesh.new()
		shape.top_radius=.20
		shape.bottom_radius=.62
		shape.height=1.0
		shape.radial_segments=32
		meshes.buoy_base=shape
	var mesh=meshes.buoy_base
	mesh_node(group,mesh,Vector3(0,0.52,0),col)
	if not meshes.has('buoy_band'):
		var shape=CylinderMesh.new()
		shape.top_radius=.35
		shape.bottom_radius=.44
		shape.height=.21
		shape.radial_segments=32
		meshes.buoy_band=shape
	var band=meshes.buoy_band
	mesh_node(group,band,Vector3(0,0.59,0),IVORY)
	torus(group,Vector3(0,0.08,0),0.54,0.10,col)
	if index%3==0:
		rounded(group,Vector3(0,1.33,0),Vector3(0.07,0.82,0.07),0.025,IVORY)
		rounded(group,Vector3(0.25,1.60,0),Vector3(0.51,0.30,0.045),0.02,col)

func collect_static(node: Node,out: Array):
	if node.has_meta('dynamic_art'):return
	if node is MeshInstance3D and node.mesh!=null and node.material_override is StandardMaterial3D:
		out.append(node)
	for child in node.get_children():collect_static(child,out)

func begin_static_plan(root: Node3D)->Dictionary:
	return {'root':root,'stack':[[root,Transform3D.IDENTITY]],'repeated':{},'remaining':{},'groups':[],'cursor':0,'phase':0,'jobs':[],'done':false}

func advance_static_plan(plan: Dictionary,limit: int=300):
	if plan.phase==0:
		for count in range(limit):
			if plan.stack.is_empty():
				plan.groups=plan.repeated.values()
				plan.phase=1
				break
			var entry=plan.stack.pop_back()
			var node=entry[0]
			var transform_v: Transform3D=entry[1]
			if node.has_meta('dynamic_art'):continue
			if node!=plan.root and node is Node3D:transform_v=transform_v*node.transform
			for child in node.get_children():plan.stack.append([child,transform_v])
			if not (node is MeshInstance3D and node.mesh!=null and node.material_override is StandardMaterial3D):continue
			var p=transform_v.origin
			var cell=str(int(floor(p.x/70)))+':'+str(int(floor(p.z/70)))
			var range_end=float(node.get_meta('detail_range',0.0))
			set_detail_visibility(node,range_end)
			var key=str(node.mesh.get_rid())+':'+str(node.material_override.get_rid())+':'+cell+':'+str(range_end)
			if not plan.repeated.has(key):plan.repeated[key]={'nodes':[],'transforms':[],'kind':'instances','range':range_end}
			plan.repeated[key].nodes.append(node)
			plan.repeated[key].transforms.append(transform_v)
	else:
		for count in range(80):
			if plan.cursor>=plan.groups.size():plan.done=true;break
			var group=plan.groups[plan.cursor]
			plan.cursor+=1
			if group.nodes.size()>=2:plan.jobs.append(group)
		# Unique geometry stays as a normal mesh. append_from() reads mesh data back
		# through the active renderer, which was stalling interactive construction.

func static_batch_jobs(root: Node3D)->Array:
	var plan=begin_static_plan(root)
	while not plan.done:advance_static_plan(plan,1000)
	return plan.jobs

func apply_static_batch(root: Node3D,job: Dictionary):
	var group=job.nodes
	var material=group[0].material_override
	var multi=MultiMesh.new()
	multi.transform_format=MultiMesh.TRANSFORM_3D
	multi.mesh=group[0].mesh
	multi.instance_count=group.size()
	var anchor=Vector3.ZERO
	for transform_v in job.transforms:anchor+=transform_v.origin
	anchor/=group.size()
	var buffer=PackedFloat32Array()
	buffer.resize(group.size()*12)
	for i in range(group.size()):
		var t: Transform3D=job.transforms[i]
		t.origin-=anchor
		var values=[t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x,t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y,t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z]
		for j in range(12):buffer[i*12+j]=values[j]
	multi.buffer=buffer
	var instance=MultiMeshInstance3D.new()
	instance.multimesh=multi
	instance.material_override=material
	instance.position=anchor
	set_detail_visibility(instance,job.range)
	root.add_child(instance)
	for node in group:node.free()

func batch_static(root: Node3D):
	for job in static_batch_jobs(root):apply_static_batch(root,job)

func own_template(node: Node,root: Node):
	for child in node.get_children():
		child.owner=root
		own_template(child,root)

func prune_empty_static(node: Node):
	if node.has_meta('dynamic_art'):return
	for child in node.get_children():
		prune_empty_static(child)
		if child is Node3D and not (child is VisualInstance3D) and child.get_child_count()==0 and not child.has_meta('dynamic_art'):child.free()

func detail_distance(size_v: Vector3)->float:
	var extent=maxf(size_v.x,maxf(size_v.y,size_v.z))
	if extent<.50:return 70.0
	if extent<1.25:return 135.0
	if extent<3.0:return 240.0
	return 0.0

func set_detail_visibility(node: GeometryInstance3D,distance: float):
	if distance<=0:return
	node.visibility_range_end=distance
	node.visibility_range_end_margin=distance*.15
	node.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED if OS.has_feature("web") else GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
