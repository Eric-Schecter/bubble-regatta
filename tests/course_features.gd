extends SceneTree
var g

func _initialize():call_deferred('run')

func encounter(item,offset: float=0):
	g.distance=item.s+offset
	g.lateral=item.lane
	g.velocity=34
	g.lateral_speed=0
	g.air_time=0
	g.course.interact(g,g.distance-8)

func run():
	g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.mode=2
	g.start_race()
	g.countdown=-1
	g.best=.01
	assert(g.course.hazards.size()>=12 and g.course.shells.size()>=40)
	assert(g.course.pads.size()==8 and g.course.ramps.size()==4)
	var gift=g.boxes[0]
	encounter(gift)
	assert(g.item>=0 and not gift.node.visible)
	var item=g.item
	encounter(gift)
	assert(g.item==item)
	g.item=-1
	g.pickup_cool=0
	g.distance=gift.s+g.LENGTH
	g.course.interact(g,g.distance-8)
	assert(g.item>=0,'Gift must be available next lap')
	var shell=g.course.shells[0]
	encounter(shell)
	assert(g.shell_count==1)
	encounter(shell)
	assert(g.shell_count==1,'Shell cannot be farmed in the same lap')
	var h=g.course.hazards[0]
	g.boost=2
	encounter(h)
	assert(g.velocity<25 and g.boost==0 and g.impact_time>0)
	var speed=g.velocity
	g.course.interact(g,g.distance-.1)
	assert(g.velocity==speed,'Persistent contact must not repeatedly damage')
	h.touching=false
	g.shield_time=5
	encounter(h)
	assert(g.velocity==34 and g.shield_time==0,'Shield absorbs one obstacle collision')
	var pad=g.course.pads[0]
	encounter(pad)
	assert(g.boost>=2.5 and g.velocity>=39)
	pad.last_lap=-1
	g.paused=true
	var before=g.boost
	g._process(.1)
	assert(g.boost==before)
	g.paused=false
	g._process(0)
	var ramp=g.course.ramps[0]
	encounter(ramp,3.6)
	assert(g.air_time>.8 and g.boost>0)
	g.course.tick(g,.45)
	g.animate_boat(g.player,0)
	assert(g.player.position.y>1.5,'Ramp must produce a visible flight arc')
	g.course.tick(g,.5)
	assert(g.air_time==0 and g.sfx.events.get('land',0)>0)
	for collectible in g.course.shells.slice(1,5):encounter(collectible)
	assert(g.shell_count==5 and g.boost>=1.2,'Five shells must grant a useful boost reward')
	g.shield_time=5
	g.lateral=15
	g.velocity=34
	g.wall_contact=false
	g.simulate(.01)
	assert(g.shield_time==0 and g.wall_protected)
	for track in range(0 if '--quick' in OS.get_cmdline_user_args() else 3):
		g.track_id=track
		g.build_track()
		assert(g.course.hazards.size()>=12 and g.boxes.size()>=8)
	g.start_race()
	assert(g.shell_count==0 and g.shield_time==0 and g.air_time==0)
	for item_reset in g.boxes+g.course.shells:assert(item_reset.taken_lap==-1 and item_reset.node.visible)
	print('COURSE PASS: 3 layouts; gift and shell pickup/next-lap/reset, swept obstacle collision/contact cooldown, shield, boost pads, jump arc/landing and pause')
	quit()
