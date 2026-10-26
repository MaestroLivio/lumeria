shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Ombra di contatto morbida per l'avatar: un dischetto sfumato che lo
// "appoggia" al prato anche quando le ombre reali sono molto tenui.
uniform vec4 tint : source_color = vec4(0.05, 0.08, 0.05, 0.32);

void fragment() {
	float d = distance(UV, vec2(0.5)) * 2.0;
	ALBEDO = tint.rgb;
	ALPHA = tint.a * smoothstep(1.0, 0.25, d);
}
