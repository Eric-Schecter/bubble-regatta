extends RefCounted
# Flat water-plane capsules approximate the rounded hull (including the outboard).
# All eight boats participate; rank distance is never wrapped when applying correction.
const RADIUS=1.43
const HALF_SEGMENT=.86
var contacts={}
var splashes=[]
var impacts=0

func reset():
	contacts.clear()
	impacts=0
	for splash in splashes:
		if is_instance_valid(splash.node):splash.node.queue_free()
	splashes.clear()

func body(g,index: int)->Dictionary:
	if index==0:
		return {'index':0,'node':g.player,'s':g.distance,'lane':g.lateral,'speed':g.velocity,'side_speed':g.lateral_speed,'protected':g.shield_time>0}
	var o=g.opponents[index-1]
	return {'index':index,'node':o.node,'s':o.s,'lane':o.lane,'speed':o.velocity,'side_speed':o.get('collision_lateral',0.0)+o.get('steer',0.0)*7.0,'protected':o.shield}

func center_of(g,b)->Vector3:
	var p=g.center(b.s)+g.side(b.s)*b.lane
	p.y=0
	return p

func axis_of(b)->Vector3:
	var axis=b.node.global_basis.z
	axis.y=0
	return axis.normalized()

func nearest(a0: Vector3,a1: Vector3,b0: Vector3,b1: Vector3)->Array:
	var u=a1-a0
	var v=b1-b0
	var w=a0-b0
	var aa=u.dot(u)
	var bb=u.dot(v)
	var cc=v.dot(v)
	var dd=u.dot(w)
	var ee=v.dot(w)
	var determinant=aa*cc-bb*bb
	var s=clampf((bb*ee-cc*dd)/determinant,0,1) if determinant>.00001 else 0.0
	var t=(bb*s+ee)/cc
	if t<0:
		t=0
		s=clampf(-dd/aa,0,1)
	elif t>1:
		t=1
		s=clampf((bb-dd)/aa,0,1)
	return [a0+u*s,b0+v*t]

func move_body(g,b,displacement: Vector3):
	b.s+=displacement.dot(g.tangent(b.s))
	b.lane=clampf(b.lane+displacement.dot(g.side(b.s)),-13.65,13.65)

func velocity_of(g,b)->Vector3:
	return g.tangent(b.s)*b.speed+g.side(b.s)*b.side_speed

func set_velocity(g,b,v: Vector3):
	b.speed=clampf(v.dot(g.tangent(b.s)),0,52)
	b.side_speed=clampf(v.dot(g.side(b.s)),-13,13)

func absorb(g,b)->bool:
	if b.index==0:return g.course.absorb(g)
	var o=g.opponents[b.index-1]
	if not o.shield:return false
	o.shield=false
	return true

func solve(g,_dt: float):
	if g.mode==2:return
	var bodies=[]
	for i in range(g.opponents.size()+1):bodies.append(body(g,i))
	var current={}
	# Multiple passes settle crowded groups without a single large positional jump.
	for iteration in range(4):
		for i in range(bodies.size()):
			for j in range(i+1,bodies.size()):
				var a=bodies[i]
				var b=bodies[j]
				if absf(a.node.position.y-b.node.position.y)>.90:continue
				var ca=center_of(g,a)
				var cb=center_of(g,b)
				if ca.distance_squared_to(cb)>30.25:continue
				var aa=axis_of(a)*HALF_SEGMENT
				var ab=axis_of(b)*HALF_SEGMENT
				var points=nearest(ca-aa,ca+aa,cb-ab,cb+ab)
				var delta: Vector3=points[1]-points[0]
				var separation=delta.length()
				if separation>RADIUS*2+.035:continue
				var key=str(i)+':'+str(j)
				var normal=delta/separation if separation>.001 else (cb-ca).normalized()
				if normal.length_squared()<.5:normal=g.side(a.s)
				var penetration=maxf(0,RADIUS*2-separation)
				var va=velocity_of(g,a)
				var vb=velocity_of(g,b)
				var closing=(va-vb).dot(normal)
				if not current.has(key):
					if contacts.has(key):current[key]=contacts[key]
					else:
						var protected_a=absorb(g,a) if closing>.7 or penetration>.08 else false
						var protected_b=absorb(g,b) if closing>.7 or penetration>.08 else false
						current[key]={'a':protected_a,'b':protected_b}
						if closing>.7 or penetration>.08:
							impacts+=1
							if i==0:
								if not protected_a:g.sfx.cue('collision',clampf(.45+closing/18,.45,1.15),signf(g.lateral-b.lane))
								g.impact_time=maxf(g.impact_time,.22)
							if ca.distance_to(g.player.position)<35:spawn_splash(g,(points[0]+points[1])*.5,normal)
				var protection=current[key]
				var mass_a=.35 if protection.a else 1.0
				var mass_b=.35 if protection.b else 1.0
				var total=mass_a+mass_b
				if penetration>.015:
					var correction=minf(penetration-.015,1.4)*.85
					move_body(g,a,-normal*correction*mass_a/total)
					move_body(g,b,normal*correction*mass_b/total)
				if closing>0:
					var impulse=closing*1.08/total
					if not protection.a:set_velocity(g,a,va-normal*impulse*mass_a)
					if not protection.b:set_velocity(g,b,vb+normal*impulse*mass_b)
	contacts=current
	for b in bodies:
		if b.index==0:
			g.distance=b.s
			g.lateral=b.lane
			g.velocity=b.speed
			g.lateral_speed=b.side_speed
		else:
			var o=g.opponents[b.index-1]
			o.s=b.s
			o.lane=b.lane
			o.velocity=b.speed
			o.collision_lateral=clampf(b.side_speed-o.get("steer",0.0)*7.0,-13,13)

func spawn_splash(g,p: Vector3,normal: Vector3):
	var root=Node3D.new()
	g.world.add_child(root)
	root.position=Vector3(p.x,.17,p.z)
	for i in range(7):
		var angle=TAU*float(i)/7
		var direction=Vector3(cos(angle),0,sin(angle))
		var drop=g.art.sphere(root,direction*.15,Vector3(.15,.08,.29),Color('#dcf4e9'))
		drop.rotation.y=angle
		drop.set_meta('direction',direction)
		drop.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	splashes.append({'node':root,'age':0.0})

func tick(dt: float):
	for splash in splashes:
		splash.age+=dt
		var t=clampf(splash.age/.38,0,1)
		for drop in splash.node.get_children():
			drop.position=drop.get_meta('direction')*(.15+t*.85)+Vector3.UP*sin(t*PI)*.12
			drop.scale=Vector3(.15,.08,.29)*(1-t)
		if t>=1:splash.node.queue_free()
	splashes=splashes.filter(func(s):return s.age<.38)
