// Volumetric tokamak plasma v3 — Godot 4.3+ spatial shader (raymarched).
// Setup: MeshInstance3D + BoxMesh centred on the torus, Y up, node scale 1.
// box_size MUST equal the BoxMesh size. Shape params are in the same units
// as your mesh (defaults = your Blender measurements). Glow on in WorldEnvironment.
// Optional: Project Settings > Rendering > Anti Aliasing > TAA on, it smooths the grain.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_front, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

uniform vec3 box_size = vec3(46.0, 24.0, 46.0);
// shape (mesh units)
uniform float major_radius = 14.57;  // OuterDiameter/2 - OuterWidth/2
uniform float minor_radius = 6.91;   // InnerWidth/2
uniform float elongation = 1.56;     // InnerHeight/InnerWidth
uniform float triangularity : hint_range(0.0, 0.8) = 0.3; // D-shape
uniform float shell_width : hint_range(0.02, 0.6) = 0.25; // relative to minor radius
uniform float core_glow : hint_range(0.0, 1.0) = 0.03;

uniform vec3 edge_color : source_color = vec3(1.0, 0.25, 0.8);
uniform vec3 core_color : source_color = vec3(0.4, 0.2, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 1.0;
uniform float peak : hint_range(0.5, 4.0) = 1.4;  // max brightness; lower = less blowout
uniform float hot_size : hint_range(0.01, 0.5) = 0.15; // relative to minor radius
uniform float hot_strength : hint_range(0.0, 40.0) = 6.0;
uniform float flicker : hint_range(0.0, 1.0) = 0.3;
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform int max_steps : hint_range(8, 128) = 40;

varying vec3 lpos;
varying vec3 cam_local;

// cheap sine-free hash
float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash13(i), hash13(i + vec3(1.0, 0.0, 0.0)), f.x);
	float b = mix(hash13(i + vec3(0.0, 1.0, 0.0)), hash13(i + vec3(1.0, 1.0, 0.0)), f.x);
	float c = mix(hash13(i + vec3(0.0, 0.0, 1.0)), hash13(i + vec3(1.0, 0.0, 1.0)), f.x);
	float d = mix(hash13(i + vec3(0.0, 1.0, 1.0)), hash13(i + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

// p in units of minor radius
vec3 plasma(vec3 p, float t, vec2 rot) {
	float R0 = major_radius / minor_radius;
	float R = length(p.xz);
	float x = R - R0;
	float y = p.y / elongation;
	float rho = length(vec2(x + triangularity * y * y, y));

	float e = (rho - 1.0) / shell_width;
	float shell = exp(-e * e);
	vec2 xp = vec2(R0 - triangularity, elongation);
	vec2 dh = vec2(R - xp.x, abs(p.y) - xp.y);
	float hot = exp(-dot(dh, dh) / (hot_size * hot_size));
	float core = core_glow * (1.0 - smoothstep(0.0, 1.0, rho));

	// empty space: skip the noise
	if (shell + hot + core < 0.004) {
		return vec3(0.0);
	}

	// one noise per sample: streaks swirling around the torus
	vec3 q = vec3(rot.x * p.x - rot.y * p.z, p.y, rot.y * p.x + rot.x * p.z);
	float n = noise3(q * vec3(2.5, 0.8, 2.5) + vec3(0.0, -t * 0.5, 0.0));

	return edge_color * shell * (0.3 + 1.2 * n)
	     + core_color * core
	     + mix(edge_color, vec3(1.0), 0.6) * hot * hot_strength * (1.0 + flicker * sin(t * 9.0 + p.y));
}

void vertex() {
	lpos = VERTEX;
	cam_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

void fragment() {
	float t = TIME * speed;
	vec3 ro = cam_local;
	vec3 rd = normalize(lpos - ro);
	vec3 bh = box_size * 0.5;

	// ray vs box
	vec3 inv = 1.0 / rd;
	vec3 t0 = (-bh - ro) * inv;
	vec3 t1 = (bh - ro) * inv;
	vec3 tlo = min(t0, t1);
	vec3 thi = max(t0, t1);
	float tn = max(max(max(tlo.x, tlo.y), tlo.z), 0.0);
	float tf = min(min(thi.x, thi.y), thi.z);

	// stop at opaque geometry (centre column etc.)
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	view.xyz /= view.w;
	vec3 scene_world = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	float world_per_local = length(mat3(MODEL_MATRIX) * rd);
	tf = min(tf, length(scene_world - CAMERA_POSITION_WORLD) / world_per_local);

	vec3 acc = vec3(0.0);
	if (tf > tn) {
		// fixed step size: short rays get fewer steps
		float dt = length(box_size) / float(max_steps);
		int n = min(max_steps, int(ceil((tf - tn) / dt)));
		dt = (tf - tn) / float(max(n, 1));
		float s = tn + dt * hash13(vec3(FRAGCOORD.xy, TIME * 60.0));
		float ang = t * 0.6;
		vec2 rot = vec2(cos(ang), sin(ang));
		for (int i = 0; i < n; i++) {
			acc += plasma((ro + rd * s) / minor_radius, t, rot);
			s += dt;
		}
		acc *= dt / minor_radius;
	}

	float f = 1.0 + flicker * (noise3(vec3(t * 8.0, 0.0, 0.0)) - 0.5);
	vec3 c = acc * intensity * f;
	// hue-preserving tonemap so it stays pink instead of blowing out white
	c /= 1.0 + max(c.r, max(c.g, c.b)) / peak;

	ALBEDO = c;
	ALPHA = 1.0;
}
