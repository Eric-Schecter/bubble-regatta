extends RefCounted
# Honest race simulation: same distance/lane space, acceleration, hazards and track boosts.
# No teleporting or player-position speed multiplier.
func reset(o,index: int):
	o.speed=[31.8,32.5,33.4,34.3,35.1,35.8,36.4][index]
	o.velocity=0.0
	o.air_time=0.0
	o.ramp_claims={}
	o.rush=0.0
	o.hit=0.0
	o.hit_cool=0.0
	o.drift_charge=0.0
	o.steer=0.0
	o.collision_lateral=0.0
	o.cargo=-1
	o.gift_claims={}
	o.pad_claims={}
	o.shield=false
	o.item_cool=0.0

func step(g,o,index: int,dt: float):
	o.air_time=maxf(0,o.air_time-dt)
	o.hit=maxf(0,o.hit-dt)
	o.rush=maxf(0,o.rush-dt)
	o.hit_cool=maxf(0,o.hit_cool-dt)
	o.item_cool=maxf(0,o.item_cool-dt)
	var target=float(o.base_lane)
	var best=80.0
	# Some captains favor gifts, others favor the outside boost line.
	for pad in g.course.pads:
		var ahead=wrapf(pad.s-o.s,-g.LENGTH*.5,g.LENGTH*.5)
		if index>=2 and ahead>-3 and ahead<best and o.pad_claims.get(str(pad.s),-1)!=int(o.s/g.LENGTH):
			best=ahead
			target=pad.lane
	if o.cargo<0 and index%2==0:
		for gift in g.boxes:
			var ahead=wrapf(gift.s-o.s,-g.LENGTH*.5,g.LENGTH*.5)
			if ahead>0 and ahead<28 and o.gift_claims.get(str(gift.s),-1)!=int(o.s/g.LENGTH):target=gift.lane
	# Read the course ahead and leave enough room for the hull, including moving buoys.
	for h in g.course.hazards:
		var ahead=wrapf(h.s-o.s,-g.LENGTH*.5,g.LENGTH*.5)
		if h.get('disabled_until',0)>g.water_clock:continue
		if ahead>-5 and ahead<32 and absf(target-h.lane)<h.radius+1.2:
			target=clampf(h.lane+(-1 if o.lane<h.lane else 1)*(h.radius+2.0),-11,11)
	# Pass a nearby slower boat instead of remaining in its lane.
	for other in g.opponents:
		if other==o:continue
		var gap=other.s-o.s
		if gap>0 and gap<10 and absf(target-other.lane)<2.3 and o.velocity>other.get('velocity',0)+.3:
			target=clampf(other.lane+(-1 if o.lane<other.lane else 1)*3.2,-11,11)
	if g.distance-o.s>0 and g.distance-o.s<12 and absf(target-g.lateral)<2.2:
		target=clampf(g.lateral+(-1 if o.lane<g.lateral else 1)*3.4,-11,11)
	o.lane=clampf(o.lane+o.collision_lateral*dt,-13.65,13.65)
	o.collision_lateral=move_toward(float(o.collision_lateral),0,dt*9)
	var old_lane=float(o.lane)
	o.lane=move_toward(float(o.lane),target,dt*(5.8+float(index%3)*.35))
	o.steer=clampf((o.lane-old_lane)/maxf(dt,.001)/7,-1,1)
	var bend=absf(g.tangent(o.s).signed_angle_to(g.tangent(o.s+22),Vector3.UP))
	if bend>.065 and o.velocity>25:o.drift_charge=minf(1.5,o.drift_charge+dt)
	elif bend<.045 and o.drift_charge>.6:
		o.rush=maxf(o.rush,1.1)
		o.drift_charge=0
	var top=o.speed*clampf(1-bend*.30,.91,1.0)+(7.5 if o.rush>0 else 0.0)
	if o.hit>0:top=9
	o.velocity=move_toward(float(o.velocity),top,dt*(12.0 if o.hit<=0 else 35.0))
	var previous=float(o.s)
	o.s+=o.velocity*dt
	var lap_index=int(o.s/g.LENGTH)
	for pad in g.course.pads:
		if crossed(g,pad.s,previous,o.s,5.5) and absf(o.lane-pad.lane)<2.3 and o.pad_claims.get(str(pad.s),-1)!=lap_index:
			o.pad_claims[str(pad.s)]=lap_index
			o.rush=maxf(o.rush,2.6)
	for ramp in g.course.ramps:
		if crossed(g,ramp.s+3.6,previous,o.s,.7) and absf(o.lane-ramp.lane)<2.3 and o.ramp_claims.get(str(ramp.s),-1)!=lap_index:
			o.ramp_claims[str(ramp.s)]=lap_index
			o.air_time=.9
			o.rush=maxf(o.rush,2.6)
	for gift in g.boxes:
		if crossed(g,gift.s,previous,o.s,2.8) and absf(o.lane-gift.lane)<2.6 and o.cargo<0 and o.gift_claims.get(str(gift.s),-1)!=lap_index:
			o.gift_claims[str(gift.s)]=lap_index
			o.cargo=0 if index%3!=1 else 2
	if o.cargo>=0 and o.item_cool<=0:
		if o.cargo==0 and o.rush<.4:o.rush=3.0;o.cargo=-1;o.item_cool=7.0
		elif o.cargo==2:o.shield=true;o.cargo=-1;o.item_cool=7.0
	for h in g.course.hazards:
		if h.get('disabled_until',0)>g.water_clock:continue
		if o.air_time<=.1 and o.hit_cool<=0 and crossed(g,h.s,previous,o.s,2.4) and absf(o.lane-h.lane)<h.radius:
			o.hit_cool=1.4
			if o.shield:o.shield=false
			else:o.hit=.8;o.velocity*=.56;o.rush=0

func crossed(g,s: float,previous: float,current: float,depth: float)->bool:
	return absf(wrapf(previous-s,-g.LENGTH*.5,g.LENGTH*.5))<depth or absf(wrapf(current-s,-g.LENGTH*.5,g.LENGTH*.5))<depth or floor((previous-s+depth)/g.LENGTH)<floor((current-s+depth)/g.LENGTH)
