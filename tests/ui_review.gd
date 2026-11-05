extends SceneTree
var g
func _initialize():call_deferred('run')
func capture(name: String,frames: int=18):
	for i in range(frames):
		g._process(1.0/30)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://captures/ui-en-'+name+'.png')
func run():
	g=load('res://main.tscn').instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.state='title'
	await capture('title')
	g.key_event(KEY_ENTER)
	await capture('menu')
	g.key_event(KEY_ENTER)
	g.racer=5
	g.refresh_captain()
	await capture('select')
	g.mode=1
	g.start_race()
	g.countdown=-1
	g.distance=180
	g.velocity=34
	g.item=0
	g.shell_count=7
	g.race_time=18.5
	g.boost=2
	g.best=.01
	await capture('race')
	g.key_event(KEY_ESCAPE)
	await capture('pause',2)
	g.key_event(KEY_ESCAPE)
	g.state='result'
	g.rank=1
	g.race_time=101.48
	g.best=98.51
	g.cup_round=0
	g.cup_points=15
	await capture('result',45)
	print('ENGLISH UI REVIEW: title, menu, longest captain name, race, pause and results captured in actual default scene')
	quit()
