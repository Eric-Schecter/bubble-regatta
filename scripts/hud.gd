extends Control
var game
var cover: Texture2D
var font: Font
var feedbacks=[]
var flights=[]
var inventory_pulse=0.0
var shell_pulse=0.0
const INK=Color('#35586b')
const CREAM=Color('#fff7e5')
const CORAL=Color('#e79583')
const TEAL=Color('#5caaa8')
const NAMES=['Cream Bear','Pip Penguin','Mochi Walrus','Peach Fox','Bubble Seal','Cotton Bunny','Cocoa Deer','Pudding Owl']
const COURSES=['Coral Harbor','Mint Islands','Sunny Bay']
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if OS.has_feature('web'):
		font=load('res://assets/fonts/Nunito.ttf')
	else:
		var system_font=SystemFont.new()
		system_font.font_names=PackedStringArray(['Avenir Next','Arial Rounded MT Bold','Arial'])
		system_font.font_weight=600
		system_font.antialiasing=TextServer.FONT_ANTIALIASING_GRAY
		font=system_font
	cover=load('res://assets/boats/cover.png')

func label(s: String,p: Vector2,size: int=20,col: Color=INK):
	draw_string(font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)
func center_label(s: String,y: float,size: int=20,col: Color=INK,x: float=480):
	label(s,Vector2(x-font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5,y),size,col)
func card(r: Rect2,col: Color=CREAM,radius: int=18,border: Color=Color(1,1,1,0.7)):
	var style=StyleBoxFlat.new()
	style.bg_color=col
	style.set_corner_radius_all(mini(radius,14))
	style.border_color=border
	style.set_border_width_all(0)
	draw_style_box(style,r)
func time_string(t: float)->String:
	return '%02d:%05.2f' % [int(t)/60,fmod(t,60)]
func anchor(p: Vector2,scale_v: float=1,col: Color=INK):
	draw_arc(p+Vector2(0,-8)*scale_v,4*scale_v,0,TAU,20,col,2*scale_v,true)
	draw_line(p+Vector2(0,-4)*scale_v,p+Vector2(0,13)*scale_v,col,2*scale_v,true)
	draw_line(p+Vector2(-7,1)*scale_v,p+Vector2(7,1)*scale_v,col,2*scale_v,true)
	draw_arc(p+Vector2(0,3)*scale_v,11*scale_v,0,PI,20,col,2*scale_v,true)
func avatar(i: int,p: Vector2,r: float,selected: bool=false):
	draw_circle(p+Vector2(0,3),r+3,Color(0.15,0.3,0.35,0.1),true,-1,true)
	draw_circle(p,r+3,CORAL if selected else Color('#dfede4'),true,-1,true)
	draw_circle(p,r,CREAM,true,-1,true)
	var fur=[Color('#fff0d2'),Color('#55748a'),Color('#c79578'),Color('#f0bf9e'),Color('#9fbac6'),Color('#ffe6d6'),Color('#c49c75'),Color('#d5bda0')][i]
	if i in [0,3,5,6]:
		for sign_x in [-1,1]:
			var ep=p+Vector2(sign_x*r*0.5,-r*0.5)
			oval(ep,Vector2(r*0.2,r*(0.50 if i==5 else 0.23)),fur)
	draw_circle(p+Vector2(0,r*0.05),r*0.68,fur,true,-1,true)
	for sign_x in [-1,1]:
		draw_circle(p+Vector2(sign_x*r*0.26,0),r*0.065,INK,true,-1,true)
		oval(p+Vector2(sign_x*r*0.40,r*0.22),Vector2(r*0.13,r*0.07),Color('#efa6a0'))
	draw_circle(p+Vector2(0,r*0.22),r*0.08,Color('#e8b153') if i==1 else INK,true,-1,true)
	if i==2:
		for sign_x in [-1,1]:draw_line(p+Vector2(sign_x*r*0.17,r*0.26),p+Vector2(sign_x*r*0.17,r*0.52),CREAM,r*0.09,true)
	card(Rect2(p+Vector2(-r*0.36,-r*0.77),Vector2(r*0.72,r*0.22)),CREAM,3)
func oval(p: Vector2,size_v: Vector2,col: Color):
	var poly=PackedVector2Array()
	for i in range(32):poly.append(p+Vector2(cos(i*TAU/32),sin(i*TAU/32))*size_v)
	draw_colored_polygon(poly,col)
func item_icon(i: int,p: Vector2,r: float):
	if i==0:
		oval(p,Vector2(r*0.45,r*0.7),Color('#f3c668'))
		draw_line(p+Vector2(0,-r*0.7),p+Vector2(0,r*0.7),CREAM,r*0.18,true)
		for x in [-1,1]:draw_line(p+Vector2(x*r*0.65,r*0.25),p+Vector2(x*r*0.9,r*0.55),CORAL,3,true)
	elif i==1:
		for y in [-0.3,0.25]:
			draw_arc(p+Vector2(-r*0.2,r*y),r*0.38,PI,TAU,16,TEAL,4,true)
			draw_arc(p+Vector2(r*0.45,r*y),r*0.28,0,PI,16,TEAL,4,true)
	else:
		draw_circle(p,r*0.7,CORAL,true,-1,true)
		draw_circle(p,r*0.42,CREAM,true,-1,true)
		for a in [0,PI/2,PI,PI*1.5]:
			var v=Vector2(cos(a),sin(a))
			draw_line(p+v*r*0.43,p+v*r*0.7,Color('#fff0d5'),r*0.2,true)

func _draw():
	if not game:return
	var g=game
	if g.state=='title':
		draw_texture_rect(cover,Rect2(0,0,960,540),false)
		card(Rect2(29,34,354,410),Color(1,0.98,0.91,0.94),14)
		anchor(Vector2(69,77),1.1,TEAL)
		label('BUBBLE',Vector2(58,148),42)
		label('REGATTA',Vector2(58,194),42)
		card(Rect2(58,344,295,63),CORAL,21)
		center_label('PLAY',384,23,CREAM,205)
	elif g.state=='select':
		card(Rect2(26,25,348,490),Color(1,0.98,0.91,0.96),26)
		label('Choose a captain',Vector2(51,72),30)
		label('←  →',Vector2(53,103),15,Color('#819a99'))
		avatar(g.racer,Vector2(106,163),36,true)
		label(NAMES[g.racer],Vector2(154,163),22)
		for i in range(8):avatar(i,Vector2(77+(i%4)*81,241+int(i/4)*64),23,i==g.racer)
		label('COURSE',Vector2(52,362),15,Color('#819a99'))
		card(Rect2(50,375,300,52),Color('#dceee3'),15)
		label(COURSES[g.selected_track()],Vector2(69,409),23,INK)
		if g.pending_track>=0:course_spinner(Vector2(325,401),9,g.selected_track_progress())
		card(Rect2(50,447,300,44),CORAL,15)
		if g.pending_start:course_spinner(Vector2(200,469),10,g.selected_track_progress())
		else:center_label('RACE',476,17,CREAM,200)
	elif g.state=='race':
		card(Rect2(22,20,126,56),Color(1,.98,.91,.90),12)
		label(str(g.rank),Vector2(41,61),36,CORAL)
		label('/ 8' if g.mode!=2 else '/ 1',Vector2(87,57),17)
		card(Rect2(22,87,126,45),Color(1,.98,.91,.84),12)
		shell_icon(Vector2(44,108),14*(1+shell_pulse*.18))
		label(str(g.shell_count),Vector2(71,116),23,INK)
		card(Rect2(399,20,162,46),Color(1,.98,.91,.90),12)
		flag_icon(Vector2(423,43),12)
		center_label('%d / 3' % g.lap,51,22,INK,493)
		card(Rect2(784,20,154,46),Color(1,.98,.91,.90),12)
		clock_icon(Vector2(800,42),8)
		label(time_string(g.race_time),Vector2(817,51),21)
		pause_icon(Vector2(915,115),9)
		draw_circle(Vector2(915,115),20,Color(1,.98,.91,.65),false,1.4,true)
		var ready=g.item>=0
		var pulse=inventory_pulse
		draw_circle(Vector2(78,465),37,Color(1,.98,.91,.92),true,-1,true)
		var shown=g.item if ready else (2 if g.shield_time>0 else (0 if g.lemon_time>0 and g.boost>0 else (1 if g.wave_time>0 else -1)))
		var shake=(event_strength('full')+event_strength('no_target')+event_strength('empty'))*sin(g.clock*34)*4
		var icon_p=Vector2(78+shake,465)
		if shown>=0:
			draw_circle(icon_p,32+sin(g.clock*4)*2,Color(.40,.77,.66,.10+pulse*.18),true,-1,true)
			item_icon(shown,icon_p,31*(1+pulse*.12))
		else:gift_icon(icon_p,24,Color('#b4ccc5'))
		if ready:space_key(Vector2(164,466),1+sin(g.clock*4)*.025)
		else:
			var progress=g.shield_time/7 if g.shield_time>0 else (g.lemon_time/3 if g.lemon_time>0 and g.boost>0 else g.wave_time/.85)
			if progress>0:draw_arc(icon_p,33,-PI/2,-PI/2+TAU*clampf(progress,0,1),48,TEAL,3.5,true)
		if event_strength('no_target')>.05:
			draw_arc(Vector2(164,466),10,0,TAU,24,Color('#9eaba6'),2,true)
			draw_line(Vector2(153,477),Vector2(175,455),CORAL,3,true)
		card(Rect2(804,445,134,61),Color(1,.98,.91,.86),12)
		label('%02d' % int(g.velocity*2.1),Vector2(820,484),33,CORAL if g.boost>0 else INK)
		speed_icon(Vector2(909,474),12,TEAL if g.boost>0 else INK,clampf(g.velocity/47,0,1))
		if g.boost>0:chevrons(Vector2(860,497),8,TEAL)
		var prev=Vector2.ZERO
		for i in range(101):
			var p=g.center(float(i)/100*g.LENGTH)
			var v=Vector2(859+p.x*0.20,343+p.z*0.20)
			if i>0:
				draw_line(prev,v,Color(.16,.30,.34,.40),4.5,true)
				draw_line(prev,v,Color(1,.98,.91,.85),2.2,true)
			prev=v
		if g.mode!=2:
			for o in g.opponents:
				var p=g.center(o.s)
				draw_circle(Vector2(859+p.x*0.20,343+p.z*0.20),2.5,INK,true,-1,true)
		var cp=g.center(g.distance)
		draw_circle(Vector2(859+cp.x*0.20,343+cp.z*0.20),5,CORAL,true,-1,true)
		if g.charge>0 or g.boost>0:
			draw_line(Vector2(390,493),Vector2(570,493),Color(1,.98,.91,.45),5,true)
			var amount=minf(1,g.charge/2 if g.boost<=0 else g.boost/3)
			if amount>0.02:draw_line(Vector2(390,493),Vector2(390+180*amount,493),CORAL if g.boost<=0 else TEAL,5,true)
			chevrons(Vector2(480,479),9,CORAL if g.boost<=0 else TEAL)
		if g.countdown>0 or g.countdown>-.65:
			card(Rect2(382,145,196,66),CREAM,30)
			var lit=clampi(4-int(ceil(g.countdown)),0,3)
			for i in range(3):
				var col=TEAL if g.countdown<=0 else (CORAL if i<lit else Color('#d8dfd2'))
				draw_circle(Vector2(421+i*59,178),17,col,true,-1,true)
				if g.countdown<=0:play_icon(Vector2(421+i*59,178),7,CREAM)
		if g.paused:
			draw_rect(Rect2(0,0,960,540),Color(.15,.35,.4,.43))
			card(Rect2(275,160,410,310),CREAM,14)
			pause_icon(Vector2(480,211),19)
			card(Rect2(342,258,112,82),Color('#dceee3'),22)
			play_icon(Vector2(398,299),20,TEAL)
			card(Rect2(506,258,112,82),Color('#f5dfcb'),22)
			restart_icon(Vector2(562,299),21,CORAL)
			card(Rect2(342,358,112,82),Color('#e4ebf2'),14)
			captains_icon(Vector2(398,399),23)
			card(Rect2(506,358,112,82),Color('#f3ddd5'),14)
			exit_icon(Vector2(562,399),22)
	elif g.state=='result':
		card(Rect2(26,36,348,470),Color(1,0.98,0.91,0.96),28)
		anchor(Vector2(200,81),1.2,CORAL)
		center_label('You win!' if g.rank==1 else 'Race complete',144,34,INK,200)
		center_label('#%d' % g.rank,199,38,CORAL,200)
		center_label('TIME  '+time_string(g.race_time),256,23,INK,200)
		center_label('BEST  '+time_string(g.best),291,18,TEAL,200)
		center_label(('ROUND %d / 3   ·   %d PTS' % [g.cup_round+1,g.cup_points]) if g.mode==0 else 'SHELLS  %d' % g.shell_count,344,17,TEAL,200)
		for x in [157,200,243]:star(Vector2(x,386),14,Color('#edc45f') if g.rank==1 else TEAL)
		card(Rect2(50,432,300,48),CORAL,16)
		if g.pending_start:course_spinner(Vector2(200,457),10,g.selected_track_progress())
		else:center_label('NEXT RACE' if g.mode==0 and g.cup_round<2 else 'BACK TO HARBOR',463,21,CREAM,200)
	# Small drawn emotes follow the actual animated character, not a fixed screen spot.
	if g.state in ['race','select','result']:
		var rig=g.player.get_node('Captain')
		if rig.emote_strength>0.08:
			var screen=g.cam.unproject_position(g.player.position+Vector3.UP*3.25)
			var alpha=rig.emote_strength
			for i in range(3):
				var phase=g.gesture_clock*2+i*2.0
				var p=screen+Vector2((-1 if i%2==0 else 1)*(54+i*12),-14-i*19+sin(phase)*7)
				star(p,6+sin(phase)*1.5,Color(0.98,0.79,0.40,alpha*0.85))
	if g.state=='race' and not g.paused:draw_visual_feedback()
	if g.flash>0:draw_rect(Rect2(0,0,960,540),Color(1,0.9,0.6,g.flash*0.45))

func star(p: Vector2,r: float,col: Color):
	var pts=PackedVector2Array()
	for i in range(10):
		var angle=-PI/2+i*PI/5
		pts.append(p+Vector2(cos(angle),sin(angle))*r*(1 if i%2==0 else 0.45))
	draw_colored_polygon(pts,col)

func reset_feedback():
	feedbacks.clear()
	flights.clear()
	inventory_pulse=0
	shell_pulse=0

func feedback(kind: String,index: int=-1):
	if kind in ['full','empty','no_target']:inventory_pulse=1
	feedbacks.append({'kind':kind,'item':index,'age':0.0,'life':.42 if kind=='impact' else .85})
	if feedbacks.size()>8:feedbacks.pop_front()

func collect(kind: String,index: int,p: Vector3):
	flights.append({'kind':kind,'item':index,'start':game.cam.unproject_position(p),'age':0.0})
	if kind=='gift':inventory_pulse=1
	else:shell_pulse=1

func _process(dt: float):
	if not game or game.paused:return
	inventory_pulse=maxf(0,inventory_pulse-dt*1.7)
	shell_pulse=maxf(0,shell_pulse-dt*2)
	for effect in feedbacks:effect.age+=dt
	for flight in flights:flight.age+=dt
	feedbacks=feedbacks.filter(func(e):return e.age<e.life)
	flights=flights.filter(func(e):return e.age<.7)
	queue_redraw()

func event_strength(kind: String)->float:
	var strength=0.0
	for effect in feedbacks:
		if effect.kind==kind:strength=maxf(strength,1-effect.age/effect.life)
	return strength

func gift_icon(p: Vector2,r: float,col: Color=CORAL):
	card(Rect2(p-Vector2(r*.76,r*.46),Vector2(r*1.52,r*1.12)),col,r*.15)
	draw_line(p+Vector2(0,-r*.48),p+Vector2(0,r*.65),CREAM,r*.20,true)
	draw_line(p+Vector2(-r*.74,-r*.15),p+Vector2(r*.74,-r*.15),CREAM,r*.14,true)
	for x in [-1,1]:draw_arc(p+Vector2(x*r*.22,-r*.59),r*.24,0,TAU,16,col,3,true)

func shell_icon(p: Vector2,r: float):
	var points=PackedVector2Array([p+Vector2(-r*.22,r*.65)])
	for i in range(21):
		var a=PI+float(i)/20*PI
		var radius=r*(.88+.10*cos(float(i)*PI*.5))
		points.append(p+Vector2(cos(a)*radius,sin(a)*radius*.8))
	points.append(p+Vector2(r*.22,r*.65))
	draw_colored_polygon(points,Color('#edbe5d'))
	for i in range(5):
		var a=PI+.3+float(i)/4*(PI-.6)
		draw_line(p+Vector2(0,r*.54),p+Vector2(cos(a),sin(a)*.8)*r*.78,CREAM,2,true)

func space_key(p: Vector2,scale_v: float=1):
	var r=Rect2(p-Vector2(24,11)*scale_v,Vector2(48,22)*scale_v)
	card(r,Color('#e6ede2'),6,Color('#b5ccc4'))
	var pts=PackedVector2Array([p+Vector2(-10,-3),p+Vector2(-10,4),p+Vector2(10,4),p+Vector2(10,-3)])
	draw_polyline(pts,TEAL,2,true)

func chevrons(p: Vector2,r: float,col: Color):
	for offset in [-r*.6,r*.6]:
		draw_polyline(PackedVector2Array([p+Vector2(-r*.6,offset+r*.35),p+Vector2(0,offset-r*.15),p+Vector2(r*.6,offset+r*.35)]),col,3,true)

func flag_icon(p: Vector2,r: float):
	draw_line(p+Vector2(-r*.6,-r*.7),p+Vector2(-r*.6,r),INK,2,true)
	for y in range(3):
		for x in range(4):
			draw_rect(Rect2(p+Vector2(-r*.6+x*r*.34,-r*.7+y*r*.34),Vector2.ONE*r*.34),INK if (x+y)%2==0 else CREAM)

func clock_icon(p: Vector2,r: float):
	draw_arc(p,r,0,TAU,24,TEAL,1.7,true)
	draw_line(p,p+Vector2(0,-r*.6),TEAL,1.7,true)
	draw_line(p,p+Vector2(r*.45,r*.25),TEAL,1.7,true)

func speed_icon(p: Vector2,r: float,col: Color,fraction: float=.75):
	draw_arc(p,r,PI,TAU,24,col,2.2,true)
	var angle=lerpf(PI,TAU,fraction)
	draw_line(p,p+Vector2(cos(angle),sin(angle))*r*.85,col,2.5,true)
	draw_circle(p,3,col,true,-1,true)

func pause_icon(p: Vector2,r: float):
	for x in [-.4,.4]:draw_line(p+Vector2(x*r,-r*.65),p+Vector2(x*r,r*.65),INK,r*.34,true)

func play_icon(p: Vector2,r: float,col: Color):
	draw_colored_polygon(PackedVector2Array([p+Vector2(-r*.55,-r),p+Vector2(r*.95,0),p+Vector2(-r*.55,r)]),col)

func restart_icon(p: Vector2,r: float,col: Color):
	draw_arc(p,r,-PI*.8,PI*.75,28,col,4,true)
	var tip=p+Vector2(cos(PI*.75),sin(PI*.75))*r
	draw_colored_polygon(PackedVector2Array([tip+Vector2(-6,-7),tip+Vector2(9,-2),tip+Vector2(-2,9)]),col)

func draw_visual_feedback():
	var g=game
	for flight in flights:
		var t=clampf(flight.age/.7,0,1)
		var u=1-pow(1-t,3)
		var end=Vector2(78,465) if flight.kind=='gift' else Vector2(44,108)
		var start=flight.start
		var control=(start+end)*.5+Vector2(0,-85)
		var p=(1-u)*(1-u)*start+2*(1-u)*u*control+u*u*end
		if flight.kind=='gift':item_icon(flight.item,p,lerpf(25,19,t))
		else:shell_icon(p,lerpf(20,13,t))
		for i in range(3):star(p+Vector2(cos(i*TAU/3+t*8),sin(i*TAU/3+t*8))*22,3,Color(1,.82,.43,(1-t)*.8))
	for e in feedbacks:
		if e.kind in ['full','empty','no_target']:continue
		var t=e.age/e.life
		var scale_v=smoothstep(0,.12,e.age)*(1-smoothstep(e.life-.2,e.life,e.age))
		var p=g.cam.unproject_position(g.player.position+Vector3.UP*(.8 if e.kind=='impact' else 3.8))
		p+=Vector2(0,-18-t*25)
		p=p.clamp(Vector2(220,105),Vector2(760,395))
		draw_set_transform(p,0,Vector2.ONE*scale_v)
		if e.kind=='boost':
			item_icon(0,Vector2.ZERO,21)
			chevrons(Vector2(33,0),12,TEAL)
		elif e.kind in ['shield','shield_break']:
			item_icon(2,Vector2.ZERO,23*(1+t*.3 if e.kind=='shield_break' else 1))
			if e.kind=='shield_break':
				for i in range(5):
					var v=Vector2(cos(i*TAU/5),sin(i*TAU/5))
					draw_line(v*(27+t*10),v*(32+t*20),TEAL,2,true)
		elif e.kind=='wave_hit':
			item_icon(1,Vector2.ZERO,24)
			draw_polyline(PackedVector2Array([Vector2(22,0),Vector2(28,6),Vector2(40,-8)]),TEAL,3,true)
		elif e.kind=='impact':
			for i in range(7):
				var v=Vector2(cos(i*TAU/7),sin(i*TAU/7))
				draw_line(v*(16+t*18),v*(24+t*26),CORAL,2.5,true)
		elif e.kind=='jump':
			draw_arc(Vector2.ZERO,19,PI,TAU,18,Color('#eab65e'),3,true)
		draw_set_transform(Vector2.ZERO)

func course_spinner(p: Vector2,r: float,progress: float):
	draw_arc(p,r,0,TAU,28,Color(.36,.66,.62,.20),2,true)
	draw_arc(p,r,game.clock*4,game.clock*4+TAU*maxf(.15,progress),28,TEAL,2.5,true)

func captains_icon(p: Vector2,r: float):
	for side in [-1,1]:
		draw_circle(p+Vector2(side*r*.63,-r*.17),r*.23,Color('#9bb6ba'),true,-1,true)
		oval(p+Vector2(side*r*.63,r*.33),Vector2(r*.32,r*.23),Color('#9bb6ba'))
	draw_circle(p+Vector2(0,-r*.26),r*.30,INK,true,-1,true)
	oval(p+Vector2(0,r*.38),Vector2(r*.43,r*.28),INK)
	draw_polyline(PackedVector2Array([p+Vector2(-r*.95,-r*.75),p+Vector2(-r*1.2,-r*.50),p+Vector2(-r*.95,-r*.25)]),TEAL,2.5,true)

func exit_icon(p: Vector2,r: float):
	draw_polyline(PackedVector2Array([p+Vector2(-r*.1,-r*.85),p+Vector2(-r*.9,-r*.85),p+Vector2(-r*.9,r*.85),p+Vector2(-r*.1,r*.85)]),CORAL,3,true)
	draw_line(p+Vector2(-r*.35,0),p+Vector2(r*.95,0),CORAL,3,true)
	draw_polyline(PackedVector2Array([p+Vector2(r*.48,-r*.40),p+Vector2(r*.95,0),p+Vector2(r*.48,r*.40)]),CORAL,3,true)
