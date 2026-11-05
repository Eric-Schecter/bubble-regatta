extends SceneTree
func _initialize():
	var art=load('res://scripts/cozy_art.gd').new()
	var palette=[Color.CORAL,Color.SKY_BLUE,Color.TAN,Color.PLUM,Color.AQUAMARINE,Color.BEIGE,Color.GOLD,Color.SLATE_BLUE]
	var first_blinks=[]
	for species in range(8):
		var boat=art.make_boat(species,palette)
		root.add_child(boat)
		var face=boat.get_node('Captain').face
		assert(face.eye_parts.size()==2 and face.mouth!=null)
		for frame in range(90):face.tick(1.0/60,'victory',frame/60.0,9999)
		assert(face.happiness>0.95)
		for eye in face.eye_parts:
			assert(eye.pivot.scale.y>1.30 and eye.pivot.scale.x>1.18,'Happy eyes must visibly widen')
		var early_blink=false
		var both_blink=false
		var wink=false
		for frame in range(200):
			face.tick(1.0/120,'wave',frame/120.0,1.65,0.0 if frame<36 else 0.08)
			if frame<36 and maxf(face.closures.x,face.closures.y)>0:early_blink=true
			if minf(face.closures.x,face.closures.y)>0.95:both_blink=true
			if absf(face.closures.x-face.closures.y)>0.95:wink=true
			for i in range(2):
				if face.closures[i]>0.95:
					assert(face.eye_parts[i].lid.visible)
					assert(not face.eye_parts[i].glint.visible,'Closed eyes must not leave floating highlights')
		assert(not early_blink and not both_blink and wink,'Greeting should only wink when the paw rises')
		var rig=boat.get_node('Captain')
		rig.request('wave')
		var saw_synced_wink=false
		for frame in range(100):
			rig.tick(1.0/120,frame/120.0*112/60,true,'idle')
			var tip: Vector3=rig.right.transform*rig.paws[1].position
			var rest_tip: Vector3=rig.rests.ArmRight*rig.paws[1].position
			if maxf(face.closures.x,face.closures.y)>0:
				assert(tip.y-rest_tip.y>0.025,'Wink must not precede the raised paw')
				saw_synced_wink=true
		assert(saw_synced_wink,'Actual greeting arm should trigger the wink')
		var start=face.time
		var count=face.natural_blink_count
		var first=-1.0
		for frame in range(1500):
			face.tick(1.0/60,'',0,0)
			if first<0 and face.natural_blink_count>count:first=face.time-start
		assert(face.natural_blink_count-count>=4,'Idle captain should blink naturally')
		assert(face.happiness<0.01,'Expression must recover after excitement')
		first_blinks.append(first)
		var frozen=face.time
		var frozen_scale=face.eye_parts[0].pivot.scale
		face.tick(0,'victory',1,9999)
		assert(face.time==frozen and face.eye_parts[0].pivot.scale==frozen_scale,'Pause should freeze expressions')
		boat.free()
	assert(first_blinks.max()-first_blinks.min()>0.4,'Crew should not blink in lockstep')
	print('FACE TEST PASS: all 8 captains; excited wide eyes, paw-synced greeting wink (no pre-blink), hidden closed-eye highlights, irregular idle blinks, recovery and pause')
	quit()
