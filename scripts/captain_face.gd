extends RefCounted
# Eye highlights and lids share an eye pivot, keeping blinks attached to the face.
var eye_parts=[]
var mouth: Node3D
var rng=RandomNumberGenerator.new()
var time=0.0
var next_blink=3.0
var blink_elapsed=-1.0
var happiness=0.0
var closures=Vector2.ZERO
var previous_gesture=''
var wink_side=1
var natural_blink_count=0
var greeting_triggered=false
var greeting_elapsed=-1.0
var previous_gesture_time=0.0

func bind_face(head: Node3D,species: int):
	rng.seed=16411+species*7919
	next_blink=rng.randf_range(2.6,5.2)
	wink_side=species%2
	for node in head.get_children():
		if node.has_meta('face_eye'):
			var open=node.get_node('OpenEye')
			var glint=node.get_node('Glint')
			eye_parts.append({'pivot':node,'open':open,'glint':glint,'lid':node.get_node('ClosedLid'),'scale':open.scale,'glint_scale':glint.scale,'glint_position':glint.position})
		elif node.has_meta('face_mouth'):mouth=node

func blink_curve(t: float)->float:
	if t<0 or t>0.285:return 0.0
	if t<0.065:return smoothstep(0,0.065,t)
	if t<0.125:return 1.0
	return 1-smoothstep(0.125,0.285,t)

func tick(dt: float,gesture: String,gesture_time: float,duration: float,greeting_lift: float=0.0):
	if dt<=0:return
	time+=dt
	var greeting=gesture=='wave'
	if gesture!=previous_gesture or (greeting and gesture_time<previous_gesture_time):
		if greeting:
			blink_elapsed=-1
			greeting_triggered=false
			greeting_elapsed=-1
			next_blink=time+rng.randf_range(2.8,5.0)
		previous_gesture=gesture
	previous_gesture_time=gesture_time
	if not greeting and time>=next_blink:
		blink_elapsed=0
		natural_blink_count+=1
		next_blink=time+rng.randf_range(2.7,5.3)
	if blink_elapsed>=0:
		blink_elapsed+=dt
		if blink_elapsed>0.285:blink_elapsed=-1
	var natural=blink_curve(blink_elapsed)
	closures=Vector2.ONE*natural
	if greeting:
		# One friendly wink starts when the actual short paw begins to rise.
		# Suppress the earlier two-eye blink and all idle blinks during the greeting.
		closures=Vector2.ZERO
		if not greeting_triggered and greeting_lift>0.025:
			greeting_triggered=true
			greeting_elapsed=0
		if greeting_elapsed>=0:
			greeting_elapsed+=dt
			closures[wink_side]=blink_curve(greeting_elapsed)
	var target=0.0
	if gesture=='victory':target=smoothstep(0.08,0.55,gesture_time)
	elif gesture=='cheer':target=0.65*smoothstep(0.1,0.35,gesture_time)*(1-smoothstep(duration-0.35,duration,gesture_time))
	elif greeting:target=0.28
	elif gesture=='finish':target=0.38
	happiness=lerpf(happiness,target,1-exp(-dt*9))
	for i in range(eye_parts.size()):
		var eye=eye_parts[i]
		var openness=1-closures[i]
		# Excitement opens the complete eye, including its attached highlight.
		eye.pivot.scale=Vector3(1+0.22*happiness,1+0.38*happiness,1+0.04*happiness)
		eye.open.scale=eye.scale*Vector3(1,maxf(0.04,openness),1)
		eye.open.visible=openness>0.13
		eye.glint.position=eye.glint_position*Vector3(1,openness,1)
		eye.glint.scale=eye.glint_scale
		eye.glint.visible=openness>0.60
		eye.lid.visible=openness<0.40
	if mouth!=null:mouth.scale=Vector3(1+0.10*happiness,0.76+0.36*happiness,1)
