extends SceneTree
func _initialize():call_deferred('run')
func percentile(values: Array,p: float)->float:
	values.sort()
	return values[mini(values.size()-1,int(values.size()*p))]
func run():
	var g=load('res://main.tscn').instantiate()
	root.add_child(g)
	g.state='select'
	g.distance=45
	if RenderingServer.has_method('viewport_set_measure_render_time'):
		RenderingServer.call('viewport_set_measure_render_time',g.viewport.get_viewport_rid(),true)
	for stage in ['opening','settled']:
		var timings=[]
		var gpu=[]
		var previous=Time.get_ticks_usec()
		for frame in range(150):
			if not "--moving-preview" in OS.get_cmdline_user_args():g.distance=45
			await process_frame
			var now=Time.get_ticks_usec()
			if frame>20:timings.append((now-previous)/1000.0)
			previous=now
			if RenderingServer.has_method('viewport_get_measured_render_time_gpu'):gpu.append(RenderingServer.call('viewport_get_measured_render_time_gpu',g.viewport.get_viewport_rid()))
		print('SELECT ',stage,' median ms ',percentile(timings,.5),' p95 ms ',percentile(timings,.95),' gpu median ms ',percentile(gpu,.5) if not gpu.is_empty() else 0,' draw calls ',Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),' primitives ',Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),' cache ',g.track_cache.size())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://captures/selection-performance.png')
	quit()
