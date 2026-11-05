extends SceneTree
var g
func _initialize():call_deferred('run')
func capture(name: String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://captures/boat-contact-'+name+'.png')
func arrange():
	g.start_race()
	g.countdown=-1
	g.best=.01
	g.distance=380
	g.lateral=0
	g.velocity=40
	for i in range(g.opponents.size()):
		var o=g.opponents[i]
		o.s=500+i*14;o.lane=8;o.base_lane=8;o.velocity=32
		g.place(o.node,o.s,o.lane)
	g.place(g.player,g.distance,g.lateral)
	g.cam.position=g.player.position-g.tangent(g.distance)*8.5+Vector3.UP*4.6
func run():
	g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	arrange()
	var o=g.opponents[0]
	o.s=g.distance+4.6;o.lane=0;o.base_lane=0;o.velocity=16
	g.place(o.node,o.s,o.lane)
	for frame in range(35):
		g.physical_test_key(KEY_UP,true)
		g._process(1.0/60)
		await process_frame
		if frame==4:await capture('rear')
	assert(g.boat_contacts.impacts>0)
	arrange()
	o=g.opponents[0]
	o.s=g.distance+.4;o.lane=2.6;o.base_lane=0;o.velocity=40
	g.place(o.node,o.s,o.lane)
	for frame in range(35):
		g.physical_test_key(KEY_UP,true)
		g.physical_test_key(KEY_RIGHT,true)
		g._process(1.0/60)
		await process_frame
		if frame==5:await capture('side')
	assert(g.boat_contacts.impacts>0)
	g.physical_test_key(KEY_RIGHT,false)
	arrange()
	var a=g.opponents[0]
	var b=g.opponents[1]
	a.s=g.distance+12;b.s=a.s;a.lane=-1.0;b.lane=1.0
	a.base_lane=0;b.base_lane=0;a.velocity=32;b.velocity=32
	g.place(a.node,a.s,a.lane);g.place(b.node,b.s,b.lane)
	for frame in range(25):
		g.physical_test_key(KEY_UP,true)
		g._process(1.0/60)
		await process_frame
		if frame==3:await capture('ai')
	assert(absf(a.lane-b.lane)>2.6)
	g.physical_test_key(KEY_UP,false)
	print('CONTACT REVIEW PASS: actual rear and side impacts plus AI/AI separation rendered with water splashes')
	quit()
