extends RefCounted
# Toy-like, shape-coded course features; positions use the same race coordinates as boats.
var hazards=[]
var shells=[]
var pads=[]
var ramps=[]
const CREAM=Color('#fff3d9')
const CORAL=Color('#e78878')
const MINT=Color('#63c7ad')

func group(g,root,s: float,lane: float)->Node3D:
	var node=Node3D.new()
	node.set_meta('dynamic_art',true)
	root.add_child(node)
	g.place(node,s,lane)
	return node

func gift(g,root,s: float,lane: float):
	var node=group(g,root,s,lane)
	var a=g.art
	a.rounded(node,Vector3(0,1.1,0),Vector3(1.5,1.25,1.5),.18,Color('#f0baad'))
	a.rounded(node,Vector3(0,1.77,0),Vector3(1.65,.24,1.65),.08,CREAM)
	for size in [Vector3(.24,1.5,1.67),Vector3(1.67,1.5,.24)]:a.rounded(node,Vector3(0,1.15,0),size,.05,Color('#e8b951'))
	for side in [-1,1]:
		var bow=a.torus(node,Vector3(side*.29,2.02,0),.24,.075,Color('#e8b951'))
		bow.rotation=Vector3(PI/2,side*.5,0)
	a.sphere(node,Vector3(0,2,0),Vector3(.22,.22,.22),CORAL)
	g.boxes.append({'node':node,'s':s,'lane':lane,'taken_lap':-1})

func shell(g,root,s: float,lane: float):
	var node=group(g,root,s,lane)
	var a=g.art
	a.sphere(node,Vector3(0,.91,0),Vector3(1.1,.85,.32),Color('#f2c568'))
	for i in range(5):
		a.sphere(node,Vector3((i-2)*.20,1.27-absf(i-2)*.08,0),Vector3(.30,.30,.30),Color('#f2c568'))
	for i in range(5):
		var x=(i-2)*.17
		for side in [-1,1]:
			a.tube(node,[Vector3(x*.3,.45,side*.19),Vector3(x,.90,side*.22),Vector3(x*.85,1.19,side*.17)],a.equal_radii(3,.035),CREAM,6)
	a.sphere(node,Vector3(0,.46,-.04),Vector3(.55,.23,.4),Color('#e7ae59'))
	shells.append({'node':node,'s':s,'lane':lane,'taken_lap':-1})

func warning(g,node):
	g.art.rounded(node,Vector3(0,1.6,0),Vector3(.12,1.4,.12),.04,CREAM)
	g.art.rounded(node,Vector3(0,2.2,0),Vector3(.9,.85,.15),.12,CORAL)
	for side in [-1,1]:
		g.art.rounded(node,Vector3(0,2.34,side*.12),Vector3(.10,.31,.08),.03,CREAM)
		g.art.sphere(node,Vector3(0,2.02,side*.12),Vector3(.12,.12,.08),CREAM)

func hazard(g,root,s: float,lane: float,kind: String):
	var node=group(g,root,s,lane)
	var a=g.art
	if kind=='rock':
		for i in range(3):
			a.sphere(node,Vector3((i-1)*.85,.30+float(i%2)*.2,0),Vector3(1.9,1.7-float(i%2)*.2,2.0),Color('#91a3aa'))
		a.sphere(node,Vector3(-.45,.95,-.35),Vector3(.8,.45,.45),Color('#f0ad92'))
	elif kind=='log':
		a.rounded(node,Vector3(0,.42,0),Vector3(4.6,.85,1.3),.4,Color('#bc906b'))
		for x in [-1.65,1.65]:a.rounded(node,Vector3(x,.45,0),Vector3(.25,.98,1.36),.12,CREAM)
		for x in [-.85,.8]:a.rounded(node,Vector3(x,.87,0),Vector3(.65,.035,.08),.02,Color('#99724f'))
	else:
		a.torus(node,Vector3(0,.3,0),1.05,.27,CORAL)
		a.sphere(node,Vector3(0,.68,0),Vector3(1.6,1.3,1.6),CORAL)
	warning(g,node)
	hazards.append({'node':node,'s':s,'lane':lane,'base_lane':lane,'kind':kind,'radius':3.0 if kind=='log' else 2.5,'touching':false})

func arrow_icon(g,node: Node3D,p: Vector3,color: Color):
	# A solid upward arrow on both faces, readable from the driving camera.
	for side in [-1,1]:
		var z=p.z+side*.10
		g.art.rounded(node,Vector3(p.x,p.y-.15,z),Vector3(.25,1.05,.12),.055,color)
		for sign_x in [-1,1]:
			g.art.tube(node,[Vector3(p.x+sign_x*.52,p.y+.08,z),Vector3(p.x,p.y+.65,z)],g.art.equal_radii(2,.14),color,8)

func pad(g,root,s: float,lane: float):
	var node=group(g,root,s,lane)
	var a=g.art
	a.rounded(node,Vector3(0,.10,0),Vector3(5.4,.20,13.8),.08,Color('#398f91'))
	var plane=PlaneMesh.new()
	plane.size=Vector2(4.75,13.5)
	var flow=ShaderMaterial.new()
	flow.shader=load('res://shaders/speed_lane.gdshader')
	var surface=MeshInstance3D.new()
	surface.mesh=plane
	surface.material_override=flow
	surface.position.y=.23
	node.add_child(surface)
	# Rounded side floats frame a broad runway; five moving chevrons show its direction.
	for x in [-2.65,2.65]:
		a.rounded(node,Vector3(x,.34,0),Vector3(.38,.42,13.6),.18,CREAM)
		for z in [-5.5,5.5]:
			a.sphere(node,Vector3(x,.38,z),Vector3(.53,.56,.53),MINT)
		# Two stacked forward chevrons stand beside the entry, never hidden under the boat.
		var sign_node=Node3D.new()
		node.add_child(sign_node)
		sign_node.position=Vector3(x,.9,5.1)
		for y in [0.0,.48]:
			for side in [-1,1]:
				a.tube(sign_node,[Vector3(side*.38,y,0),Vector3(0,y+.32,0)],a.equal_radii(2,.11),MINT,8)
	pads.append({'node':node,'s':s,'lane':lane,'last_lap':-1,'flow':flow})

func ramp_height(progress: float)->float:
	return .10+pow(clampf(progress,0,1),1.9)*1.45

func ramp(g,root,s: float,lane: float):
	var node=group(g,root,s,lane)
	var a=g.art
	var mesh=SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(16):
		var p0=float(j)/16
		var p1=float(j+1)/16
		var z0=4.8-p0*8.4
		var z1=4.8-p1*8.4
		var y0=ramp_height(p0)
		var y1=ramp_height(p1)
		var vertices=[Vector3(-2.3,y0,z0),Vector3(2.3,y0,z0),Vector3(-2.3,y1,z1),Vector3(2.3,y1,z1)]
		for i in [0,2,1,1,2,3]:
			mesh.set_normal(Vector3(0,1,(y1-y0)/(z0-z1)).normalized())
			mesh.add_vertex(vertices[i])
		# Closed golden side wedges make the rising profile visible, including at a distance.
		for side in [-1,1]:
			var pts=[Vector3(side*2.3,.04,z0),Vector3(side*2.3,y0,z0),Vector3(side*2.3,y1,z1),Vector3(side*2.3,.04,z1)]
			for i in [0,1,2,0,2,3]:
				mesh.set_normal(Vector3(side,0,0))
				mesh.add_vertex(pts[i])
	a.mesh_node(node,mesh.commit(),Vector3.ZERO,Color('#edae4f'))
	for j in range(9):
		var u=float(j)/8
		var z=4.8-u*8.4
		a.rounded(node,Vector3(0,ramp_height(u)+.025,z),Vector3(4.65,.085,.17),.03,CREAM)
	for x in [-2.4,2.4]:
		var rail=[]
		for j in range(17):
			var u=float(j)/16
			rail.append(Vector3(x,ramp_height(u)+.16,4.8-u*8.4))
		a.tube(node,rail,a.equal_radii(17,.13),CORAL,10)
		a.rounded(node,Vector3(x,1.2,-3.6),Vector3(.18,2.4,.18),.07,CORAL)
		a.sphere(node,Vector3(x,2.45,-3.6),Vector3(.35,.35,.35),CREAM)
		arrow_icon(g,node,Vector3(x,2.95,-3.6),Color('#ffe8aa'))
	# A broad solid arrow on the rising deck points directly toward the takeoff lip.
	for z in [2.6,1.0,-.6]:
		var u=(4.8-z)/8.4
		for side in [-1,1]:
			a.tube(node,[Vector3(side*1.25,ramp_height(u)+.10,z+.55),Vector3(0,ramp_height((4.8-z+.45)/8.4)+.10,z-.45)],a.equal_radii(2,.16),CREAM,8)
	ramps.append({'node':node,'s':s,'lane':lane,'last_lap':-1})

func boat_ramp_height(g)->float:
	return ramp_surface_height(g,g.distance,g.lateral)

func ramp_surface_height(g,s: float,lane: float)->float:
	for item in ramps:
		var along=wrapf(s-item.s,-g.LENGTH*.5,g.LENGTH*.5)
		if along>=-4.8 and along<=3.6 and absf(lane-item.lane)<2.3:
			return ramp_height((along+4.8)/8.4)
	return 0.0

func begin_build():
	hazards.clear();shells.clear();pads.clear();ramps.clear()

func build(g,root):
	begin_build()
	for i in range(8):build_section(g,root,i)

func section_jobs(g,i: int)->Array:
	var jobs=[]
	var s=70.0+i*185.0
	var mirror=-1.0 if (i+g.track_id)%2==0 else 1.0
	jobs.append(['gift',s,-mirror*5])
	jobs.append(['hazard',s+37,-mirror*3,['rock','log','buoy'][(i+g.track_id)%3]])
	for j in range(5):jobs.append(['shell',s+25+j*8,mirror*6])
	jobs.append(['pad',s+82,mirror*6])
	if i%2==0:
		jobs.append(['ramp',s+124,-mirror*4])
		for j in range(3):jobs.append(['shell',s+130+j*8,-mirror*4])
	else:
		jobs.append(['hazard',s+132,-7.0,'log'])
		jobs.append(['hazard',s+132,7.0,'rock'])
		jobs.append(['gift',s+139,0.0])
	return jobs

func build_feature(g,root,job: Array):
	match job[0]:
		'gift':gift(g,root,job[1],job[2])
		'shell':shell(g,root,job[1],job[2])
		'hazard':hazard(g,root,job[1],job[2],job[3])
		'pad':pad(g,root,job[1],job[2])
		'ramp':ramp(g,root,job[1],job[2])

func build_section(g,root,i: int):
	for job in section_jobs(g,i):build_feature(g,root,job)

func reset(g):
	for item in g.boxes+shells:
		item.taken_lap=-1
		item.node.show()
	for item in pads+ramps:item.last_lap=-1
	for h in hazards:
		h.touching=false
		h.disabled_until=0.0
		h.node.show()
	g.shell_count=0
	g.air_time=0
	g.shield_time=0
	g.impact_time=0

func tick(g,dt: float):
	for item in g.boxes+shells:
		item.node.visible=item.taken_lap!=int(g.distance/g.LENGTH)
		item.node.position.y=sin(g.water_clock*2+item.s)*.12
	for item in pads:item.flow.set_shader_parameter("flow_time",g.water_clock)
	for h in hazards:
		h.node.visible=h.get("disabled_until",0)<=g.water_clock
		if h.kind=='buoy':
			h.lane=clampf(h.base_lane+sin(g.water_clock*.65+h.s)*3.4,-10,10)
			g.place(h.node,h.s,h.lane)
			h.node.position.y=sin(g.water_clock*2+h.s)*.10
	var was_air=g.air_time
	g.air_time=maxf(0,g.air_time-dt)
	if was_air>0 and g.air_time==0:g.sfx.cue("land")
	g.shield_time=maxf(0,g.shield_time-dt)
	g.impact_time=maxf(0,g.impact_time-dt)

func touches(g,s: float,previous: float,depth: float)->bool:
	# Swept entry test includes wraparound and long frames at boost speed.
	return absf(wrapf(previous-s,-g.LENGTH*.5,g.LENGTH*.5))<depth or absf(wrapf(g.distance-s,-g.LENGTH*.5,g.LENGTH*.5))<depth or floor((previous-s+depth)/g.LENGTH)<floor((g.distance-s+depth)/g.LENGTH)

func absorb(g)->bool:
	if g.shield_time<=0:return false
	g.shield_time=0
	g.sfx.cue('item')
	g.shield_pop_time=.35
	g.hud.feedback('shield_break',2)
	return true

func interact(g,previous: float):
	var lap_index=int(g.distance/g.LENGTH)
	for h in hazards:
		var contact=h.get('disabled_until',0)<=g.water_clock and touches(g,h.s,previous,2.4) and absf(g.lateral-h.lane)<h.radius and g.air_time<=.12
		if contact and not h.touching:
			if not absorb(g):
				g.velocity*=.56
				g.boost=0
				g.lateral_speed+=(-1 if g.lateral<h.lane else 1)*5
				g.impact_time=.35
				g.sfx.cue('collision',1)
				g.hud.feedback('impact')
		h.touching=contact
	for item in g.boxes:
		if g.item>=0 and g.item_notice_time<=0 and touches(g,item.s,previous,2.4) and absf(g.lateral-item.lane)<2.6:
			g.item_notice_time=3
			g.hud.feedback('full',g.item)
		if item.taken_lap!=lap_index and touches(g,item.s,previous,2.4) and absf(g.lateral-item.lane)<2.6 and g.item<0 and g.pickup_cool<=0:
			g.item=g.next_gift()
			item.taken_lap=lap_index
			item.node.hide()
			g.pickup_cool=.6
			g.flash=.16
			g.sfx.cue('pickup')
			g.hud.collect('gift',g.item,item.node.global_position+Vector3.UP*1.2)
	for item in shells:
		if item.taken_lap!=lap_index and touches(g,item.s,previous,1.9) and absf(g.lateral-item.lane)<1.8:
			item.taken_lap=lap_index
			item.node.hide()
			g.shell_count+=1
			g.sfx.cue('shell')
			if g.shell_count%5==0:
				g.boost=maxf(g.boost,1.2)
				g.sfx.cue('pad')
				g.hud.feedback('boost',0)
			g.hud.collect('shell',-1,item.node.global_position+Vector3.UP*.9)
	for item in pads+ramps:
		var is_ramp=item in ramps
		var trigger_s=item.s+3.6 if is_ramp else item.s
		if item.last_lap!=lap_index and touches(g,trigger_s,previous,.7 if is_ramp else 5.5) and absf(g.lateral-item.lane)<2.3:
			item.last_lap=lap_index
			g.boost=maxf(g.boost,2.6)
			g.velocity=maxf(g.velocity,39)
			if item in ramps:
				g.air_time=.9
				g.sfx.cue('ramp')
				g.hud.feedback('jump')
			else:
				g.sfx.cue('pad')
				g.hud.feedback('boost',0)

