extends SceneTree
func _initialize():
	var art=load('res://scripts/cozy_art.gd').new()
	var palette=[Color.CORAL,Color.SKY_BLUE,Color.TAN,Color.PLUM,Color.AQUAMARINE,Color.BEIGE,Color.GOLD,Color.SLATE_BLUE]
	var tested=0
	for species in range(8):
		var boat=art.make_boat(species,palette)
		root.add_child(boat)
		var rig=boat.get_node('Captain')
		for beat_offset in [0.0,0.5,1.0,1.5]:
			for gesture in ['idle','cheer','wave','victory','finish']:
				rig.gesture=''
				if gesture!='idle':rig.request(gesture)
				for frame in range(180):
					var context=gesture if gesture in ['victory','finish'] else 'driving'
					rig.tick(1.0/60,float(frame)/60*112/60+beat_offset,true,context,sin(frame*0.04))
					if not rig.pose_is_clear():
						push_error('Clipping: species=%d gesture=%s frame=%d phase=%f' % [species,gesture,frame,beat_offset])
						quit(1)
						return
					for i in range(2):
						var arm=rig.left if i==0 else rig.right
						var shoulder: Vector3=rig.rests[arm.name].origin
						assert(arm.position.distance_to(shoulder)<0.001)
						assert((arm.transform*rig.paws[i].position).distance_to(shoulder)<0.43)
					tested+=1
		boat.free()
	print('POSE CLEARANCE PASS: %d animated poses across 8 captains; head/face/tusk/windshield clearance and fixed short-arm reach' % tested)
	quit()
