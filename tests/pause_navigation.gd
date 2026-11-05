extends SceneTree
func _initialize():call_deferred('run')
func run():
	var g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.racer=3
	g.start_race()
	g.countdown=-1
	g.velocity=30
	g.item=2
	g.use_item()
	g.cup_round=1
	g.cup_points=22
	g.key_event(KEY_ESCAPE)
	g._process(0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://captures/pause-navigation.png')
	g.menu_click(Vector2(398,299))
	assert(not g.paused and g.state=='race','Resume must keep the current race')
	g.key_event(KEY_ESCAPE)
	g.menu_click(Vector2(398,399))
	assert(g.state=='select' and not g.paused and g.racer==3)
	assert(g.item==-1 and g.velocity==0 and g.shield_time==0 and g.boost==0)
	assert(g.cup_round==0 and g.cup_points==0 and g.wakes.is_empty())
	assert(g.music_track=='harbor-day' and not g.music.stream_paused)
	assert(g.sfx.water_gain==0 and g.sfx.motor_gain==0 and not g.sfx.frozen)
	g._process(.016)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://captures/pause-return-captains.png')
	g.key_event(KEY_ENTER)
	assert(g.state=='race' and not g.paused and g.countdown>3)
	g.key_event(KEY_ESCAPE)
	g.menu_click(Vector2(562,299))
	assert(g.state=='race' and not g.paused and g.countdown>3,'Restart must still work')
	g._process(0)
	await create_timer(.65).timeout
	g.key_event(KEY_ESCAPE)
	assert(g.paused)
	print('PAUSE NAVIGATION PASS: resume, return to captains with race/audio reset, new race, restart; invoking real exit button now')
	g.menu_click(Vector2(562,399))
