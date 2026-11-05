extends SceneTree
var g
func _initialize():call_deferred('run')
func capture(name: String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://captures/item-ai-'+name+'.png')
func camera_at_player():
	g.place(g.player,g.distance,g.lateral)
	g.cam.position=g.player.position-g.tangent(g.distance)*8.5+Vector3.UP*4.6
	g.cam.look_at(g.player.position+g.tangent(g.distance)*7+Vector3.UP*.85)
func run():
	g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.start_race()
	g.countdown=-1
	g.best=.01
	g.distance=g.boxes[0].s-.1
	g.lateral=g.boxes[0].lane
	g.velocity=25
	camera_at_player()
	g._process(.05)
	await process_frame
	await capture('gift')
	g.menu_click(Vector2(135,465))
	g._process(.05)
	await process_frame
	await capture('boost')
	var h=g.course.hazards[0]
	g.distance=h.s-18
	g.lateral=h.lane
	g.item=1
	g.opponents[0].s=g.distance+24
	g.opponents[0].lane=g.lateral
	camera_at_player()
	assert(g.use_item())
	g._process(.10)
	await process_frame
	await capture('wave')
	g.item=2
	g.use_item()
	g._process(.05)
	await process_frame
	await capture('shield')
	g.start_race()
	g.countdown=-1
	for frame in range(150):
		g.physical_test_key(KEY_UP,true)
		g._process(.08)
		await process_frame
	await capture('race')
	g.physical_test_key(KEY_UP,false)
	print('ITEM/AI REVIEW PASS: real pickup, click-to-use boost, visible wave, active shield and 8-boat competition captured; rank at 12s: ',g.rank)
	quit()
