shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
varying vec2 world_xz;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
	vec2 i=floor(p),f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1.0,0.0)),f.x),mix(hash21(i+vec2(0.0,1.0)),hash21(i+vec2(1.0)),f.x),f.y);
}
void vertex(){world_xz=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;}
void fragment(){
	float age=COLOR.g;
	vec2 p=world_xz+vec2(COLOR.b*.23,-COLOR.b*.16);
	vec2 warp=vec2(noise(p*1.7),noise(p*1.7+19.3))-.5;
	float clumps=noise(p*3.1+warp*2.0);
	float detail=noise(p*12.0+warp*3.0);
	float broad=noise(p*.85+warp);
	// A ragged perimeter and holes dissolve the footprint instead of outlining a strip.
	float across=abs(UV.x*2.0-1.0);
	float edge=1.0-smoothstep(.35+broad*.28,.70+broad*.30,across);
	float threshold=mix(.33,.64,age);
	float foam=smoothstep(threshold-.08,threshold+.12,clumps*.72+detail*.28);
	float pores=mix(.5,1.0,smoothstep(.25,.65,detail));
	ALBEDO=mix(vec3(.66,.87,.85),vec3(.94,1.0,.97),clumps);
	ALPHA=COLOR.a*edge*foam*pores;
}
