shader_type spatial;
render_mode cull_disabled;
uniform vec4 shallow_color : source_color = vec4(0.08,0.53,0.54,1.0);
uniform vec4 deep_color : source_color = vec4(0.025,0.29,0.40,1.0);
varying vec3 world_pos;
void vertex(){
	vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	VERTEX.y+=sin(p.x*0.13+TIME*1.3)*0.055+cos(p.z*0.17+TIME*1.1)*0.045;
	world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
	vec2 p=world_pos.xz;
	float swell=sin(p.x*0.045+p.y*0.027+TIME*0.4)*0.5+0.5;
	float wave_a=p.x*1.25+p.y*0.58+TIME*1.3;
	float wave_b=p.y*1.80-p.x*0.33+TIME*1.7;
	float dx=0.038*1.25*cos(wave_a)-0.018*0.33*cos(wave_b);
	float dz=0.038*0.58*cos(wave_a)+0.018*1.8*cos(wave_b);
	vec3 normal_world=normalize(vec3(-dx,1.0,-dz));
	NORMAL=normalize((VIEW_MATRIX*vec4(normal_world,0.0)).xyz);
	float ripple=sin(wave_a+sin(p.y*0.37)*0.6);
	float patch=sin(p.y*0.83-p.x*0.35+TIME*0.5);
	float glint=smoothstep(0.985,1.0,ripple)*smoothstep(0.6,0.97,patch);
	ALBEDO=mix(deep_color.rgb,shallow_color.rgb,0.35+swell*0.35)+vec3(0.009,0.017,0.018)*glint;
	ROUGHNESS=0.64;
	SPECULAR=0.10;
}
