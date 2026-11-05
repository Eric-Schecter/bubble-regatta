extends SceneTree
func _initialize():call_deferred('run')
func run():
	var g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.mode=2
	g.start_race()
	g._process(0)
	await process_frame
	if DisplayServer.get_name()!='headless':
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png('res://captures/visual-start.png')
	g.countdown=-1
	g.best=.01
	g.distance=380
	g.velocity=30
	g.item=0
	g.physical_test_key(KEY_RIGHT,true)
	g.physical_test_key(KEY_SPACE,true)
	await process_frame
	g._process(.05)
	assert(g.item==-1 and g.boost>0 and g.charge==0,'Space must use the item, without starting a drift')
	g.item=2
	var held=InputEventKey.new()
	held.physical_keycode=KEY_SPACE;held.pressed=true;held.echo=true
	g._input(held)
	assert(g.item==2,'Holding Space must not consume another item')
	g.physical_test_key(KEY_SPACE,false)
	g.physical_test_key(KEY_SHIFT,true)
	await process_frame
	for frame in range(8):
		g.physical_test_key(KEY_RIGHT,true)
		g._process(.1)
		await process_frame
	assert(g.charge>.6 and g.item==2,'Shift must charge drifting without using the held gift')
	g.physical_test_key(KEY_SHIFT,false)
	await process_frame
	g._process(.05)
	assert(g.charge==0 and g.boost>0)
	g.physical_test_key(KEY_SPACE,true)
	await process_frame
	g._process(0)
	assert(g.item==-1 and g.shield_time==7)
	g.physical_test_key(KEY_SPACE,false)
	g.item=0
	g.key_event(KEY_X)
	assert(g.item==0,'X should no longer use an item')
	g.key_event(KEY_ESCAPE)
	g.physical_test_key(KEY_SPACE,true)
	await process_frame
	assert(g.item==0,'Space must not use gifts while paused')
	g.physical_test_key(KEY_SPACE,false)
	g.key_event(KEY_ESCAPE)
	g.menu_click(Vector2(915,115))
	assert(g.paused,'Pause icon must pause the race')
	if DisplayServer.get_name()!='headless':
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png('res://captures/visual-pause.png')
	g.menu_click(Vector2(398,299))
	assert(not g.paused,'Play icon must resume the race')
	assert(g.world.find_children('*','Label3D',true,false).is_empty(),'Course features must communicate through shapes rather than text labels')
	g.physical_test_key(KEY_RIGHT,false)
	g.physical_test_key(KEY_SHIFT,false)
	g._process(0)
	await process_frame
	if DisplayServer.get_name()!='headless':
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png('res://captures/space-controls.png')
	print('CONTROL PASS: Space item use, no auto-repeat, Shift drift/release, old X disabled, pause guard; actual default scene')
	await create_timer(.6).timeout
	g.queue_free()
	await process_frame
	quit()
