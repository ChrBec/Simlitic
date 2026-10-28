shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

// Lakes and streams: depth tint from the per-tile water mask, drifting ripples, foam at the shore.
#include "res://scripts/view/shaders/noise.gdshaderinc"

uniform sampler2D data_tex : filter_linear, repeat_disable;
uniform float map_size = 112.0;
uniform vec3 shallow : source_color = vec3(0.36, 0.60, 0.64);
uniform vec3 deep : source_color = vec3(0.17, 0.33, 0.46);
uniform vec3 foam : source_color = vec3(0.95, 0.94, 0.88);
uniform vec3 mist_color : source_color = vec3(0.84, 0.83, 0.80);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 data = texture(data_tex, wpos.xz / map_size);
	float w = data.a;
	float n = fbm(wpos.xz * 0.4 + vec2(TIME * 0.03, TIME * 0.02));
	vec3 col = mix(shallow, deep, smoothstep(0.55, 1.0, w + (n - 0.5) * 0.3));
	float ripple = vnoise(vec2(wpos.x * 2.0 + TIME * 0.25, wpos.z * 6.0 + wpos.x * 0.5));
	col = mix(col, shallow * 1.35, smoothstep(0.72, 0.9, ripple) * 0.35);
	float band = smoothstep(0.3, 0.42, w) * (1.0 - smoothstep(0.5, 0.66, w + (n - 0.5) * 0.2));
	col = mix(col, foam, band * (0.55 + 0.45 * vnoise(wpos.xz * 5.0 + TIME * 0.4)));
	ALBEDO = apply_mist(col, mist_color, data.b, wpos.xz, TIME);
	ROUGHNESS = 0.25;
	SPECULAR = 0.45;
}
