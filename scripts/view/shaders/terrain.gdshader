shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

// Painted ground: per-tile colours and flags come from two small textures (one texel per tile),
// everything else (brush streaks, rock on steep slopes, snow, paths, mist) is painted here.
#include "res://scripts/view/shaders/noise.gdshaderinc"

uniform sampler2D tint_tex : source_color, filter_linear, repeat_disable;
uniform sampler2D data_tex : filter_linear, repeat_disable;
uniform float map_size = 112.0;
uniform vec3 mist_color : source_color = vec3(0.84, 0.83, 0.80);
uniform vec3 path_color : source_color = vec3(0.72, 0.58, 0.38);
uniform vec3 path_dark : source_color = vec3(0.46, 0.36, 0.24);
uniform vec3 earth : source_color = vec3(0.60, 0.48, 0.32);
uniform vec3 rock : source_color = vec3(0.53, 0.47, 0.41);
uniform vec3 rock_dark : source_color = vec3(0.36, 0.32, 0.29);
uniform vec3 snow : source_color = vec3(0.95, 0.95, 0.97);
uniform vec3 sand : source_color = vec3(0.80, 0.72, 0.52);
uniform float winter = 0.0; // 0 summer … 1 deep winter: the snow line drops and the valleys frost over

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = wpos.xz / map_size;
	vec4 tint = texture(tint_tex, uv);
	vec4 data = texture(data_tex, uv);
	float n1 = fbm(wpos.xz * 0.55);
	float n2 = vnoise(vec2(wpos.x * 1.6 + wpos.z * 0.8, wpos.z * 3.2 - wpos.x * 0.5));
	float n3 = vnoise(wpos.xz * 7.0);
	vec3 col = tint.rgb * (0.86 + 0.26 * n1) * (0.95 + 0.1 * n2);

	// steep faces show rock, high ground gets snow
	float slope = 1.0 - wnorm.y;
	float rocky = smoothstep(0.22, 0.42, slope + (n1 - 0.5) * 0.25) * smoothstep(0.4, 1.2, wpos.y);
	// cliffs: streaks follow the height instead of being smeared down the slope
	float strata = vnoise(vec2((wpos.x + wpos.z) * 0.8, wpos.y * 2.2)) * 0.6 + vnoise(vec2((wpos.x - wpos.z) * 2.5, wpos.y * 5.0)) * 0.4;
	vec3 stone = mix(rock, rock_dark, smoothstep(0.25, 0.8, mix(n2 * 0.6 + n1 * 0.4, strata, smoothstep(0.3, 0.7, slope))));
	stone *= 0.9 + 0.2 * smoothstep(0.0, 9.0, wpos.y);
	col = mix(col, stone, rocky);
	float snow_line = mix(9.5, 3.0, winter);
	float snowy = smoothstep(snow_line, snow_line + 1.5, wpos.y + (n1 - 0.5) * 3.0) * (1.0 - smoothstep(0.6, 0.85, slope));
	col = mix(col, snow * (0.95 + 0.05 * n3), snowy);
	col = mix(col, snow * 0.96, winter * 0.5 * smoothstep(0.35, 0.65, n2 * 0.7 + n1 * 0.3));

	// shores, building plots, roads and mountain trails
	col = mix(col, sand * (0.9 + 0.15 * n3), smoothstep(0.12, 0.4, data.a));
	col = mix(col, earth * (0.88 + 0.2 * n2), smoothstep(0.35, 0.6, tint.a) * 0.8);
	float rd = data.r + (n1 - 0.5) * 0.22;
	col = mix(col, path_dark, smoothstep(0.40, 0.48, rd) * 0.55);
	col = mix(col, path_color * (0.9 + 0.18 * n3), smoothstep(0.50, 0.56, rd));
	float tr = data.g + (n1 - 0.5) * 0.2;
	float trail = smoothstep(0.48, 0.58, tr) * (0.35 + 0.65 * step(0.75, data.g));
	col = mix(col, path_color * (0.85 + 0.2 * n3), trail);

	ALBEDO = apply_mist(col, mist_color, data.b, wpos.xz, TIME);
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}
