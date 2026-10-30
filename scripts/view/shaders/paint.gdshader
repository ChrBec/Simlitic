shader_type spatial;
render_mode specular_disabled;

// Gouache look for every model: vertex colours lit in two soft bands (light side and shade side,
// shadows lean lilac through the ambient light), a little brush grain, and the seasons:
// foliage (vertex alpha < 1) turns fresh in spring, ochre and rust in autumn, bare in winter,
// and in winter snow settles on every upward face.
#include "res://scripts/view/shaders/noise.gdshaderinc"

uniform float spring = 0.0;
uniform float autumn = 0.0;
uniform float winter = 0.0;
uniform float light_scale = 0.45;
uniform vec3 snow_color : source_color = vec3(0.96, 0.96, 0.99);
uniform vec3 autumn_a : source_color = vec3(0.88, 0.58, 0.20);
uniform vec3 autumn_b : source_color = vec3(0.74, 0.32, 0.16);

varying vec3 wpos;
varying vec3 wnorm;
varying float leaf;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	leaf = 1.0 - step(0.75, COLOR.a);
}

void fragment() {
	vec3 c = COLOR.rgb;
	float grain = vnoise(wpos.xz * 9.0 + wpos.y * 5.0);
	// each tree picks its own autumn colour
	float pick = hash12(floor(wpos.xz * 0.9));
	vec3 fall = mix(autumn_a, autumn_b, pick) * (0.75 + 0.45 * dot(c, vec3(0.333)));
	c = mix(c, fall, leaf * autumn * (pick < 0.2 ? 0.25 : 0.8));
	c = mix(c, c * vec3(0.95, 1.14, 0.88), leaf * spring * 0.6);
	c = mix(c, vec3(0.46, 0.41, 0.42) * (0.9 + 0.2 * pick), leaf * winter * 0.7);
	float up = smoothstep(0.5, 0.82, wnorm.y + (grain - 0.5) * 0.25);
	c = mix(c, snow_color, up * winter * 0.9);
	ALBEDO = c * (0.94 + 0.12 * grain);
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	// two painted bands with a soft edge instead of a smooth gradient
	float lit = 0.1 + smoothstep(-0.02, 0.12, ndl) * 0.24 + smoothstep(0.38, 0.55, ndl) * 0.14;
	if (!LIGHT_IS_DIRECTIONAL) {
		lit = clamp(ndl, 0.0, 1.0) * 0.5; // fires glow softly
	}
	DIFFUSE_LIGHT += lit * ATTENUATION * LIGHT_COLOR / PI * light_scale;
}
