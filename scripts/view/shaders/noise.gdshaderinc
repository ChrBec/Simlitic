// Small value-noise helpers shared by the painted world shaders.
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x), mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += vnoise(p) * a;
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return s / 0.9375;
}

// Unexplored land lies under drifting mist.
vec3 apply_mist(vec3 col, vec3 mist, float reveal, vec2 xz, float time) {
	float cloud = fbm(xz * 0.07 + vec2(time * 0.012, time * 0.007));
	float fog = 1.0 - smoothstep(0.05, 0.95, reveal + (cloud - 0.5) * 0.45);
	return mix(col, mist * (0.88 + 0.22 * cloud), fog * 0.85);
}
