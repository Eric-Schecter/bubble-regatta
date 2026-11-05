extends SceneTree
func _initialize():call_deferred('run')

func run():
	var game=load('res://main.tscn').instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.mode=2
	game.start_race()
	game.countdown=-1
	game.best=.01
	var checked=0
	for stage in range(3):
		game.physical_test_key(KEY_RIGHT,stage==1)
		game.physical_test_key(KEY_SHIFT,stage==1)
		for frame in range(55):
			game.physical_test_key(KEY_RIGHT,stage==1)
			game.physical_test_key(KEY_SHIFT,stage==1)
			game.physical_test_key(KEY_UP,true)
			game.boost=3
			game.velocity=47
			var dt=.1 if stage==2 else 1.0/30
			game._process(dt)
			var samples=[]
			for w in game.wakes:
				if w.sign==0:samples.append(w)
			for i in range(samples.size()-1):
				assert(samples[i].p.distance_to(samples[i+1].p)<.405,'Wake spacing must remain continuous at speed and on turns')
				checked+=1
			if samples.size()>0:
				var head=game.wake_heads.values().filter(func(w):return w.sign==0)[0]
				assert(samples[-1].p.distance_to(head.p)<.405,'Current hull must connect to last sampled section')
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png('res://captures/wake-continuous-'+str(stage)+'.png')
	game.physical_test_key(KEY_UP,false)
	game.physical_test_key(KEY_RIGHT,false)
	game.physical_test_key(KEY_SHIFT,false)
	game.paused=true
	var before=game.water_clock
	game._process(.1)
	assert(game.water_clock==before)
	game.start_race()
	assert(game.wakes.is_empty() and game.wake_heads.is_empty())
	print('WAKE PASS: ',checked,' connected segments; high-speed straight, turning/drift, 10 FPS, live stern attachment, pause and restart; actual default scene captured')
	quit()
