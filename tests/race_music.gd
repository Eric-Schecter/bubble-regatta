extends SceneTree

func _initialize():call_deferred('run')

func run():
	var game=load('res://main.tscn').instantiate()
	root.add_child(game)
	await process_frame
	assert(game.music_track=='harbor-day' and game.music_bpm==112)
	var selection_stream=game.music.stream
	game.start_race()
	game.update_music_track()
	assert(game.music_track=='bubble-sprint' and game.music_bpm==140)
	assert(game.music.stream!=selection_stream and game.music.playing)
	assert(game.music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD)
	assert(game.music.stream.loop_end>1000000)
	await create_timer(.6).timeout
	assert(game.music_fades.is_empty())
	game.key_event(KEY_ESCAPE)
	assert(game.paused and game.music.stream_paused)
	game.key_event(KEY_ESCAPE)
	assert(not game.paused and not game.music.stream_paused)
	game.key_event(KEY_M)
	assert(game.muted and game.music.volume_db==-80)
	game.state='result'
	game.update_music_track()
	await create_timer(.6).timeout
	assert(game.music_track=='harbor-day' and game.music_bpm==112)
	assert(game.music.volume_db==-80)
	game.key_event(KEY_M)
	assert(not game.muted and game.music.volume_db==-13)
	print('RACE MUSIC PASS: selection/race/result switching, loop, crossfade, tempo, pause and mute')
	quit()
