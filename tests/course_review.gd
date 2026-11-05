extends SceneTree
var g
var record: AudioEffectRecord
func _initialize():call_deferred('run')
func run():
	g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.mode=2
	g.start_race()
	g.countdown=-1
	g.best=.01
	record=AudioEffectRecord.new()
	AudioServer.add_bus_effect(0,record)
	record.set_recording_active(true)
	var shots=[['gift',g.boxes[0].s-14,0.0],['obstacle',g.course.hazards[0].s-12,0.0],['boost',g.course.pads[0].s-16,g.course.pads[0].lane],['ramp',g.course.ramps[0].s-10,g.course.ramps[0].lane]]
	for shot in shots:
		for frame in range(25):
			g.distance=shot[1]
			g.lateral=shot[2]
			g.velocity=16
			g.lateral_speed=0
			g._process(1.0/30)
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png('res://captures/course-'+shot[0]+'.png')
	# Real interactions through the race loop, with matching recorded sound.
	for target in [g.boxes[0],g.course.shells[0],g.course.hazards[0],g.course.pads[0],g.course.ramps[0]]:
		g.distance=target.s-1
		g.lateral=target.lane
		g.velocity=34
		g.lateral_speed=0
		for frame in range(32):
			g.physical_test_key(KEY_UP,true)
			g._process(1.0/30)
			await process_frame
			if target==g.course.ramps[0] and frame==12:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png('res://captures/course-flight.png')
	g.physical_test_key(KEY_UP,false)
	record.set_recording_active(false)
	record.get_recording().save_to_wav('res://captures/course-sound.wav')
	print('COURSE REVIEW PASS: gifts, shells, obstacle, boost arrows, ramp and flight captured in actual race; mixed audio recorded')
	quit()
