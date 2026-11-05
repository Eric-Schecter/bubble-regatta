extends RefCounted
# Small independent build jobs. The live course and its gameplay state remain untouched.
const N=560
const STEP=2.8
const LENGTH=N*STEP
var game
var art
var track_id=0
var boxes=[]
var course=preload('res://scripts/course_features.gd').new()
var root: Node3D
var rng=RandomNumberGenerator.new()
var phase=0
var cursor=0
var jobs=[]
var feature_jobs=[]
var attached_root: Node3D
var batch_plan={}
var job_index=0
var done=false
var build_us=0
var max_step_us=0
var max_step_phase=0

func _init(owner_game,id: int):
	game=owner_game
	art=game.art
	track_id=id
	rng.seed=124+id*9787
	root=Node3D.new()
	root.name='PreparingTrack'+str(id)
	root.visible=false

func center(s: float)->Vector3:return game.center_for(s,track_id)
func tangent(s: float)->Vector3:return (center(s+.5)-center(s-.5)).normalized()
func side(s: float)->Vector3:return tangent(s).cross(Vector3.UP).normalized()
func place(node: Node3D,s: float,lane: float):
	node.position=center(s)+side(s)*lane
	node.rotation.y=atan2(-tangent(s).x,-tangent(s).z)

func advance(budget_us: int=4000):
	var started=Time.get_ticks_usec()
	while not done:
		var phase_before=phase
		var step_start=Time.get_ticks_usec()
		step()
		var step_us=Time.get_ticks_usec()-step_start
		if step_us>max_step_us:max_step_us=step_us;max_step_phase=phase_before
		if Time.get_ticks_usec()-started>=budget_us:break
	build_us+=Time.get_ticks_usec()-started

func step():
	match phase:
		0:
			var water=MeshInstance3D.new()
			water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if not art.meshes.has('ocean_plane'):
				var plane=PlaneMesh.new()
				plane.size=Vector2(1800,1800)
				plane.subdivide_width=128
				plane.subdivide_depth=128
				art.meshes.ocean_plane=plane
			water.mesh=art.meshes.ocean_plane
			var material=ShaderMaterial.new()
			material.shader=load('res://shaders/water.gdshader')
			if track_id==1:
				material.set_shader_parameter('shallow_color',Color('#69c5bc'))
				material.set_shader_parameter('deep_color',Color('#278d9d'))
			elif track_id==2:
				material.set_shader_parameter('shallow_color',Color('#8acbd7'))
				material.set_shader_parameter('deep_color',Color('#548db8'))
			water.material_override=material
			root.add_child(water)
			phase=1
		1:
			var s=cursor*STEP
			for sign_x in [-1,1]:art.buoy(root,center(s)+side(s)*sign_x*14.0,cursor+(0 if sign_x<0 else 1))
			if cursor%28==0:
				var sign_x=-1 if cursor%56==0 else 1
				var p=center(s)+side(s)*sign_x*rng.randf_range(30,36)
				art.island(root,p,rng.randf_range(10,14),int(cursor/28))
			cursor+=7
			if cursor>=N:
				cursor=0
				course.begin_build()
				for i in range(8):feature_jobs.append_array(course.section_jobs(self,i))
				phase=2
		2:
			course.build_feature(self,root,feature_jobs[cursor])
			cursor+=1
			if cursor==feature_jobs.size():phase=3;cursor=0
		3:
			var f=tangent(0)
			for x in [-15.5,15.5]:
				var p=center(0)+side(0)*x
				game.cube(root,p+Vector3.UP*3.5,Vector3(.5,7,.5),Color('#fff5dc'))
				game.ball(root,p+Vector3.UP*7.4,Vector3(.9,.9,.9),Color('#f1bd68'))
			for i in range(20):
				var p=center(0)+side(0)*(i-9.5)*1.5+Vector3.UP*(6.8-.8*sin(float(i)/19*PI))
				var flag=game.cube(root,p,Vector3(1.3,.95,.12),game.COLORS[i%8])
				flag.rotation.y=atan2(-f.x,-f.z)
			art.island(root,Vector3.ZERO,64,100)
			phase=4
		4:
			var a=float(cursor)/8*TAU
			art.cottage(root,Vector3(sin(a)*34,1.3,cos(a)*26),cursor)
			cursor+=1
			if cursor==8:
				art.lighthouse(root,Vector3(0,1,-6))
				phase=5;cursor=0
		5:
			var harbor=int(cursor/6)
			var part=cursor%6
			var s=[55.0,200.0,350.0,800.0,1200.0][harbor]
			var shore=center(s)+side(s)*38
			if part==0:art.island(root,shore,22,int(s),false)
			elif part==1:art.lighthouse(root,shore+Vector3(2,1.8,3))
			elif part<5:
				var j=part-2
				var house=Node3D.new()
				root.add_child(house)
				house.position=shore+side(s)*(-9+j*8)+tangent(s)*(-5)
				house.rotation.y=atan2(side(s).x,side(s).z)
				art.cottage(house,Vector3(0,1.8,0),j)
			else:art.pier(root,center(s)+side(s)*19,atan2(side(s).x,side(s).z),18)
			cursor+=1
			if cursor==30:phase=6;cursor=0
		6:
			var p=Vector3(sin(float(cursor))*520,55+sin(cursor*3)*15,cos(float(cursor))*520)
			for j in range(3):game.ball(root,p+Vector3(j*13,abs(j-1)*-5,0),Vector3(36,19,19),Color('#fff8e7'))
			cursor+=1
			if cursor==18:phase=7
		7:
			if batch_plan.is_empty():batch_plan=art.begin_static_plan(root)
			art.advance_static_plan(batch_plan)
			if batch_plan.done:
				jobs=batch_plan.jobs
				batch_plan={}
				phase=8
		8:
			if job_index<jobs.size():
				art.apply_static_batch(root,jobs[job_index])
				job_index+=1
			else:
				jobs.clear()
				art.prune_empty_static(root)
				attached_root=Node3D.new()
				attached_root.name=root.name
				attached_root.hide()
				game.world.add_child(attached_root)
				phase=9
		9:
			if root.get_child_count()>0:
				var child=root.get_child(0)
				root.remove_child(child)
				attached_root.add_child(child)
			else:
				root.free()
				root=attached_root
				done=true

func progress()->float:
	if done:return 1.0
	if phase==1:return .05+float(cursor)/N*.35
	if phase==2:return .40+float(cursor)/maxi(1,feature_jobs.size())*.12
	if phase<7:return .52+float(phase-3)*.07
	if phase==7:return .75
	if phase==9:return .98
	return .80+float(job_index)/maxi(1,jobs.size())*.18

func entry()->Dictionary:
	return {'root':root,'boxes':boxes,'course':course,'cpu_ms':build_us/1000.0,'max_step_ms':max_step_us/1000.0,'max_step_phase':max_step_phase}
