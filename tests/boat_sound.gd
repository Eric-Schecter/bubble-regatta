extends SceneTree
var game
var recorder: AudioEffectRecord

func _initialize():call_deferred('run')

func wait_seconds(seconds: float):await create_timer(seconds).timeout

func run():
	game=load('res://main.tscn').instantiate()
	root.add_child(game)
	await process_frame
	if '--record-sfx' in OS.get_cmdline_user_args():
		recorder=AudioEffectRecord.new()
		AudioServer.add_bus_effect(0,recorder)
		recorder.set_recording_active(true)
	game.key_event(KEY_ENTER)
	await wait_seconds(.25)
	game.key_event(KEY_DOWN)
	await wait_seconds(.20)
	game.key_event(KEY_ENTER)
	await wait_seconds(.30)
	game.mode=2
	game.start_race()
	game.best=.01 # This review must not write a personal best.
	await wait_seconds(3.7)
	assert(game.sfx.events.get('count',0)==3)
	assert(game.sfx.events.get('go',0)==1)
	game.physical_test_key(KEY_UP,true)
	await wait_seconds(1.8)
	assert(game.sfx.water_gain>.1 and game.sfx.motor_gain>.1)
	if recorder:root.get_texture().get_image().save_png('res://captures/boat-sound-race.png')
	game.lateral=15
	game.velocity=30
	await wait_seconds(.2)
	assert(game.sfx.events.get('collision',0)>0)
	var impacts=game.sfx.events.collision
	await wait_seconds(.1)
	assert(game.sfx.events.collision==impacts,'Wall contact must not spam impacts')
	game.lateral=0
	game.wall_contact=false
	await wait_seconds(.25)
	game.mode=1
	var other=game.opponents[0]
	other.s=game.distance
	other.lane=0
	other.touching=false
	await wait_seconds(.4)
	assert(game.sfx.events.collision>impacts,'Boat contact should also trigger collision sound')
	game.mode=2
	game.lateral=0
	game.velocity=30
	game.charge=.7
	game.physical_test_key(KEY_RIGHT,true)
	game.physical_test_key(KEY_SHIFT,true)
	await wait_seconds(.2)
	assert(game.sfx.events.get('charge',0)>0)
	game.physical_test_key(KEY_SHIFT,false)
	game.physical_test_key(KEY_RIGHT,false)
	await wait_seconds(.2)
	assert(game.sfx.events.get('boost',0)>0)
	await wait_seconds(.6)
	var box=game.boxes[0]
	game.distance=box.s-.1
	game.lateral=box.lane
	game.lateral_speed=0
	game.velocity=5
	game.pickup_cool=0
	game.item=-1
	await wait_seconds(.2)
	assert(game.sfx.events.get('pickup',0)>0)
	game.key_event(KEY_SPACE)
	await wait_seconds(.4)
	assert(game.sfx.events.get('item',0)>0)
	game.key_event(KEY_ESCAPE)
	await wait_seconds(.2)
	assert(game.sfx.loops.water.stream_paused)
	var position=game.sfx.loops.water.get_playback_position()
	await wait_seconds(.4)
	assert(absf(game.sfx.loops.water.get_playback_position()-position)<.05)
	game.key_event(KEY_ESCAPE)
	game.key_event(KEY_M)
	await wait_seconds(.15)
	assert(game.sfx.loops.water.volume_db==-80)
	var events_before=game.sfx.events.duplicate()
	game.sfx.cue('pickup')
	assert(game.sfx.events==events_before)
	game.key_event(KEY_M)
	await wait_seconds(.25)
	game.distance=game.LENGTH-.1
	game.velocity=30
	await wait_seconds(.2)
	assert(game.sfx.events.get('lap',0)>0)
	await wait_seconds(.8)
	game.distance=game.LENGTH*3-.1
	await wait_seconds(1.7)
	assert(game.state=='result' and game.sfx.events.get('finish',0)==1)
	assert(game.sfx.water_gain<.001)
	game.physical_test_key(KEY_UP,false)
	if recorder:
		recorder.set_recording_active(false)
		recorder.get_recording().save_to_wav('res://captures/boat-sound-review.wav')
	print('BOAT SOUND PASS: real countdown, sailing, collision cooldown, drift boost, pickup/use, pause, mute, lap and finish; ',game.sfx.events)
	quit()
