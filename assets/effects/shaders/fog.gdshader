shader_type canvas_item;

// Atmospheric Nighttime Fog Shader for Harborvale.
// Generates soft drifting misty layers without heavy texture sampling.

uniform vec4 fog_color : source_color = vec4(0.07, 0.10, 0.15, 1.0);
uniform float fog_density : hint_range(0.0, 1.0) = 0.0;
uniform vec2 drift_velocity = vec2(0.02, 0.008);
uniform vec2 drift_velocity2 = vec2(-0.012, 0.015);
uniform float noise_scale = 2.8;

// Fast procedural noise
float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float smooth_noise(vec2 uv) {
	vec2 lv = fract(uv);
	vec2 id = floor(uv);
	lv = lv * lv * (3.0 - 2.0 * lv);
	
	float bl = hash(id);
	float br = hash(id + vec2(1.0, 0.0));
	float tl = hash(id + vec2(0.0, 1.0));
	float tr = hash(id + vec2(1.0, 1.0));
	
	float b = mix(bl, br, lv.x);
	float t = mix(tl, tr, lv.x);
	return mix(b, t, lv.y);
}

float fbm(vec2 uv) {
	float val = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 3; i++) {
		val += amp * smooth_noise(uv);
		uv = rot * uv * 2.02;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	if (fog_density <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		vec2 uv1 = UV * noise_scale + TIME * drift_velocity;
		vec2 uv2 = UV * (noise_scale * 1.4) + TIME * drift_velocity2;
		
		float n1 = fbm(uv1);
		float n2 = fbm(uv2);
		float combined = mix(n1, n2, 0.45);
		
		// Soft rolling fog bands
		float mist = smoothstep(0.2, 0.8, combined);
		float alpha = mist * fog_density;
		
		COLOR = vec4(fog_color.rgb, alpha);
	}
}
