extends SceneTree
var g
func _initialize():call_deferred('run')
func setup():
	g.start_race()
	g.countdown=-1
	g.best=.01
	g.distance=180
	g.lateral=0
	g.velocity=34
	g.lateral_speed=0
	g.place(g.player,g.distance,g.lateral)
	for i in range(g.opponents.size()):
		var o=g.opponents[i]
		o.s=400+i*20
		o.lane=8
		o.velocity=34
		o.steer=0
		o.collision_lateral=0
		g.place(o.node,o.s,o.lane)
func run():
	g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	setup()
	var other=g.opponents[0]
	other.s=g.distance
	other.lane=2.3
	g.lateral_speed=7
	g.place(other.node,other.s,other.lane)
	g.boat_contacts.solve(g,.016)
	assert(g.lateral<-.1 and other.lane>2.4,'Side contact must push both hulls apart')
	assert(g.lateral_speed<7 and other.collision_lateral>0,'Side momentum must transfer to the other boat')
	var impacts=g.boat_contacts.impacts
	g.boat_contacts.solve(g,.016)
	assert(g.boat_contacts.impacts==impacts,'Persistent contact must not replay the impact')
	setup()
	other=g.opponents[0]
	other.s=g.distance+3.9
	other.lane=0
	other.velocity=18
	g.velocity=44
	g.place(other.node,other.s,other.lane)
	g.boat_contacts.solve(g,.016)
	assert(g.velocity<44 and other.velocity>18,'Rear collision must slow the rear boat and push the leading boat')
	assert(other.s-g.distance>4.3,'Bow and stern should separate rather than pass through')
	setup()
	var a=g.opponents[0]
	var b=g.opponents[1]
	a.s=260;b.s=260;a.lane=-.9;b.lane=.9
	a.collision_lateral=5;b.collision_lateral=-4
	g.place(a.node,a.s,a.lane);g.place(b.node,b.s,b.lane)
	g.boat_contacts.solve(g,.016)
	assert(a.lane<-.9 and b.lane>.9,'AI boats must collide with each other too')
	setup()
	other=g.opponents[0]
	other.s=g.distance+g.LENGTH
	other.lane=2.2
	g.place(other.node,other.s,other.lane)
	g.boat_contacts.solve(g,.016)
	assert(g.lateral<0 and other.lane>2.2,'Lapped boats on the same water must collide')
	assert(other.s-g.distance>g.LENGTH-3,'Collision must not erase lap progress')
	setup()
	other=g.opponents[0]
	other.s=g.distance;other.lane=1.5
	g.place(other.node,other.s,other.lane)
	g.player.position.y=2.0
	g.boat_contacts.solve(g,.016)
	assert(g.lateral==0 and other.lane==1.5,'A boat flying above another must not collide')
	setup()
	other=g.opponents[0]
	other.s=g.distance+3.8;other.lane=0;other.velocity=15
	g.velocity=43;g.shield_time=7
	g.place(other.node,other.s,other.lane)
	g.boat_contacts.solve(g,.016)
	assert(g.shield_time==0 and g.velocity==43 and other.velocity>15,'Shield preserves momentum while the hull still pushes the other boat')
	setup()
	g.mode=2
	other=g.opponents[0]
	other.s=g.distance;other.lane=0
	g.place(other.node,other.s,other.lane)
	g.boat_contacts.solve(g,.016)
	assert(g.lateral==0 and other.lane==0,'Hidden opponents cannot collide in solo mode')
	g.mode=1
	g.paused=true
	var before=g.distance
	g._process(.1)
	assert(g.distance==before)
	g.start_race()
	assert(g.boat_contacts.contacts.is_empty() and g.boat_contacts.splashes.is_empty())
	print('BOAT CONTACT PASS: bilateral side/rear impacts, impulse transfer, AI/AI, single contact cue, lap seam, airborne separation, shield, solo, pause and restart')
	await create_timer(.7).timeout
	g.queue_free()
	await process_frame
	await process_frame
	quit()
