extends Node3D
# Poses are local offsets about the seated hips, neck and shoulder pivots.
var torso: Node3D
var head: Node3D
var left: Node3D
var right: Node3D
var rests={}
var gesture=''
var gesture_time=0.0
var duration=0.0
var local_time=0.0
var emote_strength=0.0
var face=preload("res://scripts/captain_face.gd").new()
var sleeves=[]
var paws=[]
var species=0
var head_inverse=Transform3D.IDENTITY
var blockers=[]
var clearance_corrections=0
var last_safe={}


func bind_rig():
	torso=get_node('Torso')
	head=torso.get_node('Head')
	left=torso.get_node('ArmLeft')
	right=torso.get_node('ArmRight')
	sleeves=[torso.get_node('SleeveLeft'),torso.get_node('SleeveRight')]
	for arm in [left,right]:
		for n in arm.get_children():
			if n.has_meta('paw_side'):paws.append(n)
	for n in [torso,head,left,right]:rests[n.name]=n.transform
	face.bind_face(head,species)
	# Exclusion ellipsoids live with the animated skull, cheeks, muzzle and tusks.
	blockers=[
		[Vector3(0,0.51,-0.05),Vector3(0.95,0.825,0.765)],
		[Vector3(0,0.34,-0.82),Vector3(0.48,0.28,0.28)],
		[Vector3(-0.62,0.32,-0.651),Vector3(0.20,0.105,0.05)],
		[Vector3(0.62,0.32,-0.651),Vector3(0.20,0.105,0.05)]
	]
	if species==2:
		for x in [-0.22,0.22]:blockers.append([Vector3(x,0.18,-0.93),Vector3(0.075,0.26,0.075)])
	if species==7:
		for x in [-0.40,0.40]:blockers.append([Vector3(x,0.53,-0.64),Vector3(0.41,0.435,0.14)])

func request(kind: String):
	gesture=kind
	gesture_time=0
	duration=1.9 if kind=='cheer' else (1.65 if kind=='wave' else 9999.0)

func tick(dt: float,beats: float,rhythm_on: bool,context: String,steer: float=0.0):
	if dt<=0:return
	local_time+=dt
	if context in ['victory','finish'] and gesture!=context:request(context)
	if context not in ['victory','finish'] and gesture in ['victory','finish']:
		gesture=''
	gesture_time+=dt
	if gesture_time>duration:gesture=''
	var rhythm=1.0 if rhythm_on else 0.0
	var sway=sin(beats*PI)
	var nod=sin(beats*TAU-0.25)
	var lively=0.45 if context=='driving' else 1.0
	var body_r=Vector3(0.012*nod*rhythm,0.025*sway*rhythm,0.075*sway*rhythm*lively)
	var head_r=Vector3(0.025*nod*rhythm,0.055*sin(beats*PI-0.3)*rhythm,-0.045*sin(beats*PI-0.35)*rhythm)
	var body_p=Vector3(0.018*sway*rhythm,0.014*(1-cos(beats*TAU))*rhythm+sin(local_time*1.8)*0.008,0)
	var left_r=Vector3.ZERO
	var right_r=Vector3.ZERO
	var left_p=Vector3.ZERO
	var right_p=Vector3.ZERO
	var strength=0.0
	if gesture in ['cheer','wave']:
		var t=gesture_time
		strength=smoothstep(0.12,0.38,t)*(1-smoothstep(duration-0.4,duration,t))
		var windup=sin(clampf(t/0.22,0,1)*PI)*0.07
		body_r.x+=windup
		body_r.z-=0.08*strength
		head_r.x-=0.075*strength*sin(maxf(0,t-0.3)*TAU*2)
		head_r.y-=0.15*strength
		var pump=0.5-0.5*cos(maxf(0,t-0.4)*TAU*2.5)
		var lift=smoothstep(0.18,0.65,strength)
		right_r=Vector3((1.20+0.12*pump)*lift,-0.05*strength,-1.08*strength)
		
		if gesture=='wave':right_r.z+=sin(t*TAU*3)*0.09*strength
	elif gesture in ['victory','finish']:
		var t=gesture_time
		strength=smoothstep(0.1,0.65,t)
		var pulse=0.5-0.5*cos(beats*TAU)
		body_p.y+=0.065*pulse*strength
		body_r.z=sin(beats*PI)*0.10*strength
		body_r.y=sin(beats*PI*0.5)*0.09*strength
		head_r.x-=0.07*pulse*strength
		head_r.z=-body_r.z*0.6
		right_r=Vector3(1.23+0.11*sin(beats*TAU),0,-1.08+sin(beats*TAU)*0.07)*strength
		
		if gesture=='victory':
			left_r=Vector3(1.23-0.11*sin(beats*TAU),0,1.08+sin(beats*TAU)*0.07)*strength
			
	# Race steering remains readable; gestures cannot move the hull or steering state.
	body_r.z-=steer*0.025
	emote_strength=strength
	apply_pose(torso,body_r,body_p,dt)
	apply_pose(head,head_r,Vector3.ZERO,dt)
	apply_pose(left,left_r,left_p,dt)
	apply_pose(right,right_r,right_p,dt)
	head_inverse=head.transform.affine_inverse()
	constrain_arm(left,paws[0],-1)
	constrain_arm(right,paws[1],1)
	var paw_now: Vector3=right.transform*paws[1].position
	var paw_rest: Vector3=rests.ArmRight*paws[1].position
	face.tick(dt,gesture,gesture_time,duration,paw_now.y-paw_rest.y)
	# Fixed shoulders and fixed short arm lengths; expression comes from rotation.
	for i in range(2):
		var arm=left if i==0 else right
		var shoulder: Vector3=rests[arm.name].origin
		var end: Vector3=arm.transform*paws[i].position
		var delta=end-shoulder
		if delta.length()>0.01:
			sleeves[i].position=(shoulder+end)*0.5
			sleeves[i].basis=Basis(Quaternion(Vector3.UP,delta.normalized()))
			sleeves[i].scale=Vector3(0.36,0.40,0.36)

func apply_pose(n: Node3D,r: Vector3,p: Vector3,dt: float):
	var rest: Transform3D=rests[n.name]
	var target=rest*Transform3D(Basis.from_euler(r),p)
	n.transform=n.transform.interpolate_with(target,1-exp(-dt*14))

func point_clear(p: Vector3,radius: float)->bool:
	var h=head_inverse*p
	for blocker in blockers:
		var q=(h-blocker[0])/(blocker[1]+Vector3.ONE*(radius+0.025))
		if q.length_squared()<1.0:return false
	var captain_p=torso.transform*p
	# Back of the windshield plus palm clearance; the wheel itself permits a grip.
	if absf(captain_p.x)<1.30 and captain_p.y<1.55+radius and captain_p.y>0.75-radius and captain_p.z<(-1.03+radius+0.03):return false
	return true

func direction_clear(shoulder: Vector3,direction: Vector3,length_v: float)->bool:
	if not point_clear(shoulder+direction*length_v,0.225):return false
	for t in [0.45,0.75]:
		if not point_clear(shoulder+direction*length_v*t,0.17):return false
	return true

func constrain_arm(arm: Node3D,paw: Node3D,sign_x: int):
	var shoulder: Vector3=rests[arm.name].origin
	var local_tip=paw.position
	var reach=local_tip.length()
	var desired: Vector3=(arm.basis*local_tip).normalized()
	if direction_clear(shoulder,desired,reach):
		last_safe[arm.name]=desired
		return
	clearance_corrections+=1
	# Project the desired fist direction onto nearby safe directions on the same
	# fixed-radius reach sphere. Test the actual interpolated pose, not just keyframes.
	var best=Vector3(sign_x*0.35,-0.60,-0.72).normalized()
	var best_score=-100.0
	if last_safe.has(arm.name):
		var previous: Vector3=last_safe[arm.name]
		if direction_clear(shoulder,previous,reach):
			best=previous
			best_score=previous.dot(desired)-maxf(0,previous.z)*0.10
	for i in range(96):
		var y=1.0-2.0*(float(i)+0.5)/96.0
		var angle=float(i)*2.39996323
		var radius=sqrt(maxf(0,1-y*y))
		var d=Vector3(cos(angle)*radius,y,sin(angle)*radius)
		if d.x*sign_x< -0.40:continue
		if not direction_clear(shoulder,d,reach):continue
		var score=d.dot(desired)-maxf(0,d.z)*0.10
		if score>best_score:best_score=score;best=d
	if best_score> -99:
		# Refine continuously toward the requested pose, avoiding coarse sample snaps.
		var lo=0.0
		var hi=1.0
		for step in range(10):
			var t=(lo+hi)*0.5
			if direction_clear(shoulder,best.slerp(desired,t).normalized(),reach):lo=t
			else:hi=t
		best=best.slerp(desired,lo*0.985).normalized()
		arm.basis=Basis(Quaternion(local_tip.normalized(),best))
		last_safe[arm.name]=best

func pose_is_clear()->bool:
	head_inverse=head.transform.affine_inverse()
	for i in range(2):
		var arm=left if i==0 else right
		var shoulder: Vector3=rests[arm.name].origin
		var d: Vector3=arm.basis*paws[i].position
		if not direction_clear(shoulder,d.normalized(),d.length()):return false
	return true
