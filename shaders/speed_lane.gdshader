shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float flow_time=0.0;
void fragment(){
	float across=abs(UV.x*2.0-1.0);
	float phase=fract(UV.y*5.0-across*.55+flow_time*1.7);
	float arrow=1.0-smoothstep(.16,.23,abs(phase-.5));
	arrow*=1.0-smoothstep(.76,.94,across);
	vec3 base=mix(vec3(.12,.60,.58),vec3(.30,.80,.65),1.0-across);
	ALBEDO=mix(base,vec3(1.0,.97,.73),arrow);
}
