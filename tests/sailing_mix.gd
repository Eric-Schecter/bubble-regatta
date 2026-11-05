extends SceneTree
var game
var throttle=true

func _initialize():call_deferred('run')

func cruise(seconds: float):
	var until=Time.get_ticks_msec()+seconds*1000
	while Time.get_ticks_msec()<until:
		if throttle:game.physical_test_key(KEY_UP,true)
		game.lateral=0
		game.lateral_speed=0
		await process_frame

func run():
	game=load('res://main.tscn').instantiate()
	root.add_child(game)
	await process_frame
	game.mode=2
	game.start_race()
	game.best=.01
	game.countdown=-1
	var recorder=AudioEffectRecord.new()
	AudioServer.add_bus_effect(0,recorder)
	recorder.set_recording_active(true)
	game.physical_test_key(KEY_UP,true)
	await cruise(5)
	assert(game.sfx.loops.motor.volume_db>game.sfx.loops.water.volume_db+6)
	assert(game.sfx.streams.water.get_length()>28)
	assert(game.sfx.streams['water-detail'].get_length()>36)
	var before=game.sfx.loops.motor.pitch_scale
	# Cruise spans a full water loop, while the second layer keeps moving independently.
	await cruise(24)
	game.boost=3
	game.sfx.cue('boost')
	await cruise(2)
	assert(game.sfx.loops.motor.pitch_scale>before)
	game.key_event(KEY_ESCAPE)
	await create_timer(.4).timeout
	for voice in game.sfx.loops.values():assert(voice.stream_paused)
	game.key_event(KEY_ESCAPE)
	game.key_event(KEY_M)
	await create_timer(.25).timeout
	for voice in game.sfx.loops.values():assert(voice.volume_db==-80)
	game.key_event(KEY_M)
	throttle=false
	game.physical_test_key(KEY_UP,false)
	game.physical_test_key(KEY_DOWN,true)
	await cruise(3)
	game.physical_test_key(KEY_DOWN,false)
	await cruise(1)
	assert(game.sfx.motor_gain<.001 and game.sfx.water_gain<.001)
	recorder.set_recording_active(false)
	recorder.get_recording().save_to_wav('res://captures/sailing-mix-v2.wav')
	print('SAILING MIX PASS: 29/37-second independent water layers, motor presence/RPM, loop crossing, boost, all-layer pause/mute, stop fade; actual scene mix recorded')
	quit()
