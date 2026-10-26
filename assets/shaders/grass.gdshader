shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Prato procedurale: chiazze morbide, fili d'erba e macchie secche.
// Nessuna texture: tutto calcolato in coordinate mondo, quindi le chiazze
// non "scivolano" quando il terreno viene scalato.

uniform vec3 color_deep : source_color = vec3(0.20, 0.40, 0.17);
uniform vec3 color_mid : source_color = vec3(0.33, 0.56, 0.24);
uniform vec3 color_light : source_color = vec3(0.52, 0.71, 0.31);
uniform vec3 color_dry : source_color = vec3(0.62, 0.62, 0.32);
uniform float patch_scale = 0.09;
uniform float detail_scale = 1.35;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += vnoise(p) * amp;
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float broad = fbm(world_pos.xz * patch_scale);
	float fine = fbm(world_pos.xz * detail_scale);
	vec3 c = mix(color_deep, color_mid, smoothstep(0.22, 0.72, broad));
	c = mix(c, color_light, smoothstep(0.52, 0.92, broad));
	c = mix(c, color_dry, smoothstep(0.62, 0.95, fine) * 0.28);
	c *= 0.93 + 0.14 * fine;
	// micro-contrasto per non far sembrare il prato una superficie di plastica
	float speck = hash(floor(world_pos.xz * 26.0));
	c *= 0.97 + 0.06 * speck;
	ALBEDO = c;
	ROUGHNESS = 0.96;
	SPECULAR = 0.12;
}
