extends SceneTree
func _initialize():call_deferred('run')
func run():
	var game=load('res://main.tscn').instantiate()
	var started=Time.get_ticks_usec()
	root.add_child(game)
	print('SCENE READY ms: ',(Time.get_ticks_usec()-started)/1000.0)
	game.set_process(false)
	game.state='select'
	var root_ids={0:game.track_cache[0].root.get_instance_id()}
	var max_click=0.0
	var max_pump=0.0
	var start_frame=0.0
	for i in range(6):
		var t=Time.get_ticks_usec()
		game.menu_click(Vector2(290,400))
		var click_ms=(Time.get_ticks_usec()-t)/1000.0
		max_click=maxf(max_click,click_ms)
		var start_pending=i==1 and game.pending_track>=0
		if start_pending:
			game.key_event(KEY_ENTER)
			assert(game.pending_start and game.state=='select')
		var frames=0
		while game.pending_track>=0:
			var frame=Time.get_ticks_usec()
			game._process(1.0/60)
			var elapsed=(Time.get_ticks_usec()-frame)/1000.0
			if start_pending and game.state=='race':start_frame=elapsed
			else:max_pump=maxf(max_pump,elapsed)
			frames+=1
			await process_frame
		if start_pending:
			assert(game.state=='race' and game.track_id==2,'Race entry must wait for the requested course')
			game.state='select'
		assert(game.active_track==game.track_id)
		assert(game.boxes.size()==12 and game.course.pads.size()==8)
		var id=game.track_id
		var node_id=game.track_cache[id].root.get_instance_id()
		if root_ids.has(id):assert(root_ids[id]==node_id,'Revisiting must reuse the same course root')
		root_ids[id]=node_id
		print('COURSE ',id,' click ms: ',click_ms,'; prepare frames: ',frames,'; build CPU ms: ',game.track_cache[id].cpu_ms,'; max build step ',game.track_cache[id].max_step_ms,' ms at phase ',game.track_cache[id].max_step_phase)
		if DisplayServer.get_name()!='headless':
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png('res://captures/course-cache-'+str(id)+'.png')
	assert(game.track_cache.size()==3 and max_click<50)
	# Rapid changes must commit the final requested course, including a cached selection.
	game.request_track(1);game.request_track(2);game.request_track(0)
	assert(game.track_id==0 and game.pending_track==-1)
	game.mode=1
	game.start_race()
	assert(game.course.hazards.size()>=12)
	print('COURSE PROFILE PASS: max click ',max_click,' ms; max preparation frame ',max_pump,' ms; race-start frame ',start_frame,' ms; 3 stable cached roots, correct feature sets, rapid switching and race entry')
	game.queue_free()
	await process_frame
	quit()
