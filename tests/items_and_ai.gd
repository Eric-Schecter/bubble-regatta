extends SceneTree
func _initialize():call_deferred('run')
func run():
	var g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.start_race()
	g.countdown=-1
	g.best=.01
	var gift=g.boxes[0]
	g.distance=gift.s+4
	g.lateral=gift.lane+2.3
	g.course.interact(g,gift.s-.1)
	assert(g.item==0 and gift.taken_lap==0,'First gift and a glancing high-speed pickup should work')
	g.velocity=25
	g.menu_click(Vector2(130,465))
	assert(g.item==-1 and g.boost>=3 and g.velocity>=42,'Clicking the inventory must immediately activate boost')
	g.item=0
	g.boost=0
	var physical_space=InputEventKey.new()
	physical_space.physical_keycode=KEY_SPACE
	physical_space.keycode=0
	physical_space.pressed=true
	g._input(physical_space)
	assert(g.item==-1 and g.boost==3,'Physical Space must work with an IME or non-Latin keycode')
	g.mode=2
	g.item=1
	for h in g.course.hazards:h.disabled_until=10000
	assert(not g.use_item() and g.item==1,'Empty wave cast must retain the item')
	for h in g.course.hazards:h.disabled_until=0
	g.mode=1
	var h=g.course.hazards[0]
	g.distance=h.s-15
	g.lateral=h.lane
	g.opponents[0].s=g.distance+20
	g.opponents[0].lane=g.lateral
	assert(g.use_item() and g.item==-1)
	assert(g.opponents[0].hit>0 and h.disabled_until>g.water_clock and g.wave_visual.visible)
	g.update_item_effects(1)
	assert(not g.wave_visual.visible)
	g.item=2
	g.use_item()
	g._process(0)
	assert(g.shield_time==7 and g.player.get_node('ShieldVisual').visible)
	assert(g.course.absorb(g) and g.shield_time==0)
	g.item=0
	g.paused=true
	assert(not g.use_item() and g.item==0)
	g.start_race()
	g.countdown=-1
	var max_jump=0.0
	var boosting=0
	var dt=1.0/30
	for frame in range(1800):
		g.water_clock+=dt
		g.distance=34.0*float(frame+1)*dt
		g.lateral=0
		g.course.tick(g,dt)
		for i in range(g.opponents.size()):
			var o=g.opponents[i]
			var previous=float(o.s)
			g.race_ai.step(g,o,i,dt)
			max_jump=maxf(max_jump,o.s-previous)
			if o.rush>0:boosting+=1
			assert(absf(o.lane)<=11.01)
	var ahead=0
	var best=0.0
	var pads=0
	var gifts=0
	for o in g.opponents:
		if o.s>g.distance:ahead+=1
		best=maxf(best,o.s)
		pads+=o.pad_claims.size()
		gifts+=o.gift_claims.size()
	print('AI benchmark: ordinary cruise rank ',ahead+1,'; fastest average ',best/60,'; pad claims ',pads,'; gifts ',gifts)
	assert(ahead>=2,'Holding ordinary top speed should no longer guarantee first place')
	assert(best<42*60,'AI must remain beatable with sustained skilled boosting')
	assert(max_jump<52*dt and boosting>0 and pads>0 and gifts>0,'AI must earn boosts without teleporting')
	var leader=g.opponents[0]
	leader.hit=1.5
	leader.velocity=35
	g.race_ai.step(g,leader,0,.5)
	assert(leader.velocity<30,'Waves must slow the stronger AI too')
	var launch=g.course.ramps[0]
	leader.s=launch.s+3.1
	leader.lane=launch.lane
	leader.velocity=34
	leader.hit=0
	leader.ramp_claims.clear()
	g.race_ai.step(g,leader,0,.04)
	assert(leader.air_time>0,'AI must launch at a ramp lip rather than passing through the board')
	print('ITEM/AI PASS: pickup tolerance, clickable instant boost, no-target wave retention, visible wave and obstacle clearing, shield, pause; 60 s pace benchmark: ',ahead,' opponents ahead of 34-speed cruise, ',pads,' pad uses, ',gifts,' gifts; fastest ',snappedf(best/60,.1),' average, no teleports, faster boosting remains competitive')
	# Let real-time music crossfades/audio callbacks finish before destroying the fixture.
	await create_timer(.7).timeout
	g.queue_free()
	await process_frame
	await process_frame
	quit()
