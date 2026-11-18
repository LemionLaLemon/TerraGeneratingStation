//IMPORTED FROM BLENDER
shader_type spatial;

uniform vec3 color1 : source_color = vec3(0.77, 0.79, 0.82);
uniform vec3 color2 : source_color = vec3(0.77, 0.79, 0.82);
uniform vec3 mortar : source_color = vec3(0.0);
uniform float scale = 10.0;
uniform float mortar_size = 0.005;
uniform float mortar_smooth = 0.1;
uniform float bias = -1.0;
uniform float brick_width = 0.5;
uniform float row_height = 0.7;
uniform float offset_amount = 0.0;
uniform int offset_frequency = 2;
uniform float squash_amount = 1.0;
uniform int squash_frequency = 2;
uniform float roughness_value = 0.5;
uniform float grain_size = 0.012;

float brick_noise(int n) {
	uint u = uint(n);
	u = (u << 13u) ^ u;
	u = u * (u * u * 15731u + 789221u) + 1376312589u;
	return float(u & 0x7fffffffu) / float(0x7fffffff);
}

uniform float grain_amount = 0.08;

float hash21(vec2 q) {
	uvec2 v = uvec2(ivec2(q));
	uint h = v.x * 1597334673u ^ v.y * 3812015801u;
	h = (h ^ (h >> 16u)) * 0x7feb352du;
	h = (h ^ (h >> 15u)) * 0x846ca68bu;
	h ^= h >> 16u;
	return float(h) / 4294967295.0;
}

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz * scale;
	float bw = brick_width;
	float offset = 0.0;
	int rownum = int(floor(p.y / row_height));

	if (offset_frequency != 0 && squash_frequency != 0) {
		bw *= (rownum % squash_frequency != 0) ? 1.0 : squash_amount;
		offset = (rownum % offset_frequency != 0) ? 0.0 : bw * offset_amount;
	}

	int bricknum = int(floor((p.x + offset) / bw));
	float x = (p.x + offset) - bw * float(bricknum);
	float y = p.y - row_height * float(rownum);

	float tint = clamp(brick_noise((rownum << 16) + (bricknum & 0xFFFF)) + bias, 0.0, 1.0);

	float d = min(min(x, y), min(bw - x, row_height - y));
	float m = 0.0;
	if (d < mortar_size) {
		m = (mortar_smooth == 0.0) ? 1.0 : smoothstep(0.0, mortar_smooth, 1.0 - d / mortar_size);
	}

	vec3 brick = mix(color1, color2, tint);
	vec2 g = world_pos.xz / grain_size;
	float fade = 1.0 - smoothstep(0.7, 1.6, length(fwidth(g)));
	float grain = (hash21(floor(g)) - 0.5) * grain_amount * fade;
	ALBEDO = mix(brick, mortar, m) + vec3(grain);
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
}