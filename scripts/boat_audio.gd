extends Node
# Independent voices keep pickups, impacts and boost feedback from cutting each other off.
var loops={}
var streams={}
var voices: Array[AudioStreamPlayer]=[]
var cooldowns={}
var events={}
var water_gain=0.0
var motor_gain=0.0
var boost_gain=0.0
var impact_cursor=0
var frozen=false
var silent=false

func _ready():
	for name in ['water','water-detail','motor','boost-water','navigate','confirm','back','count','go','pickup','lap','finish','item','charge','boost','collision','collision-2','collision-3','shell','pad','ramp','land']:
		var stream=load('res://assets/boats/sfx/'+name+'.wav') as AudioStreamWAV
		streams[name]=stream
		if name in ['water','water-detail','motor','boost-water']:
			stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
			stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
			var player=AudioStreamPlayer.new()
			if OS.has_feature("web"):player.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
			add_child(player)
			player.stream=stream
			player.volume_db=-80
			player.play(7.3 if name=='water-detail' else (3.7 if name=='water' else 0.0))
			loops[name]=player
	for i in range(12):
		var voice=AudioStreamPlayer.new()
		if OS.has_feature("web"):voice.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
		add_child(voice)
		voices.append(voice)

func cue(name: String,gain: float=1.0,pan_hint: float=0.0):
	if frozen or silent or cooldowns.get(name,0.0)>0:return
	cooldowns[name]=0.40 if name=='collision' else (0.07 if name=='navigate' else 0.12)
	for voice in voices:
		if voice.playing:continue
		var sample=name
		if name=='collision':
			impact_cursor=(impact_cursor+1)%3
			sample=['collision','collision-2','collision-3'][impact_cursor]
		voice.stream=streams[sample]
		voice.volume_db=(-19.0 if name=='collision' else (-23.0 if name=='shell' else -20.0))+linear_to_db(maxf(.05,gain))
		voice.pitch_scale=1.0+pan_hint*.04 if name=='collision' else 1.0
		voice.play()
		events[name]=events.get(name,0)+1
		return

func reset():
	for voice in voices:voice.stop()
	cooldowns.clear()
	water_gain=0
	motor_gain=0
	boost_gain=0

func tick(dt: float,racing: bool,speed: float,boosting: bool,drifting: bool,is_paused: bool,muted: bool):
	frozen=is_paused
	silent=muted
	for voice in voices:
		voice.stream_paused=frozen
		# Muting discards old transients, so unmute cannot replay a stale impact.
		if silent:voice.stop()
	for key in cooldowns:
		if not frozen:cooldowns[key]=maxf(0,cooldowns[key]-dt)
	var speed_ratio=clampf(speed/40.0,0,1)
	var moving=racing and speed>0.5
	var blend=1-exp(-dt*9)
	water_gain=lerpf(water_gain,(.10+.90*speed_ratio)*(1.15 if drifting else 1.0) if moving else 0.0,blend)
	motor_gain=lerpf(motor_gain,.25+.75*speed_ratio if moving else 0.0,blend)
	boost_gain=lerpf(boost_gain,1.0 if moving and boosting else 0.0,blend)
	loops.water.pitch_scale=.94+speed_ratio*.12
	loops['water-detail'].pitch_scale=1.04+speed_ratio*.07
	loops.motor.pitch_scale=.76+speed_ratio*.78
	loops['boost-water'].pitch_scale=1.0+speed_ratio*.10
	for name in loops:
		var voice=loops[name]
		voice.stream_paused=frozen
		var gain=water_gain if name in ['water','water-detail'] else (motor_gain if name=='motor' else boost_gain)
		var level=-30.0 if name=='water' else (-36.0 if name=='water-detail' else (-23.0 if name=='motor' else -30.0))
		voice.volume_db=-80.0 if silent or gain<.001 else level+linear_to_db(gain)
