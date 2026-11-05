extends Node
const MUSIC_BPM = 112.0
const RACE_MUSIC_BPM = 140.0
var music_bpm = MUSIC_BPM
var music_track = "harbor-day"
var music_fades: Array = []
const N = 560
const STEP = 2.8
const LENGTH = N * STEP
const COLORS = [Color('#ef807c'),Color('#7cbfd4'),Color('#d5a27e'),Color('#c9a4d9'),Color('#76cbb8'),Color('#f4d9a3'),Color('#f3c260'),Color('#91a3c9')]
const ANIMALS = ['bear','penguin','walrus','fox','seal','hare','reindeer','owl']
var art = preload("res://scripts/cozy_art.gd").new()
var viewport: SubViewport
var world: Node3D
var cam: Camera3D
var hud: Control
var player: Node3D
var opponents: Array = []
var boxes: Array = []
var course=preload("res://scripts/course_features.gd").new()
var race_ai=preload("res://scripts/race_ai.gd").new()
var boat_contacts=preload("res://scripts/boat_contacts.gd").new()
var lemon_time=0.0
var gift_pickups=0
var item_notice_time=0.0
var wave_time=0.0
var wave_s=0.0
var wave_lane=0.0
var wave_visual: Node3D
var shell_count=0
var air_time=0.0
var shield_time=0.0
var shield_pop_time=0.0
var impact_time=0.0
var state = 'title'
var selection = 0
var racer = 0
var track_id = 0
var active_track=-1
var track_cache={}
var track_builders={}
var pending_track=-1
var pending_start=false
var track_prepare_max_us=0
var last_visual_state=""
var cover_preview_warmed=false
var mode = 0
var distance = 0.0
var lateral = 0.0
var velocity = 0.0
var steering = 0.0
var lateral_speed = 0.0
var wakes: Array = []
var water_clock = 0.0
var muted = false
var wake_root: Node3D
var showcase = false
var art_review = false
var review_stage = 0
var input_test = false
var input_stage = 0
var charge = 0.0
var boost = 0.0
var race_time = 0.0
var countdown = 3.5
var item = -1
var lap = 1
var rank = 8
var paused = false
var music_beats=0.0
var gesture_clock=0.0
var cheer_cooldown=0.0
var cheer_text_timer=0.0
var cheer_text=""
var animation_review=false
var face_review=false
var face_stage=0
var face_stage_started=0.0
var face_frames=0
var face_next_capture=0.0
var face_timings=[]
var face_audio_start=0.0
var motion_stage=0
var motion_next_capture=0.0
var motion_frames=0
var motion_timings=[]
var motion_audio_meta={}
var motion_pause_pose: Transform3D
var motion_pause_time=0.0
var motion_rest_pose: Transform3D
var clock = 0.0
var flash = 0.0
var pickup_cool = 0.0
var best = 0.0
var sfx: Node
var charge_ready=false
var wall_contact=false
var wall_protected=false
var cup_round = 0
var cup_points = 0
var music: AudioStreamPlayer
var wake_samples={}
var wake_heads={}
var wake_distances={}
var test_mode = false
var test_stage = 0
var pause_snapshot = Vector2.ZERO

var web_window
var background_suspended=false
var web_entry_preparing=false
var perf_review=false
var perf_frame_start=0
var perf_frames=0
var perf_elapsed=0.0
var perf_process_us=0
var perf_wake_us=0
var web_waiting_for_entry=false

func _ready():
	if OS.has_feature("web"):web_window=JavaScriptBridge.get_interface("window")
	perf_review="--perf-review" in OS.get_cmdline_user_args()
	set_process(false)
	set_process_input(false)
	seed(124)
	viewport = SubViewport.new()
	viewport.size = Vector2i(960,540)
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.use_taa = not OS.has_feature("web")
	if OS.has_feature("web"):viewport.msaa_3d=Viewport.MSAA_4X
	viewport.scaling_3d_scale = 1.0
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var surface = TextureRect.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	surface.stretch_mode=TextureRect.STRETCH_SCALE
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.focus_mode = Control.FOCUS_NONE
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(surface)
	add_child(viewport)
	surface.texture=viewport.get_texture()
	get_tree().root.size_changed.connect(update_scene_resolution)
	update_scene_resolution()
	world = Node3D.new()
	viewport.add_child(world)
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color('#319adb')
	sky_mat.sky_horizon_color = Color('#96d4ec')
	sky_mat.ground_horizon_color = Color('#b9dfe8')
	sky_mat.ground_bottom_color = Color('#70b5c1')
	sky_mat.sky_energy_multiplier = 0.8
	sky_mat.sky_curve = 0.35
	sky.sky_material = sky_mat
	e.sky = sky
	e.background_color = Color('#697bab')
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color('#d9e9e1')
	e.ambient_light_energy = 0.30 if OS.has_feature("web") else 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.95
	e.ssao_enabled = not OS.has_feature("web")
	e.ssao_radius = 1.0
	e.ssao_intensity = 1.1
	e.ssao_detail = 0.8
	e.fog_enabled = true
	e.fog_light_color = Color('#c3e8e6')
	e.fog_density = 0.0007
	env.environment = e
	world.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-35,0)
	sun.light_color = Color('#fff3de')
	sun.light_energy = 0.65 if OS.has_feature("web") else 1.1
	sun.light_angular_distance = 12.0
	sun.shadow_enabled = true
	sun.shadow_blur = 1.4
	sun.shadow_bias = 0.12
	sun.shadow_normal_bias = 3.0
	sun.shadow_opacity = 0.62
	sun.directional_shadow_split_1 = 0.35
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 55.0 if OS.has_feature("web") else 85.0
	world.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 62
	cam.far = 900
	world.add_child(cam)
	wake_root = Node3D.new()
	world.add_child(wake_root)
	if OS.has_feature('web'):
		var builder=track_builder(track_id)
		while not builder.done:
			builder.advance(6000)
			web_loading_progress('course',builder.progress(),1)
			await get_tree().process_frame
		finish_track(track_id)
		activate_track(track_id)
	else:build_track()
	player = boat(racer)
	world.add_child(player)
	for i in range(7):
		if OS.has_feature('web'):
			web_loading_progress('captains',i+1,8)
			await get_tree().process_frame
		var k = boat((i+1)%8)
		world.add_child(k)
		opponents.append({'node':k,'s':float(12+i*7),'lane':float((i%3)-1)*3.1,'speed':31.0+i*0.8,'hit':0.0})
	if OS.has_feature('web'):web_loading_progress('captains',8,8)
	hud = Control.new()
	hud.set_script(load('res://scripts/hud.gd'))
	hud.game = self
	add_child(hud)
	sfx=load('res://scripts/boat_audio.gd').new()
	add_child(sfx)
	music = AudioStreamPlayer.new()
	if OS.has_feature("web"):music.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music)
	if ResourceLoader.exists('res://assets/boats/harbor-day.wav'):
		music.stream = load('res://assets/boats/harbor-day.wav')
		music.volume_db = -13
		(music.stream as AudioStreamWAV).loop_mode=AudioStreamWAV.LOOP_FORWARD
		(music.stream as AudioStreamWAV).loop_end=roundi(music.stream.get_length()*(music.stream as AudioStreamWAV).mix_rate)
		music.play()
	if FileAccess.file_exists('user://boat_best_v1.txt'):
		best = float(FileAccess.get_file_as_string('user://boat_best_v1.txt'))
		if best<10:best=0
	test_mode = '--self-test' in OS.get_cmdline_user_args()
	showcase = '--showcase' in OS.get_cmdline_user_args()
	input_test = '--input-test' in OS.get_cmdline_user_args()
	art_review = '--art-review' in OS.get_cmdline_user_args()
	animation_review = '--motion-test' in OS.get_cmdline_user_args()
	face_review = '--face-review' in OS.get_cmdline_user_args()
	set_process(true)
	set_process_input(true)
	if test_mode or '--play-now' in OS.get_cmdline_user_args(): start_race()
	if '--web-entered' in OS.get_cmdline_user_args():
		return_to_captains()
		prepare_web_entry.call_deferred()
	if '--preview' in OS.get_cmdline_user_args():
		state='select'
		distance=45
		player.get_node('Captain').request('wave')

func update_scene_resolution():
	var pixels=DisplayServer.window_get_size()
	var scale_factor=minf(1.0,1280.0/maxf(1.0,pixels.x))
	viewport.size=Vector2i(maxi(960,roundi(pixels.x*scale_factor)),maxi(540,roundi(pixels.y*scale_factor)))


func web_loading_progress(stage: String,current: float,total: float):
	JavaScriptBridge.eval("if(window.regattaProgress)window.regattaProgress('%s',%s,%s)" % [stage,str(current),str(total)],true)


func prepare_web_entry():
	web_entry_preparing=true
	# Render the actual selection scene while the HTML cover still hides it.
	_process(0.0)
	web_waiting_for_entry=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	music.stream_paused=true
	for i in range(3):
		await RenderingServer.frame_post_draw
		web_loading_progress('render',i+1,3)
	web_entry_preparing=false
	viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	JavaScriptBridge.eval("if(window.regattaReady)window.regattaReady()",true)


func material(c: Color) -> StandardMaterial3D:
	return art.mat(c.darkened(.12),.95)

func cube(parent: Node3D,pos: Vector3,size: Vector3,col: Color)->MeshInstance3D:
	if not art.meshes.has('unit_box'):art.meshes.unit_box=BoxMesh.new()
	var mesh=art.mesh_node(parent,art.meshes.unit_box,pos,col)
	mesh.material_override=material(col)
	mesh.scale=size
	return mesh

func ball(parent: Node3D,pos: Vector3,size: Vector3,col: Color)->MeshInstance3D:
	if not art.meshes.has('cloud_sphere'):
		var sphere=SphereMesh.new()
		sphere.radial_segments=24
		sphere.rings=12
		sphere.radius=.5
		sphere.height=1
		art.meshes.cloud_sphere=sphere
	var mesh=art.mesh_node(parent,art.meshes.cloud_sphere,pos,col)
	mesh.material_override=material(col)
	mesh.scale=size
	return mesh

func boat(index: int) -> Node3D:
	var node=art.make_boat(index,COLORS)
	var ring=art.torus(node,Vector3(0,.32,0),1.65,.065,Color('#b8f2d4'))
	ring.name='ShieldVisual'
	ring.scale.z=1.45
	var ring_material=ring.material_override.duplicate() as StandardMaterial3D
	ring_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override=ring_material
	ring.hide()
	return node

func center(s: float) -> Vector3:
	return center_for(s,track_id)

func center_for(s: float,id: int)->Vector3:
	var a = s/LENGTH*TAU
	var r = 190.0 + 35*sin(a*3+id)
	return Vector3(sin(a)*r,0,cos(a)*r*0.82)

func tangent(s: float) -> Vector3:
	return (center(s+0.5)-center(s-0.5)).normalized()

func side(s: float) -> Vector3:
	return tangent(s).cross(Vector3.UP).normalized()

func place(k: Node3D,s: float,l: float):
	k.position = center(s)+side(s)*l
	k.rotation.y = atan2(-tangent(s).x,-tangent(s).z)

func track_builder(id: int):
	if not track_builders.has(id):
		var builder=load('res://scripts/track_builder.gd').new(self,id)
		track_builders[id]=builder
	return track_builders[id]

func finish_track(id: int):
	track_cache[id]=track_builders[id].entry()
	if track_cache[id].root.get_parent()==null:world.add_child(track_cache[id].root)
	track_builders.erase(id)

func activate_track(id: int):
	if active_track>=0 and track_cache.has(active_track):
		var old=track_cache[active_track].root
		old.hide()
		old.name='CachedTrack'+str(active_track)
	track_id=id
	active_track=id
	var entry=track_cache[id]
	entry.root.name='Track'
	entry.root.show()
	boxes=entry.boxes
	course=entry.course
	course.reset(self)
	pending_track=-1
	if is_instance_valid(player):
		wakes.clear();wake_samples.clear();wake_heads.clear();wake_distances.clear()
		for child in wake_root.get_children():child.queue_free()
		place(player,distance,lateral)
		for o in opponents:place(o.node,o.s,o.lane)
		if state in ['title','menu','select']:
			cam.position=player.position+tangent(distance)*7.5+side(distance)*3+Vector3.UP*3.8
			cam.look_at(player.position+Vector3.UP*1.1)

func build_track():
	# Synchronous entry for initial startup and deterministic tooling. Live clicks use request_track.
	var id=track_id
	if not track_cache.has(id):
		var builder=track_builder(id)
		while not builder.done:builder.advance(1000000)
		finish_track(id)
	activate_track(id)

func request_track(id: int):
	pending_start=false
	if track_cache.has(id):activate_track(id)
	else:
		pending_track=id
		track_builder(id)

func update_track_preparation():
	if state=='race' or paused:return
	var id=pending_track
	if id<0 and state not in ['title','menu']:return
	if id<0:
		for candidate in range(3):
			if not track_cache.has(candidate):id=candidate;break
	if id<0:return
	var builder=track_builder(id)
	var started=Time.get_ticks_usec()
	builder.advance(7000 if pending_track>=0 else 3000)
	track_prepare_max_us=maxi(track_prepare_max_us,Time.get_ticks_usec()-started)
	if builder.done:
		finish_track(id)
		if pending_track==id:
			var start_when_ready=pending_start
			activate_track(id)
			pending_start=false
			if start_when_ready:start_race()

func selected_track()->int:
	return pending_track if pending_track>=0 else track_id

func selected_track_progress()->float:
	if pending_track<0:return 1.0
	return track_builders[pending_track].progress() if track_builders.has(pending_track) else 1.0

func island(root: Node3D,p: Vector3,r: float,index: int):
	art.island(root,p,r,index)

func cottage(root: Node3D,p: Vector3,index: int):
	art.cottage(root,p,index)

func lighthouse(root: Node3D,p: Vector3):
	art.lighthouse(root,p)

func refresh_captain():
	player.free()
	player=boat(racer)
	world.add_child(player)
	place(player,distance,lateral)
	player.get_node('Captain').request('wave')

func start_race():
	sfx.reset()
	boat_contacts.reset()
	course.reset(self)
	charge_ready=false
	item_notice_time=0
	shield_pop_time=0
	hud.reset_feedback()
	gift_pickups=0
	lemon_time=0
	wave_time=0
	if is_instance_valid(wave_visual):wave_visual.hide()
	wall_contact=false
	wall_protected=false
	state = 'race'
	rank=1 if mode==2 else 8
	cheer_cooldown=0
	cheer_text_timer=0
	music.stream_paused=false
	distance = 0
	lateral = 0
	lateral_speed = 0
	wakes.clear()
	wake_samples.clear()
	wake_heads.clear()
	wake_distances.clear()
	for child in wake_root.get_children(): child.queue_free()
	velocity = 0
	boost = 0
	charge = 0
	race_time = 0
	countdown = 3.5
	item = -1
	lap = 1
	paused = false
	pickup_cool = 0
	player.free()
	player = boat(racer)
	world.add_child(player)
	place(player,0,0)
	cam.position=player.position-tangent(0)*8.5+Vector3.UP*4.6
	for i in range(7):
		opponents[i].node.free()
		opponents[i].node=boat((racer+i+1)%8)
		world.add_child(opponents[i].node)
		opponents[i].s = float(12+i*7)
		opponents[i].hit=0
		opponents[i].touching=false
		opponents[i].protected_contact=false
		opponents[i].rush=0.0
		if not opponents[i].has("base_lane"):opponents[i].base_lane=opponents[i].lane
		opponents[i].lane=opponents[i].base_lane
		race_ai.reset(opponents[i],i)
		place(opponents[i].node,opponents[i].s,opponents[i].lane)
		opponents[i].node.visible = mode!=2

func _input(event):
	if web_waiting_for_entry:return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		menu_click(event.position)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var raw_key=event.physical_keycode if event.physical_keycode!=0 else event.keycode
		var key = KEY_ENTER if raw_key==KEY_KP_ENTER else raw_key
		if key==KEY_M:
			muted=not muted
			music.volume_db=-80 if muted else -13
			for fading in music_fades:
				if is_instance_valid(fading): fading.volume_db=-80
		if key==KEY_H and not paused and state in ['race','select']:
			player.get_node('Captain').request('wave')
		if key==KEY_C and not paused and state in ['race','select']:
			request_cheer('加油，船长！')
		if key==KEY_F12:
			get_viewport().get_texture().get_image().save_png('res://captures/game.png')
		if state in ['title','menu','select','result']:
			if key in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:sfx.cue('navigate')
			elif key in [KEY_ENTER,KEY_SPACE]:sfx.cue('confirm')
			elif key==KEY_ESCAPE:sfx.cue('back')
		if state=='title':
			if key==KEY_ENTER or key==KEY_SPACE:return_to_captains()
		elif state=='select':
			if key==KEY_RIGHT: racer=(racer+1)%8; refresh_captain()
			if key==KEY_LEFT: racer=posmod(racer-1,8); refresh_captain()
			if key==KEY_UP or key==KEY_DOWN: request_track(posmod(selected_track()+(1 if key==KEY_DOWN else -1),3))
			if key==KEY_ENTER:
				if pending_track>=0:pending_start=true
				else:start_race()
			if key==KEY_ESCAPE:
				pending_start=false
				pending_track=-1
				state='title'
		elif state=='race':
			if key==KEY_ESCAPE:
				paused=not paused
				music.stream_paused=paused
			if key==KEY_R: start_race()
			if key==KEY_SPACE and not paused:use_item()
		elif state=='result' and key==KEY_ENTER:
			if pending_start:return
			if mode==0 and cup_round<2:
				cup_round+=1
				request_track((track_id+1)%3)
				if pending_track>=0:pending_start=true
				else:start_race()
			else:
				return_to_captains()

func return_to_captains():
	mode=0
	paused=false
	pending_start=false
	pending_track=-1
	state='select'
	selection=clampi(mode,0,2)
	cup_round=0
	cup_points=0
	distance=45
	lateral=0
	lateral_speed=0
	steering=0
	velocity=0
	boost=0
	charge=0
	item=-1
	lemon_time=0
	shield_pop_time=0
	wave_time=0
	flash=0
	if is_instance_valid(wave_visual):wave_visual.hide()
	boat_contacts.reset()
	wakes.clear();wake_samples.clear();wake_heads.clear();wake_distances.clear()
	for child in wake_root.get_children():child.queue_free()
	course.reset(self)
	hud.reset_feedback()
	sfx.reset()
	sfx.tick(0,false,0,false,false,false,muted)
	music.stream_paused=false
	update_music_track()
	refresh_captain()

func menu_click(p: Vector2):
	if state=='race' and paused:
		if Rect2(342,258,112,82).has_point(p):key_event(KEY_ESCAPE)
		elif Rect2(506,258,112,82).has_point(p):key_event(KEY_R)
		elif Rect2(342,358,112,82).has_point(p):return_to_captains()
		elif Rect2(506,358,112,82).has_point(p):exit_game()
		return
	if state=='race' and p.distance_to(Vector2(915,115))<22:
		key_event(KEY_ESCAPE)
		return
	if state=='race' and not paused and Rect2(22,424,186,83).has_point(p):
		use_item()
		return
	if state=='title' and Rect2(58,344,295,63).has_point(p):
		key_event(KEY_ENTER)
	elif state=='select':
		for i in range(8):
			if p.distance_to(Vector2(77+(i%4)*81,241+int(i/4)*64))<29:
				sfx.cue('navigate')
				racer=i
				refresh_captain()
				return
		if Rect2(50,375,300,52).has_point(p):
			sfx.cue('navigate')
			request_track(posmod(selected_track()+(-1 if p.x<200 else 1),3))
		elif Rect2(50,447,300,44).has_point(p):key_event(KEY_ENTER)
	elif state=='result' and Rect2(50,432,300,48).has_point(p):key_event(KEY_ENTER)

func run_input_test():
	if clock<1+input_stage*0.4:return
	match input_stage:
		0: physical_test_key(KEY_ENTER,true)
		1:
			assert(state=='select' and mode==0,'Title must enter Championship captain selection')
			physical_test_key(KEY_ENTER,false)
		2:
			assert(state=='select','Keyboard menu -> selection failed')
			physical_test_key(KEY_ENTER,false)
			physical_test_key(KEY_ENTER,true)
		3:
			assert(state=='race','Keyboard selection -> race failed')
			physical_test_key(KEY_ENTER,false)
			state='title'
			click_test(Vector2(200,375))
		4:
			assert(state=='select' and mode==0,'Mouse title must enter Championship selection')
		5:
			assert(state=='select' and mode==0,'Championship selection failed')
			click_test(Vector2(239,241))
		6:
			assert(racer==2,'Mouse captain selection failed')
			click_test(Vector2(200,470))
		7:
			assert(state=='race','Mouse selection -> race failed')
			get_viewport().get_texture().get_image().save_png('res://captures/input-verified.png')
			state='result'
			cup_round=2
			click_test(Vector2(200,455))
		8:
			assert(state=='select' and mode==0 and cup_round==0,'Completed cup must return to captain selection')
			print('INPUT TEST PASS: keyboard/mouse entry and new result continue button')
			get_tree().quit()
	input_stage+=1

func click_test(p: Vector2):
	var e=InputEventMouseButton.new()
	e.button_index=MOUSE_BUTTON_LEFT
	e.pressed=true
	e.position=get_viewport().get_final_transform()*p
	Input.parse_input_event(e)

func _process(dt):
	if web_window!=null and web_window.regattaHidden and not web_entry_preparing:
		if not background_suspended:
			background_suspended=true
			viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
			music.stream_paused=true
			sfx.tick(0,false,0,false,false,true,muted)
		return
	if background_suspended:
		background_suspended=false
		dt=minf(dt,.05)
		music.stream_paused=paused or web_waiting_for_entry
	if perf_review:perf_frame_start=Time.get_ticks_usec()
	if web_waiting_for_entry:
		if not JavaScriptBridge.eval("window.regattaEntered === true",true):return
		web_waiting_for_entry=false
		music.stream_paused=false
	update_track_preparation()
	sfx.frozen=paused
	sfx.silent=muted
	update_music_track()
	clock += dt
	var render_world=state in ['select','race','result']
	if state=='select' and last_visual_state!='select':
		place(player,distance,0)
		cam.position=player.position+tangent(distance)*7.5+side(distance)*3+Vector3.UP*3.8
		cam.look_at(player.position+Vector3.UP*.7)
	if render_world:
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		cover_preview_warmed=true
	elif not cover_preview_warmed:
		place(player,distance,0)
		cam.position=player.position+tangent(distance)*7.5+side(distance)*3+Vector3.UP*3.8
		cam.look_at(player.position+Vector3.UP*.7)
		viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
		cover_preview_warmed=true
	else:viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	last_visual_state=state
	for o in opponents:
		o.node.visible=state=='race' and mode!=2
	if not paused:
		water_clock+=dt
		if render_world:
			course.tick(self,dt)
			update_item_effects(dt)
			boat_contacts.tick(dt)
	flash = maxf(0,flash-dt)
	if state=='race':
		if not paused:
			var before_countdown=countdown
			countdown -= dt
			for mark in [3.0,2.0,1.0,0.0]:
				if before_countdown>mark and countdown<=mark:sfx.cue('go' if mark==0 else 'count')
			if before_countdown>0 and countdown<=0:request_cheer('出发，加油！')
			if countdown<=0: simulate(dt)
	elif state=='select':
		distance += dt*12
		place(player,distance,0)
		animate_boat(player,0)
	if not paused and render_world:
		var wake_started=Time.get_ticks_usec() if perf_review else 0
		update_wakes(dt)
		if perf_review:perf_wake_us+=Time.get_ticks_usec()-wake_started
	if state=='result':animate_boat(player,0)
	update_captain_actions(dt)
	cam.h_offset=lerpf(cam.h_offset,-1.9 if state in ['select','result'] else sin(water_clock*45)*impact_time*.18,dt*5)
	if player.has_node('ShieldVisual'):
		var ring=player.get_node('ShieldVisual')
		ring.visible=shield_time>0 or shield_pop_time>0
		var burst=1-shield_pop_time/.35 if shield_pop_time>0 else 0.0
		ring.scale=Vector3(1+burst*.4,1,1.45*(1+burst*.4))
		ring.material_override.albedo_color.a=1.0 if shield_time>0 else shield_pop_time/.35
	var target = player.position
	var fwd = tangent(distance)
	var desired = target-fwd*8.5+Vector3.UP*4.6
	if state in ['title','menu','select','result']:
		desired=target+fwd*7.5+side(distance)*3.0+Vector3.UP*3.8
		cam.position=cam.position.lerp(desired,1-exp(-dt*4)) if clock>0.1 else desired
		cam.look_at(target+Vector3.UP*0.7)
	else:
		cam.position = cam.position.lerp(desired,1-exp(-dt*7)) if clock>0.1 else desired
		cam.look_at(target+fwd*7+Vector3.UP*0.85)
	cam.fov = lerpf(cam.fov,68.0 if boost>0 and state=='race' else 58.0,dt*3)
	hud.queue_redraw()
	sfx.tick(dt,state=='race' and countdown<=0,velocity,boost>0,charge>0,paused,muted)
	if showcase: run_showcase()
	if input_test: run_input_test()
	if art_review: run_art_review()
	if test_mode: run_tests(dt)
	if animation_review: run_motion_test(dt)
	if face_review: run_face_review()
	if perf_review:publish_perf(dt)

func publish_perf(dt: float):
	perf_process_us+=Time.get_ticks_usec()-perf_frame_start
	perf_frames+=1
	perf_elapsed+=dt
	if perf_elapsed<1.0:return
	var sample={'state':state,'fps':perf_frames/perf_elapsed,'game_ms':perf_process_us/1000.0/perf_frames,'wake_ms':perf_wake_us/1000.0/perf_frames,'draws':Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),'primitives':Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
	if OS.has_feature('web'):JavaScriptBridge.eval("window.regattaPerf=window.regattaPerf||[];window.regattaPerf.push("+JSON.stringify(sample)+")",true)
	else:print('PERF ',sample)
	perf_frames=0;perf_elapsed=0;perf_process_us=0;perf_wake_us=0


func update_music_track():
	for fading in music_fades:
		if is_instance_valid(fading): fading.stream_paused=paused
	var wanted="bubble-sprint" if state=='race' else "harbor-day"
	if wanted==music_track:return
	var stream=load('res://assets/boats/'+wanted+'.wav') as AudioStreamWAV
	if stream==null:return
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
	var outgoing=music
	music_fades.append(outgoing)
	music=AudioStreamPlayer.new()
	if OS.has_feature("web"):music.playback_type=AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music)
	music.stream=stream
	music.volume_db=-80
	music.stream_paused=paused
	music.play()
	music_track=wanted
	music_bpm=RACE_MUSIC_BPM if state=='race' else MUSIC_BPM
	var fade=create_tween().set_parallel(true)
	fade.tween_method(func(db):
		if is_instance_valid(outgoing):outgoing.volume_db=-80.0 if muted else db, outgoing.volume_db,-80.0,0.45)
	var incoming=music
	fade.tween_method(func(db):
		if is_instance_valid(incoming):incoming.volume_db=-80.0 if muted else db, -80.0,-13.0,0.45)
	fade.chain().tween_callback(func():
		music_fades.erase(outgoing)
		outgoing.queue_free())

func request_cheer(words: String):
	if paused or cheer_cooldown>0 or state=='result':return
	player.get_node('Captain').request('cheer')
	cheer_cooldown=4.0
	cheer_text_timer=1.9
	cheer_text=words

func update_captain_actions(dt: float):
	if paused or state not in ['select','race','result']:return
	gesture_clock+=dt
	cheer_cooldown=maxf(0,cheer_cooldown-dt)
	cheer_text_timer=maxf(0,cheer_text_timer-dt)
	var seconds=gesture_clock
	var rhythm_on=false
	if music!=null and music.playing:
		seconds=maxf(0,music.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
		rhythm_on=not muted
	music_beats=seconds*music_bpm/60.0
	var context='driving' if state=='race' and countdown<=0 else 'idle'
	if state=='result':context='victory' if rank==1 else 'finish'
	player.get_node('Captain').tick(dt,music_beats,rhythm_on,context,steering if state=='race' else 0.0)
	if state=='race' and mode!=2:
		for i in range(opponents.size()):
			var k=opponents[i].node
			k.get_node('Captain').tick(dt,music_beats+float(i)*0.12,rhythm_on,'driving')

func animate_boat(k: Node3D,phase: float):
	k.position.y=0.02+sin(water_clock*2.9+phase)*0.085
	k.rotation.x=sin(water_clock*2.3+phase)*0.025
	k.rotation.z=sin(water_clock*2.0+phase)*0.025
	if k==player and state=='race' and air_time<=0:k.position.y+=course.boat_ramp_height(self)
	if k==player and air_time>0:
		k.position.y+=1.55*(air_time/.9)+sin(PI*(1-air_time/.9))*1.8
		k.rotation.x-=sin(TAU*(1-air_time/.9))*.12

func add_wake(k: Node3D,speed: float):
	var boat_id=str(k.get_instance_id())
	if speed<3:
		for sign_x in [-1,0,1]:wake_heads.erase(boat_id+':'+str(sign_x))
		wake_samples.erase(boat_id)
		return
	var behind=k.global_transform.basis.z
	behind.y=0
	behind=behind.normalized()
	var right=k.global_transform.basis.x
	right.y=0
	right=right.normalized()
	var stern=k.position+behind*1.25
	stern.y=0.13
	var strength=smoothstep(2.0,12.0,speed)
	var now={'p':stern,'right':right,'time':water_clock,'s':0.0,'strength':strength}
	if not wake_samples.has(boat_id) or wake_samples[boat_id].p.distance_to(stern)>15:
		# Restart after a teleport, without drawing a ribbon across the course.
		wakes=wakes.filter(func(w):return w.boat!=boat_id)
		wake_samples[boat_id]=now
		append_wake_section(boat_id,now)
	var previous=wake_samples[boat_id]
	var distance_to_head=previous.p.distance_to(stern)
	var steps=int(distance_to_head/0.40)
	for i in range(1,steps+1):
		var fraction=float(i)*0.40/distance_to_head
		var section={'p':previous.p.lerp(stern,fraction),'right':previous.right.lerp(right,fraction).normalized(),'time':lerpf(previous.time,water_clock,fraction),'s':previous.s+float(i)*.40,'strength':lerpf(previous.strength,strength,fraction)}
		append_wake_section(boat_id,section)
		wake_samples[boat_id]=section
	wake_distances[boat_id]=previous.s+distance_to_head
	for sign_x in [-1,0,1]:
		wake_heads[boat_id+':'+str(sign_x)]={'p':stern+right*sign_x*.90,'right':right,'sign':sign_x,'age':0.0,'born':water_clock,'boat':boat_id,'s':wake_distances[boat_id],'strength':strength,'id':boat_id+':'+str(sign_x)}

func append_wake_section(boat_id: String,section: Dictionary):
	for sign_x in [-1,0,1]:
		wakes.append({'p':section.p+section.right*sign_x*.90,'right':section.right,'sign':sign_x,'age':water_clock-section.time,'born':section.time,'boat':boat_id,'s':section.s,'strength':section.strength,'id':boat_id+':'+str(sign_x)})

func update_wakes(_dt: float):
	wake_heads.clear()
	if state=='race' and countdown<=0:
		if air_time<=.1:add_wake(player,velocity)
		if mode!=2:
			for o in opponents:add_wake(o.node,o.get('velocity',0))
	for w in wakes:w.age=water_clock-w.born
	wakes=wakes.filter(func(w):return w.age<(0.65 if w.sign==0 else 0.95))
	var groups={}
	for w in wakes:
		if not groups.has(w.id):groups[w.id]=[]
		groups[w.id].append(w)
	# A live cross-section joins the sampled ribbon to the moving hull every frame.
	for id in wake_heads:
		if groups.has(id):groups[id].append(wake_heads[id])
	if groups.is_empty():
		for c in wake_root.get_children():c.hide()
		return
	# Share each ribbon cross-section between adjacent triangles. Build packed
	# channels directly instead of dispatching SurfaceTool calls per vertex.
	var vertices=PackedVector3Array()
	var colors=PackedColorArray()
	var uvs=PackedVector2Array()
	var indices=PackedInt32Array()
	for group in groups.values():
		if group.size()<2:continue
		var base=vertices.size()
		for i in range(group.size()):
			var w=group[i]
			var life=0.65 if w.sign==0 else 0.95
			var t=w.age/life
			var p=w.p+w.right*w.sign*w.age*0.9
			p.y=0.17+sin(water_clock*2+p.x*0.13+p.z*0.17)*0.025
			var downstream=maxf(0,wake_distances.get(w.boat,w.s)-w.s)
			var emerge=smoothstep(0.0,1.5,downstream)
			var width=lerpf(0.08,0.72 if w.sign==0 else 0.40,emerge)+w.age*(1.65 if w.sign==0 else 1.15)
			var alpha=(0.30 if w.sign==0 else 0.38)*emerge*pow(1-t,2.0)*w.strength
			var foam_data=Color(1.0 if w.sign==0 else 0.0,t,w.age,alpha)
			vertices.append(p-w.right*width);vertices.append(p+w.right*width)
			colors.append(foam_data);colors.append(foam_data)
			uvs.append(Vector2(0,w.s));uvs.append(Vector2(1,w.s))
			if i>0:
				var previous=base+(i-1)*2
				for q in [previous,previous+2,previous+3,previous,previous+3,previous+1]:indices.append(q)
	if indices.is_empty():
		for c in wake_root.get_children():c.hide()
		return
	var mesh: MeshInstance3D
	if wake_root.get_child_count()==0:
		mesh=MeshInstance3D.new()
		var m=ShaderMaterial.new()
		m.shader=load('res://shaders/foam.gdshader')
		mesh.material_override=m
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.mesh=ArrayMesh.new()
		wake_root.add_child(mesh)
	else:mesh=wake_root.get_child(0)
	mesh.show()
	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	mesh.mesh.clear_surfaces()
	mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)

func key_event(key: Key):
	var e=InputEventKey.new()
	e.pressed=true
	e.keycode=key
	_input(e)

func run_showcase():
	if clock>1 and test_stage==0:
		state='select'
		distance=45
		test_stage=1
	elif clock>4 and test_stage==1:
		get_viewport().get_texture().get_image().save_png('res://captures/cozy-select.png')
		start_race()
		countdown=-1
		test_stage=2
	elif clock>10 and test_stage==2:
		print('COZY RACE FPS: ',Engine.get_frames_per_second())
		get_viewport().get_texture().get_image().save_png('res://captures/cozy-race.png')
		distance=330
		test_stage=3
	elif clock>12 and test_stage==3:
		get_viewport().get_texture().get_image().save_png('res://captures/cozy-harbor.png')
		get_tree().quit()

func run_art_review():
	if review_stage==0:
		state='select'
		distance=45
		racer=0
		refresh_captain()
		review_stage=1
	if clock>review_stage*1.2:
		get_viewport().get_texture().get_image().save_png('res://captures/captain-%d.png' % racer)
		if racer==7:
			print('ART REVIEW: all eight captains captured in the default scene')
			get_tree().quit()
		else:
			racer+=1
			refresh_captain()
			review_stage+=1

func verify_short_arms():
	var rig=player.get_node('Captain')
	for i in range(2):
		var arm=rig.left if i==0 else rig.right
		var shoulder: Vector3=rig.rests[arm.name].origin
		var paw: Vector3=arm.transform*rig.paws[i].position
		assert(arm.position.distance_to(shoulder)<0.001,'Shoulders must stay attached to the body')
		assert(paw.distance_to(shoulder)<0.43,'Paws must remain within short-arm reach')
		assert(rig.sleeves[i].scale.y<0.43,'Sleeves must not stretch during gestures')

func run_face_review():
	if face_stage==0:
		state='select'
		distance=45
		DirAccess.make_dir_recursive_absolute('res://captures/face')
		face_stage=1
		face_stage_started=clock
	var rig=player.get_node('Captain')
	if clock-face_stage_started>1.0 and face_stage==1:
		key_event(KEY_H)
		face_stage=2
		face_stage_started=clock
	if face_stage==2 and maxf(rig.face.closures.x,rig.face.closures.y)>0.95 and minf(rig.face.closures.x,rig.face.closures.y)<0.1:
		face_stage=3
		face_stage_started=clock
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png('res://captures/face-hello.png')
	if clock-face_stage_started>1.4 and face_stage==3:
		key_event(KEY_C)
		face_stage=4
		face_stage_started=clock
	if clock-face_stage_started>0.7 and face_stage==4 and rig.face.happiness>0.5:
		get_viewport().get_texture().get_image().save_png('res://captures/face-happy.png')
		face_stage=5
		face_stage_started=clock
	if clock-face_stage_started>0.8 and face_stage==5:
		start_race()
		countdown=-1
		velocity=34
		race_time=96.8
		distance=LENGTH*3-0.05
		for o in opponents:o.s=distance-30
		face_stage=6
		face_stage_started=clock
	if clock-face_stage_started>1.5 and face_stage==6 and state=='result' and rig.face.happiness>0.95:
		get_viewport().get_texture().get_image().save_png('res://captures/face-victory.png')
		face_stage=7
		face_stage_started=clock
	if clock>30:
		push_error('Facial review timed out at stage %d' % face_stage)
		get_tree().quit(1)
		return
	if face_stage==7 and clock-face_stage_started>2.5:
		var timing=FileAccess.open('res://captures/face/timing.txt',FileAccess.WRITE)
		for i in range(face_timings.size()-1):
			timing.store_line("file 'frame-%04d.png'" % i)
			timing.store_line('duration %.6f' % (face_timings[i+1]-face_timings[i]))
		timing.store_line("file 'frame-%04d.png'" % (face_timings.size()-1))
		timing.close()
		var meta=FileAccess.open('res://captures/face/audio-timing.json',FileAccess.WRITE)
		meta.store_string(JSON.stringify({'audio_start':face_audio_start,'duration':face_timings[-1]-face_timings[0]}))
		meta.close()
		print('FACE REVIEW PASS: greeting blink, happy expression, winning expression captured in default scene')
		get_tree().quit()
	if clock>0.8 and clock>=face_next_capture:
		get_viewport().get_texture().get_image().save_png('res://captures/face/frame-%04d.png' % face_frames)
		if face_frames==0:face_audio_start=maxf(0,music.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
		face_timings.append(clock)
		face_frames+=1
		face_next_capture=clock+1.0/12

func run_motion_test(dt: float):
	if motion_stage==0:
		state='select'
		distance=45
		DirAccess.make_dir_recursive_absolute('res://captures/motion')
		motion_stage=1
	if clock>1.4 and motion_stage==1:
		motion_rest_pose=player.get_node('Captain/Torso').transform
		motion_stage=2
	if clock>1.8 and motion_stage==2:
		assert(not player.get_node('Captain/Torso').transform.is_equal_approx(motion_rest_pose),'Music sway must move the seated torso')
		request_cheer('加油，船长！')
		motion_stage=3
	if clock>2.6 and motion_stage==3:
		var cheer_rig=player.get_node('Captain')
		var cheer_tip: Vector3=cheer_rig.right.transform*cheer_rig.paws[1].position
		var cheer_rest: Vector3=cheer_rig.rests.ArmRight*cheer_rig.paws[1].position
		assert(cheer_tip.y>cheer_rest.y+0.05,'Cheer must visibly raise the short paw')
		assert(cheer_rig.pose_is_clear(),'Cheer must leave clearance around the face')
		assert(absf(player.get_node('Captain/Torso/ArmLeft').rotation.x)<0.15,'Driving paw must stay on the helm')
		verify_short_arms()
		get_viewport().get_texture().get_image().save_png('res://captures/motion-cheer.png')
		paused=true
		music.stream_paused=true
		motion_audio_meta['pause_clock']=clock
		motion_pause_pose=player.get_node('Captain/Torso/ArmRight').transform
		motion_pause_time=gesture_clock
		motion_stage=4
	if clock>2.95 and motion_stage==4:
		assert(player.get_node('Captain/Torso/ArmRight').transform.is_equal_approx(motion_pause_pose),'Pause must freeze gesture')
		assert(gesture_clock==motion_pause_time)
		motion_audio_meta['resume_clock']=clock
		paused=false
		music.stream_paused=false
		motion_stage=5
	if clock>4.2 and motion_stage==5:
		start_race()
		assert(player.get_node('Captain').gesture=='','Restart must clear emotes')
		countdown=-1
		velocity=34
		race_time=96.8
		distance=LENGTH*3-0.05
		for o in opponents:o.s=distance-30
		motion_stage=6
	if clock>5.0 and motion_stage==6:
		assert(state=='result' and rank==1,'Actual finish should select winning animation')
		assert(player.get_node('Captain').gesture=='victory')
		motion_stage=7
	if clock>6.2 and motion_stage==7:
		var win_rig=player.get_node('Captain')
		for i in range(2):
			var arm=win_rig.left if i==0 else win_rig.right
			var tip: Vector3=arm.transform*win_rig.paws[i].position
			var rest_tip: Vector3=win_rig.rests[arm.name]*win_rig.paws[i].position
			assert(tip.y>rest_tip.y+0.04,'Winning paw should lift without crossing the face')
		assert(win_rig.pose_is_clear())
		verify_short_arms()
		get_viewport().get_texture().get_image().save_png('res://captures/motion-victory.png')
		motion_stage=8
	if clock>8.3 and motion_stage==8:
		rank=4
		motion_stage=9
	if clock>8.7 and motion_stage==9:
		assert(player.get_node('Captain').gesture=='finish','Nonwinning finish should not claim champion')
		motion_stage=10
	if clock>9.4:
		var timing=FileAccess.open('res://captures/motion/timing.txt',FileAccess.WRITE)
		for i in range(motion_timings.size()-1):
			timing.store_line("file 'frame-%04d.png'" % i)
			timing.store_line('duration %.6f' % (motion_timings[i+1]-motion_timings[i]))
		timing.store_line("file 'frame-%04d.png'" % (motion_timings.size()-1))
		timing.close()
		motion_audio_meta['start_clock']=motion_timings[0]
		motion_audio_meta['duration']=motion_timings[-1]-motion_timings[0]
		var meta_file=FileAccess.open('res://captures/motion/audio-timing.json',FileAccess.WRITE)
		meta_file.store_string(JSON.stringify(motion_audio_meta))
		meta_file.close()
		print('MOTION TEST PASS: music sway, one-paw cheer, pause freeze, restart reset, real finish, winning two-paw celebration, nonwinner wave')
		get_tree().quit()
	if clock>0.8 and clock>=motion_next_capture:
		get_viewport().get_texture().get_image().save_png('res://captures/motion/frame-%04d.png' % motion_frames)
		if motion_frames==0:motion_audio_meta['audio_start']=maxf(0,music.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
		motion_timings.append(clock)
		motion_frames+=1
		motion_next_capture=clock+1.0/12

func run_tests(dt: float):
	if clock>1 and test_stage==0:
		countdown=-1
		test_stage=1
	if clock>4 and test_stage==1:
		assert(velocity>0 and distance>20)
		pause_snapshot=Vector2(distance,race_time)
		key_event(KEY_ESCAPE)
		assert(paused)
		test_stage=8
	if clock>4.35 and test_stage==8:
		assert(is_equal_approx(distance,pause_snapshot.x) and is_equal_approx(race_time,pause_snapshot.y))
		key_event(KEY_ESCAPE)
		physical_test_key(KEY_RIGHT,true)
		physical_test_key(KEY_SHIFT,true)
		test_stage=9
	if clock>5.1 and test_stage==9:
		assert(charge>0.4)
		physical_test_key(KEY_RIGHT,false)
		physical_test_key(KEY_SHIFT,false)
		test_stage=10
	if clock>5.3 and test_stage==10:
		assert(boost>0)
		item=0
		key_event(KEY_SPACE)
		assert(boost>0 and item==-1)
		var b=boxes[0]
		b.taken_lap=-1
		item=-1
		distance=b.s-0.1
		lateral=b.lane
		pickup_cool=0
		boost=0
		test_stage=2
	if clock>5.55 and test_stage==2:
		assert(item>=0)
		if DisplayServer.get_name()!='headless':get_viewport().get_texture().get_image().save_png('res://captures/boats-test-race.png')
		distance=LENGTH*3-0.1
		test_stage=3
	if test_stage==3 and state=='result':
		assert(cup_points>0)
		if cup_round<2:
			key_event(KEY_ENTER)
			if pending_start:test_stage=11
			else:
				assert(state=='race')
				countdown=-1
				velocity=40
				distance=LENGTH*3-0.1
		else:
			mode=2
			start_race()
			assert(not opponents[0].node.visible)
			print('BOAT TEST PASS: acceleration, multi-frame pause, drift charge/release, pickup, item consumption, three-lap finish, three-round cup, solo mode')
			state='select'
			test_stage=4
	if test_stage==11 and state=='race':
		countdown=-1
		velocity=40
		distance=LENGTH*3-.1
		test_stage=3
	if test_stage==4 and clock>7:
		if DisplayServer.get_name()!='headless':get_viewport().get_texture().get_image().save_png('res://captures/boats-select.png')
		get_tree().quit()

func physical_test_key(key: Key,down: bool):
	var e=InputEventKey.new()
	e.keycode=key
	e.physical_keycode=key
	e.pressed=down
	Input.parse_input_event(e)

func simulate(dt: float):
	var previous_distance=distance
	race_time+=dt
	boost=maxf(boost-dt,0)
	pickup_cool=maxf(0,pickup_cool-dt)
	var throttle = Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W) or test_mode or showcase
	var brake = Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S)
	var steer = float(Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
	var drift = Input.is_physical_key_pressed(KEY_SHIFT) and abs(steer)>0 and velocity>15
	steering=lerpf(steering,steer,1-exp(-dt*4.0))
	var top = 47.0 if boost>0 else 34.0
	if abs(lateral)>13.0: top*=0.75
	velocity=move_toward(velocity,top if throttle else 0.0,dt*(10 if throttle else 3.2))
	if brake: velocity=move_toward(velocity,0,dt*20)
	var curve = tangent(distance).signed_angle_to(tangent(distance+8),Vector3.UP)
	var lateral_target=steering*velocity*(0.33 if drift else 0.25)-curve*velocity*0.7
	lateral_speed=lerpf(lateral_speed,lateral_target,1-exp(-dt*(1.65 if drift else 3.5)))
	lateral+=lateral_speed*dt
	if abs(lateral)<13.6:
		wall_contact=false
		wall_protected=false
	if abs(lateral)>14.0:
		lateral=clampf(lateral,-14.0,14.0)
		if velocity>4 and not wall_contact:
			wall_protected=course.absorb(self)
			if not wall_protected:sfx.cue('collision',clampf(velocity/30.0,.35,1.0),signf(lateral))
		wall_contact=true
		lateral_speed*=-0.35
		if not wall_protected:velocity*=0.96
	if drift:
		charge=minf(2.0,charge+dt)
		if charge>.6 and not charge_ready:
			charge_ready=true
			sfx.cue('charge')
	elif charge>0:
		if charge>0.6:
			boost=maxf(boost,charge*0.9)
			sfx.cue('boost')
			request_cheer('乘浪，冲呀！')
		charge=0
		charge_ready=false
	distance+=velocity*dt
	var previous_lap=lap
	lap=mini(3,int(distance/LENGTH)+1)
	if lap>previous_lap:
		sfx.cue('lap')
		request_cheer('最后一圈，加油！' if lap==3 else '再接再厉！')
	place(player,distance,lateral)
	player.rotation.y-=steering*(0.42 if drift else 0.22)
	animate_boat(player,0)
	player.rotation.z-=steering*minf(velocity/30.0,1.0)*0.13
	player.rotation.x-=minf(velocity/1000.0,0.045)
	rank=1
	for i in range(7):
		var o=opponents[i]
		race_ai.step(self,o,i,dt)
		place(o.node,o.s,o.lane)
		animate_boat(o.node,float(i))
		if o.air_time>0:o.node.position.y+=1.55*(o.air_time/.9)+sin(PI*(1-o.air_time/.9))*1.8
		else:o.node.position.y+=course.ramp_surface_height(self,o.s,o.lane)
		o.node.rotation.z-=o.steer*.10
		o.node.get_node("ShieldVisual").visible=o.shield
	boat_contacts.solve(self,dt)
	# Apply corrected positions in this frame, keeping bobbing, banking and jump height.
	var player_y=player.position.y
	place(player,distance,lateral)
	player.position.y=player_y
	player.rotation.y-=steering*(0.42 if drift else 0.22)
	rank=1
	for o in opponents:
		var boat_y=o.node.position.y
		place(o.node,o.s,o.lane)
		o.node.position.y=boat_y
		if o.s>distance and mode!=2:rank+=1
	course.interact(self,previous_distance)
	if distance>=LENGTH*3:
		sfx.cue('finish')
		state='result'
		velocity=0
		cheer_text_timer=0
		if mode==0: cup_points += [15,12,10,8,6,4,2,1][rank-1]
		if best==0 or race_time<best:
			best=race_time
			if not animation_review and not face_review:
				var f=FileAccess.open('user://test_record.txt' if test_mode else 'user://boat_best_v1.txt',FileAccess.WRITE)
				if f:f.store_string(str(best))


func next_gift()->int:
	var result=gift_pickups%3
	gift_pickups+=1
	return result

func use_item()->bool:
	if state!='race' or paused:return false
	if item<0:
		hud.feedback('empty')
		return false
	if item==1:
		var targets=[]
		var obstacles=[]
		if mode!=2:
			for o in opponents:
				if o.s-distance>=-20 and o.s-distance<85 and absf(o.lane-lateral)<7:targets.append(o)
		for h in course.hazards:
			var ahead=wrapf(h.s-distance,-LENGTH*.5,LENGTH*.5)
			if ahead>=0 and ahead<70 and absf(h.lane-lateral)<7 and h.get('disabled_until',0)<=water_clock:obstacles.append(h)
		if targets.is_empty() and obstacles.is_empty():
			hud.feedback('no_target',1)
			return false
		for o in targets:
			if o.get("shield",false):o.shield=false
			else:o.hit=2.2
		for h in obstacles:h.disabled_until=water_clock+5.0
		wave_time=.85
		wave_s=distance+2
		wave_lane=lateral
		create_wave_visual()
		sfx.cue('item')
		hud.feedback('wave_hit',1)
	elif item==0:
		boost=maxf(boost,3.0)
		lemon_time=3.0
		velocity=maxf(velocity,42)
		sfx.cue('boost')
		hud.feedback('boost',0)
	else:
		shield_time=7.0
		sfx.cue('item')
		hud.feedback('shield',2)
	item=-1
	request_cheer('冲呀！')
	return true

func create_wave_visual():
	if is_instance_valid(wave_visual):wave_visual.queue_free()
	wave_visual=Node3D.new()
	world.add_child(wave_visual)
	for row in range(3):
		var pts=[]
		for j in range(17):
			var x=(j-8)*.65
			pts.append(Vector3(x,.20+sin(float(j)/16*PI)*.32,.06*x*x+row*.6))
		var crest=art.tube(wave_visual,pts,art.equal_radii(17,.14 if row==0 else .08),Color('#c3f5e6'))
		var material=crest.material_override.duplicate() as StandardMaterial3D
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		crest.material_override=material
		crest.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	place(wave_visual,wave_s,wave_lane)

func update_item_effects(dt: float):
	shield_pop_time=maxf(0,shield_pop_time-dt)
	lemon_time=maxf(0,lemon_time-dt)
	item_notice_time=maxf(0,item_notice_time-dt)
	if wave_time<=0:return
	wave_time=maxf(0,wave_time-dt)
	if not is_instance_valid(wave_visual):return
	var elapsed=.85-wave_time
	place(wave_visual,wave_s+elapsed*65,wave_lane)
	wave_visual.scale.x=1+elapsed*.6
	for child in wave_visual.get_children():
		var material=child.material_override as StandardMaterial3D
		material.albedo_color.a=smoothstep(0,.12,wave_time)*.7
	if wave_time==0:wave_visual.hide()

func _exit_tree():
	# Partially prepared courses live outside the tree until ready.
	for builder in track_builders.values():
		if is_instance_valid(builder.root):builder.root.free()
	track_builders.clear()

func exit_game():
	if OS.has_feature('web'):
		JavaScriptBridge.eval('window.location.reload()',true)
	else:get_tree().quit()
