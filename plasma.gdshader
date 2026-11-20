// Volumetric tokamak plasma v15 - Godot 4.3+/4.4 spatial shader (raymarched), Forward+ / Mobile / Compatibility.
//
// WHAT IT DRAWS
//   A see-through gas, not a solid donut: the hot core is dark, light comes from the thin cold edge
//   (bright only where you look along it), fine field-aligned filaments, faint haze out to the walls,
//   and bright contact rings where the divertor legs land on the tiles. The default is the steady
//   flat-top state. Nothing is sequenced in time: every state change comes from the "sim inputs".
//
// SETUP
//   1. MeshInstance3D + BoxMesh, as a sibling of the vessel mesh (same parent), no rotation.
//      box_size MUST equal the BoxMesh's own Size property (not size x node scale).
//   2. All lengths below are in the BoxMesh's LOCAL units. Node scale just scales the whole plasma, so
//      with BoxMesh 46x24x46 at node scale 1 the defaults fit tokamak.blend / plasmatoroid.blend at their
//      native size. If your vessel is N times bigger, set the node scale to N and leave the uniforms alone.
//   3. Give this node the same position and scale as the vessel mesh node and leave center_y = 0.68,
//      OR put the node origin on the plasma centre and set center_y = 0. Not both.
//   4. Material: this shader, nothing else. Do not put it on the torus mesh.
//   5. Nothing opaque may sit inside the plasma: hide the old Plasmatoroid meshes. Surfaces are never
//      painted with the plasma (v14 did that, which gave a flat banded donut whenever the volume
//      overlapped the vessel roof); they just block what is behind them.
//      Window glass must be Transparency = Alpha (alpha hash / scissor / opaque glass cut the plasma).
//      Set debug_view = 1 to check placement: blue = marched volume, red = opaque geometry inside
//      the plasma edge. Correctly placed, there is no red apart from small patches at the targets.
//   6. The camera may be inside or outside the box.
//
// TIME
//   Godot's TIME wraps at Project Settings > rendering/limits/time/time_rollover_secs (default 3600).
//   time_wrap must equal that setting. Every animation here is a whole number of cycles per wrap, so
//   the wrap is seamless and nothing loses precision however long the game runs. For the same reason
//   toroidal_speed is rounded to a whole number of turns per wrap. To run off your own clock instead,
//   set time_override >= 0 (seconds, keep it inside 0..time_wrap).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_front, shadows_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;

group_uniforms sim_inputs;
// Everything here is normalised and meant to be set from the simulation every frame.
uniform float plasma_current : hint_range(0.0, 1.0) = 1.0;   // 0 = no plasma (draws nothing), 1 = full flat-top brightness
uniform float density : hint_range(0.0, 1.0) = 0.5;          // edge density: more haze, a brighter and slightly thicker edge
uniform float edge_temp : hint_range(0.0, 1.0) = 0.5;        // edge temperature colour: 0 = cold blue, 0.5 = pink/lavender, 1 = red-orange
uniform float xpoint_balance : hint_range(-1.0, 1.0) = 0.4;  // -1 = lower divertor only, 0 = balanced double null, +1 = upper only
uniform float turbulence : hint_range(0.0, 1.0) = 0.4;       // filament contrast and shimmer
uniform float elm : hint_range(0.0, 1.0) = 0.0;              // ELM burst: pulse it 0 -> 1 -> 0 over ~50-200 ms
uniform float lithium : hint_range(0.0, 1.0) = 0.0;          // lithium puff: red sparks at the injector, green streaks along the field
uniform float lithium_angle : hint_range(-180.0, 180.0, 0.1) = 0.0; // where the injector is, degrees around Y from +X (fixed to the vessel)
uniform float startup : hint_range(0.0, 1.0) = 0.0;          // start-up look: blue, hazy, bright spots at tile edges
uniform float collapse : hint_range(0.0, 1.0) = 0.0;         // collapse look: red outside / blue rim ovals shrinking to the midplane, gone at 1
uniform float diverted : hint_range(0.0, 1.0) = 1.0;         // 0 = limited on the centre column, 1 = X-points + divertor legs
uniform float top_hot : hint_range(0.0, 1.0) = 1.0;          // master switch for the upper divertor contact (multiplies xpoint_balance)
uniform float h_mode : hint_range(0.0, 1.0) = 0.0;           // 0 = L-mode, 1 = H-mode (thinner, dimmer edge, less haze)
uniform float q95 : hint_range(1.0, 15.0) = 4.0;             // edge safety factor: filament pitch (rounded to a whole number)
uniform float z_offset = 0.0;                                // vertical plasma displacement from the sim (mesh units)
uniform float toroidal_angle = 0.0;                          // radians, added to the spin. Drive this and set toroidal_speed = 0 for sim-driven rotation
uniform float toroidal_speed = 49.0;                          // rad/s, rounded to a whole number of turns per time_wrap

group_uniforms shape;
uniform vec3 box_size = vec3(46.0, 24.0, 46.0);
// Outer limit of the bright plasma; the plasma edge sits at `separatrix` times this.
// Defaults fit plasmatoroid.blend: edge R0 12.90, half-width 3.88, elongation 1.55, triangularity 0.40, centre Y 0.68
uniform float major_radius = 12.9;   // R of the torus centre line
uniform float minor_radius = 4.22;   // plasma edge half-width / separatrix
uniform float elongation = 1.55;     // height / width
uniform float triangularity : hint_range(0.0, 0.8) = 0.435; // D-shape
uniform float center_y = 0.68;       // height of the torus centre above the BoxMesh centre
uniform float separatrix : hint_range(0.5, 1.0) = 0.92;
// where the divertor legs land, (R, Y) with Y measured from the BoxMesh centre
uniform vec2 strike_inner = vec2(10.3, -7.0);        // lower inner target
uniform vec2 strike_outer = vec2(14.3, -6.9);        // lower outer target
uniform vec2 strike_upper_inner = vec2(7.5, 8.3);    // NEW: top lip of the centre column
uniform vec2 strike_upper_outer = vec2(14.6, 10.2);  // NEW: roof
uniform int tile_count : hint_range(1, 96) = 24;     // NEW: tiles around the machine (gaps show as notches in the contact rings)
uniform float haze_reach : hint_range(1.0, 3.0) = 1.9; // NEW: how far the haze reaches, in minor radii from the torus centre line (about the vessel wall)

group_uniforms look;
uniform float intensity : hint_range(0.0, 10.0) = 1.0;       // overall brightness
uniform float peak : hint_range(0.5, 4.0) = 1.5;             // brightest output value (above 1 feeds the scene glow)
uniform float whiten : hint_range(0.0, 1.0) = 0.5;           // how much the brightest parts burn out to pink-white
uniform vec3 color_cold : source_color = vec3(0.30, 0.42, 1.0);   // edge_temp = 0
uniform vec3 color_mid : source_color = vec3(1.0, 0.50, 0.86);    // edge_temp = 0.5 (flat-top pink)
uniform vec3 color_hot : source_color = vec3(1.0, 0.28, 0.12);    // edge_temp = 1
uniform vec3 haze_color : source_color = vec3(0.55, 0.30, 1.0);   // tint of the haze and of the inboard edge
uniform vec3 lithium_neutral : source_color = vec3(1.0, 0.12, 0.05); // Li I sparks
uniform vec3 lithium_ion : source_color = vec3(0.15, 1.0, 0.35);     // Li II streaks
uniform float shell_width : hint_range(0.01, 0.3) = 0.035;   // edge layer thickness, relative to minor radius
uniform float edge_sharpness : hint_range(1.0, 6.0) = 2.0;   // how much crisper the outer side of the edge is
uniform float edge_base : hint_range(0.0, 4.0) = 1.0;        // edge brightness
uniform float face_dim : hint_range(0.0, 1.0) = 0.04;        // edge seen face-on vs edge-on. Low = see-through gas, high = solid shell
uniform float inner_glow : hint_range(0.0, 10.0) = 1.6;      // extra edge light on the centre-column side
uniform float filament_face : hint_range(0.0, 2.0) = 0.5;    // filament streaks seen face-on (the sweeping curtains)
uniform float haze : hint_range(0.0, 2.0) = 1.0;             // faint glow filling the vessel
uniform float haze_falloff : hint_range(0.05, 1.5) = 0.45;   // how fast the haze fades away from the edge (minor radii)
uniform float leg_width : hint_range(0.01, 0.3) = 0.05;      // divertor leg thickness, relative to minor radius
uniform float leg_strength : hint_range(0.0, 20.0) = 2.5;
uniform float hot_size : hint_range(0.01, 0.5) = 0.07;       // contact ring thickness, relative to minor radius
uniform float hot_strength : hint_range(0.0, 40.0) = 7.0;    // contact ring brightness
uniform float tile_gaps : hint_range(0.0, 1.0) = 0.7;        // depth of the notches at tile gaps
uniform float xpoint_asym : hint_range(0.0, 1.0) = 0.6;     // one side of the machine brighter
uniform float xpoint_asym_angle : hint_range(-180.0, 180.0, 1.0) = 180.0; // which side, degrees around Y from +X
uniform float contact_glow : hint_range(0.0, 5.0) = 1.0;     // glow painted on tiles at the strike lines
uniform float wall_light : hint_range(0.0, 1.0) = 0.05;      // soft light on surfaces facing the plasma
uniform float wall_falloff : hint_range(0.1, 10.0) = 2.0;    // how far that reaches (mesh units)
uniform float near_fade : hint_range(0.0, 10.0) = 1.5;       // glow fades in over this distance from the camera (mesh units)

group_uniforms perf;
uniform int max_steps : hint_range(8, 160) = 40;             // sample budget per pixel
uniform float step_scale : hint_range(0.5, 2.0) = 1.0;       // sample spacing. >1 = faster and rougher
uniform bool filaments = true;                               // off = no filament texture (saves two atan per edge sample)

group_uniforms time;
uniform float time_wrap = 3600.0;      // MUST equal rendering/limits/time/time_rollover_secs
uniform float time_override = -1.0;    // >= 0: use this instead of TIME (seconds, 0..time_wrap)
uniform bool msaa_edge_fix = true; // v15.1: stops dotted holes along mesh edges when MSAA is on (4 extra depth reads per pixel)
uniform int debug_view : hint_range(0, 1) = 0; // 1 = show march volume (blue), plasma edge (green), opaque geometry inside the plasma (red)

// internal balance, tuned against renders. Change the uniforms, not these.
const float EDGE_GAIN = 1.1;
const float LEG_GAIN = 0.12;
const float RING_GAIN = 2.0;
const float HAZE_GAIN = 0.03;
const float WALL_GAIN = 0.5;
const float LI_GAIN = 1.6;
const float PITCH = 0.8;
const float LEG_START = 0.35; // legs are drawn over the part nearer the target; by the X-point they are too faint to be worth the samples

varying vec3 lpos;
varying flat vec3 cam_local;
varying flat vec3 zrow;    // view depth gained per unit of local-space travel
varying flat vec4 fph;     // filament modes 1, 2 as (cos, -sin) of their phase
varying flat vec4 fph2;    // xy = filament mode 3, z = lithium flow phase, w = spark clock (0..1)
varying flat vec3 misc;    // xy = bright-side direction, z = flicker
varying flat vec3 ecol;    // edge colour for the current state
varying flat vec3 hcol;    // haze colour for the current state

// Everything that is the same for every sample along a ray, worked out once per pixel.
struct Ctx {
	vec4 geo;    // R0, edge radius, vertical shift, 1 / elongation   (minor-radius units)
	vec4 shl;    // 1 / edge width, edge width, edge brightness, filament contrast
	vec4 shl2;   // face-on brightness, face-on streak brightness, q, haze cut-off start
	vec4 hz;     // 1 / outer falloff, 1 / inner falloff, floor, brightness
	vec4 li;     // lower inner leg: start (R, Y), target (R, Y)
	vec4 lo;     // lower outer leg
	vec4 ui;     // upper inner leg
	vec4 uo;     // upper outer leg
	vec3 bl;     // lower divertor bounds: R min, R max, Y top
	vec3 bu;     // upper divertor bounds: R min, R max, Y bottom
	vec4 dw;     // lower weight, upper weight, leg brightness, ring brightness
	vec2 lith;   // injector direction
};

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// interleaved gradient noise: even per-pixel offsets
float ign(vec2 px) {
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

vec2 cmul(vec2 a, vec2 b) {
	return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

// distance from p to segment s.xy -> s.zw; u = 0 at the start, 1 at the end
float seg(vec2 p, vec4 s, out float u) {
	vec2 ba = s.zw - s.xy;
	vec2 pa = p - s.xy;
	u = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * u);
}

Ctx make_ctx() {
	Ctx c;
	float a = minor_radius;
	float size = 1.0 - 0.5 * collapse;               // collapse: the cross-section shrinks towards the midplane
	float el = elongation * (1.0 - 0.45 * collapse);
	float zc = z_offset / a;
	float rs = separatrix * size;
	c.geo = vec4(major_radius / a, rs, zc, 1.0 / el);
	float dens_gain = 0.45 + 1.1 * density;
	float sw = shell_width * mix(1.0, 0.6, h_mode) * (1.0 + 9.0 * collapse + 2.0 * startup) * (0.8 + 0.4 * density) * rs;
	float tb = turbulence * (1.0 + 2.0 * elm);
	c.shl = vec4(1.0 / sw, sw, EDGE_GAIN * edge_base * dens_gain * mix(1.0, 0.5, h_mode) * (1.0 - 0.6 * startup), tb);
	c.shl2 = vec4(mix(face_dim, 0.7, collapse), filament_face * tb * (1.0 - collapse), max(1.0, round(q95)), 0.7 * haze_reach);
	c.hz = vec4(1.0 / haze_falloff, 1.0 / mix(0.1, 0.6, startup), 0.75 * startup,
	            HAZE_GAIN * haze * 2.0 * density * (1.0 - 0.4 * h_mode) * (1.0 + 2.0 * startup + 2.0 * elm));
	// divertor geometry
	float dv = diverted * (1.0 - collapse);
	float w_up = mix(top_hot * clamp(1.0 + xpoint_balance, 0.0, 1.0), 1.0, startup) * dv;
	float w_lo = mix(clamp(1.0 - xpoint_balance, 0.0, 1.0), 1.0, startup) * dv;
	float burst = (1.0 + 3.0 * elm) * dens_gain;
	c.dw = vec4(w_lo, w_up, LEG_GAIN * leg_strength * burst * (1.0 - 0.8 * startup), RING_GAIN * hot_strength * burst);
	float xr = c.geo.x - triangularity * separatrix * separatrix;
	float xz = separatrix * elongation;
	vec2 off = vec2(0.0, center_y);
	vec2 xl = vec2(xr, zc - xz);
	vec2 xu = vec2(xr, zc + xz);
	vec2 t;
	t = (strike_inner - off) / a;
	c.li = vec4(mix(xl, t, LEG_START), t);
	t = (strike_outer - off) / a;
	c.lo = vec4(mix(xl, t, LEG_START), t);
	t = (strike_upper_inner - off) / a;
	c.ui = vec4(mix(xu, t, LEG_START), t);
	t = (strike_upper_outer - off) / a;
	c.uo = vec4(mix(xu, t, LEG_START), t);
	float reach = 2.5 * max(leg_width, hot_size);
	c.bl = vec3(min(min(c.li.x, c.li.z), min(c.lo.x, c.lo.z)) - reach, max(max(c.li.x, c.li.z), max(c.lo.x, c.lo.z)) + reach,
	            max(max(c.li.y, c.li.w), max(c.lo.y, c.lo.w)) + reach);
	c.bu = vec3(min(min(c.ui.x, c.ui.z), min(c.uo.x, c.uo.z)) - reach, max(max(c.ui.x, c.ui.z), max(c.uo.x, c.uo.z)) + reach,
	            min(min(c.ui.y, c.ui.w), min(c.uo.y, c.uo.w)) - reach);
	// a divertor that is switched off gets empty bounds, so it costs nothing
	if (w_lo <= 0.001) {
		c.bl.z = -1e4;
	}
	if (w_up <= 0.001) {
		c.bu.z = 1e4;
	}
	float la = radians(lithium_angle);
	c.lith = vec2(cos(la), sin(la));
	return c;
}

// p in units of minor radius, relative to the torus centre. rd = ray direction.
// limb = 1 while marching (view-dependent edge), 0 when looking up a surface point.
// Returns rgb = light per unit length, w = safe step to the next sample (minor-radius units).
// hot = contact ring light on its own; edge_d = signed distance to the plasma edge (negative inside).
vec4 plasma(vec3 p, vec3 rd, float limb, Ctx c, out float hot, out float edge_d) {
	hot = 0.0;
	float R = length(p.xz);
	vec2 cs = p.xz / max(R, 1e-4);
	float y = (p.y - c.geo.z) * c.geo.w;
	vec2 pol = vec2(R - c.geo.x + triangularity * y * y, y);
	float lp = max(length(pol), 1e-4);
	vec2 dir = pol / lp;
	edge_d = lp - c.geo.y;

	// thin edge layer: soft towards the inside, crisp at the boundary
	float es = edge_d * c.shl.x;
	float sharp = es > 0.0 ? edge_sharpness : 1.0;
	float e = es * sharp;
	// step: jump to within 2.5 widths of the layer, then cross it in steps of about 1.5 widths
	float wn = c.shl.y / sharp;
	float hn = 1.5 * step_scale * wn;
	float stp = max(abs(edge_d) - 2.5 * wn, 0.0) * 0.95 + hn;

	// --- haze: fills the vessel, strongest just outside the edge, dark in the core
	float hz = max(exp(edge_d > 0.0 ? -edge_d * c.hz.x : edge_d * c.hz.y), c.hz.z);
	hz *= 1.0 - smoothstep(c.shl2.w, haze_reach, lp);
	vec3 col = (c.hz.w * hz) * hcol;

	// --- edge layer
	float theta = 0.0;
	bool have_theta = false;
	if (e * e < 6.25) {
		vec3 n = normalize(vec3(dir.x * cs.x, dir.y * c.geo.w, dir.x * cs.y));
		float cosn = abs(dot(n, rd));
		// a real emitting layer is far thinner than we can afford to sample, which makes it much
		// brighter edge-on than face-on. Fake that with the view angle.
		stp = min(stp, hn / max(cosn, 0.25));
		float g = 1.0 - cosn;
		g *= g;
		g *= g;
		float lf = mix(1.0, c.shl2.x + (1.0 - c.shl2.x) * g * g, limb);
		float inb = max(-dir.x, 0.0);
		inb *= inb;
		float ob = smoothstep(-0.2, 0.6, dir.x);
		// field-aligned filaments: stripes of constant (phi - q * theta), q a whole number so they
		// close on themselves both ways round. They rotate rigidly with the plasma.
		float fil = 0.5;
		float streak = 0.0;
		if (filaments) {
			theta = atan(pol.y, pol.x);
			have_theta = true;
			// theta - PITCH * sin(theta): field lines are steep on the outboard side and shallow by the column
			float w = c.shl2.z * (theta - PITCH * dir.y);
			// z = exp(i * (phi - w)); the harmonics come from complex powers instead of more trig
			vec2 z = cmul(cs, vec2(cos(w), -sin(w)));
			vec2 z2 = cmul(z, z);
			vec2 z4 = cmul(z2, z2);
			vec2 z5 = cmul(z4, z);
			vec2 z11 = cmul(cmul(z5, z5), z);
			float f1 = dot(z2, fph.xy);
			float f2 = dot(z5, fph.zw);
			float f3 = dot(z11, fph2.xy);
			fil = 0.5 + 0.5 * (0.45 * f1 + 0.33 * f2 * (0.6 + 0.4 * f1) + 0.22 * f3);
			streak = smoothstep(0.55, 0.95, fil + 0.25 * f3 * f2);
		}
		// limb light with filament contrast, plus the filaments seen face-on as faint streaks
		float lightf = lf * (1.0 + c.shl.w * (1.6 * fil - 0.8))
		             + limb * c.shl2.y * (2.5 + 3.0 * elm * ob) * streak * (0.35 + 0.65 * ob);
		float amt = exp(-e * e) * c.shl.z * lightf * (1.0 + inner_glow * inb * inb) * (1.0 - 0.65 * ob);
		// colour: edge colour, violet on the column side; in a collapse red outside and blue inside
		vec3 ec = mix(ecol, hcol, 0.55 * inb);
		if (collapse > 0.001) {
			ec = mix(ec, mix(vec3(0.25, 0.35, 1.0), vec3(1.0, 0.2, 0.06), smoothstep(-1.0, 0.6, es)), min(1.0, 1.6 * collapse));
		}
		col += amt * ec;
	}

	// --- divertor legs and contact rings. Only the divertor on this side of the midplane is looked at,
	// and only inside its bounding box; otherwise just step towards the box.
	bool up = p.y > c.geo.z;
	vec3 bb = up ? c.bu : c.bl;
	float outside = max(up ? bb.z - p.y : p.y - bb.z, max(bb.x - R, R - bb.y));
	vec2 fine = step_scale * vec2(1.1 * leg_width, 1.2 * hot_size);
	if (outside < 0.0) {
		vec4 si = up ? c.ui : c.li;
		vec4 so = up ? c.uo : c.lo;
		vec2 q = vec2(R, p.y);
		float u_i;
		float u_o;
		float di = seg(q, si, u_i);
		float dout = seg(q, so, u_o);
		vec2 qa = q - si.zw;
		vec2 qb = q - so.zw;
		float ri = dot(qa, qa);
		float ro = dot(qb, qb);
		vec2 gap = max(vec2(min(di, dout) - 2.5 * leg_width, sqrt(min(ri, ro)) - 2.5 * hot_size), vec2(0.0));
		stp = min(stp, min(gap.x * 0.9 + fine.x, gap.y * 0.9 + fine.y));
		if (gap.x * gap.y <= 0.0) {
			float wgt = up ? c.dw.y : c.dw.x;
			float il = 1.0 / (leg_width * leg_width);
			float ih = 1.0 / (hot_size * hot_size);
			float legs = exp(-di * di * il) * (0.1 + 0.9 * u_i) + 0.6 * exp(-dout * dout * il) * (0.1 + 0.9 * u_o);
			float ring = exp(-ri * ih) + 0.45 * exp(-ro * ih);
			if (ring > 0.003) {
				// tiles: notches at the gaps in flat-top, isolated bright spots at tile edges at start-up
				float tc = float(tile_count);
				float tt = atan(p.z, p.x) * tc / TAU;
				float te = abs(fract(tt) - 0.5) * 2.0; // 0 = tile centre, 1 = gap
				float notch = 1.0 - tile_gaps * smoothstep(0.78, 0.95, te);
				if (startup > 0.001) {
					float sd = (1.0 - te) * tc * 0.125;
					float spots = 6.0 * exp(-sd * sd * 40.0) * step(0.45, hash12(vec2(mod(floor(tt + 0.5), tc), 3.0)));
					notch = mix(notch, spots, startup);
				}
				ring *= notch;
			}
			// one side of the machine brighter than the other
			wgt *= 1.0 + xpoint_asym * dot(cs, misc.xy);
			hot = c.dw.w * ring * wgt;
			col += (c.dw.z * legs * wgt) * ecol + hot * mix(ecol, vec3(1.0), 0.2);
		}
	} else {
		stp = min(stp, outside + min(fine.x, fine.y));
	}

	// --- lithium puff: neutral sparks at the injector, ions streaming along the field line through it
	if (lithium > 0.001) {
		const float TH0 = 0.95; // poloidal angle of the injector (outboard, above the midplane)
		// toroidal distance from the injector, wrapped to -pi..pi without a seam
		float dphi = atan(cs.y * c.lith.x - cs.x * c.lith.y, cs.x * c.lith.x + cs.y * c.lith.y);
		float th = have_theta ? theta : atan(pol.y, pol.x);
		float dth = th - PITCH * dir.y - (TH0 - PITCH * sin(TH0)) - dphi / c.shl2.z;
		float er = (edge_d - 0.07) / 0.055;
		if (abs(dth) < 0.6 && er * er < 6.0) {
			// streaks: a bundle of field lines through the injector, fading with distance along the field
			float sub = 0.55 + 0.45 * cos(dth * 46.0 + 1.7 * sin(dphi * 3.0 + fph2.z));
			float along = exp(-dphi * dphi / 1.4) * (0.7 + 0.3 * cos(dphi * 9.0 - fph2.z));
			col += (LI_GAIN * lithium * exp(-dth * dth / 0.02 - er * er) * sub * along) * lithium_ion;
			stp = min(stp, max(abs(edge_d - 0.07) - 0.1, 0.0) * 0.9 + step_scale * 0.05);
		}
		// sparks: small twinkling blobs in a patch just outside the edge
		float es2 = (edge_d - 0.2) / 0.09;
		if (abs(dphi) < 0.34 && abs(dth) < 0.5 && es2 * es2 < 4.0) {
			vec3 gp = vec3(dphi * 22.0, dth * 15.0, es2 * 1.5);
			vec3 gi = floor(gp);
			float hsd = hash12(gi.xy + 17.0 + 7.3 * gi.z);
			vec3 off = gp - gi - 0.5 - 0.3 * (vec3(hsd, fract(hsd * 57.3), fract(hsd * 91.7)) - 0.5);
			// each spark blinks a whole number of times per wrap
			float tw = sin(TAU * (fph2.w * (1.0 + floor(hsd * 3.0)) + fract(hsd * 13.7)));
			float sp = exp(-dot(off, off) * 60.0) * smoothstep(0.3, 1.0, tw) * step(0.35, hsd)
			         * exp(-dphi * dphi / 0.03 - dth * dth / 0.06 - es2 * es2);
			col += (LI_GAIN * 14.0 * lithium * sp) * lithium_neutral;
			stp = min(stp, step_scale * 0.035);
		}
	}

	return vec4(col, stp);
}

void vertex() {
	lpos = VERTEX;
	cam_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	// third row of the model-view matrix: local direction -> view-space depth
	mat3 mv = mat3(MODELVIEW_MATRIX);
	zrow = -vec3(mv[0].z, mv[1].z, mv[2].z);

	// u runs 0..1 once per TIME wrap. Every phase below is fract(u * whole number), so the
	// wrap is invisible and precision never degrades.
	float wrap = max(time_wrap, 1e-3);
	float u = fract((time_override >= 0.0 ? time_override : TIME) / wrap);
	float tor = TAU * fract(u * round(toroidal_speed * wrap / TAU)) + toroidal_angle;
	// the three filament modes turn with the plasma, each with its own slow drift (shimmer)
	float p1 = -2.0 * tor + TAU * fract(u * round(0.05 * wrap));
	float p2 = -5.0 * tor - TAU * fract(u * round(0.13 * wrap));
	float p3 = -11.0 * tor + TAU * fract(u * round(0.31 * wrap));
	fph = vec4(cos(p1), -sin(p1), cos(p2), -sin(p2));
	fph2 = vec4(cos(p3), -sin(p3), TAU * fract(u * round(0.8 * wrap)), fract(u * round(1.7 * wrap)));
	float aa = radians(xpoint_asym_angle);
	float fl = sin(TAU * fract(u * round(7.3 * wrap))) + sin(TAU * fract(u * round(11.9 * wrap)) + 1.3);
	misc = vec3(cos(aa), sin(aa), 1.0 + 0.04 * turbulence * (1.0 + 3.0 * elm) * fl);

	// colour of the current state
	float t = clamp(edge_temp - 0.4 * startup + 0.6 * collapse, 0.0, 1.0);
	ecol = t < 0.5 ? mix(color_cold, color_mid, t * 2.0) : mix(color_mid, color_hot, t * 2.0 - 1.0);
	hcol = mix(haze_color, ecol, 0.35 + 0.4 * max(startup, collapse));
}

void fragment() {
	// everything below works relative to the torus centre
	vec3 ro = cam_local - vec3(0.0, center_y, 0.0);
	vec3 rd = normalize(lpos - cam_local);
	float a = minor_radius;
	float amp = intensity * plasma_current * (1.0 - smoothstep(0.55, 1.0, collapse)) * misc.z;
	if (amp <= 0.0 && debug_view == 0) {
		discard;
	}

	// the light only exists inside a slab (height) and a cylinder (outer radius): march just that
	vec3 bh = box_size * 0.5;
	float yext = a * elongation * haze_reach;
	float ylo = max(-bh.y - center_y, -yext);
	float yhi = min(bh.y - center_y, yext);
	float rmax = min(min(bh.x, bh.z), major_radius + a * haze_reach);
	float iy = 1.0 / (abs(rd.y) > 1e-5 ? rd.y : 1e-5);
	float ta = (ylo - ro.y) * iy;
	float tb = (yhi - ro.y) * iy;
	float tn = max(min(ta, tb), 0.0);
	float tf = max(ta, tb);
	float qa = max(dot(rd.xz, rd.xz), 1e-6);
	float qb = dot(ro.xz, rd.xz);
	float qd = qb * qb - qa * (dot(ro.xz, ro.xz) - rmax * rmax);
	if (qd <= 0.0) {
		discard;
	}
	qd = sqrt(qd);
	tn = max(tn, (-qb - qd) / qa);
	tf = min(tf, (-qb + qd) / qa);

	// stop at opaque geometry. Linear view depth of the scene behind this pixel
	// (Forward+/Mobile: reverse-Z, NDC z = raw depth. Compatibility: NDC z = depth * 2 - 1).
	float depth = textureLod(depth_tex, SCREEN_UV, 0.0).r;
	if (msaa_edge_fix) {
		// MSAA: the depth texture holds one sample per pixel, so on mesh edges it can report the
		// near mesh and punch a dotted hole in the plasma. Use the farthest depth of the 4 neighbours.
		vec2 px = 1.0 / VIEWPORT_SIZE;
		vec4 dn = vec4(textureLod(depth_tex, SCREEN_UV + vec2(px.x, 0.0), 0.0).r,
		               textureLod(depth_tex, SCREEN_UV - vec2(px.x, 0.0), 0.0).r,
		               textureLod(depth_tex, SCREEN_UV + vec2(0.0, px.y), 0.0).r,
		               textureLod(depth_tex, SCREEN_UV - vec2(0.0, px.y), 0.0).r);
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
		depth = max(depth, max(max(dn.x, dn.y), max(dn.z, dn.w)));   // larger = farther
#else
		depth = min(depth, min(min(dn.x, dn.y), min(dn.z, dn.w)));   // reverse-Z: smaller = farther
#endif
	}
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
#else
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
#endif
	float scene_z = -view.z / view.w;
	float scene_t = scene_z / max(dot(rd, zrow), 1e-5);
	bool hit = scene_t < tf;
	tf = min(tf, scene_t);
	// something opaque is in front of the whole volume (a wall, another room): draw nothing
	if (tf <= tn) {
		discard;
	}

	Ctx ctx = make_ctx();
	float dt_max = 1.2 * a;
	float s = tn + 0.03 * a * ign(FRAGCOORD.xy);
	vec3 dens = vec3(0.0);
	float hsum = 0.0;
	vec4 pv = vec4(0.0);
	float ph = 0.0;
	float pdt = 0.0;
	float inv_fade = 1.0 / max(near_fade, 1e-3);
	float ed = 1.0;
	float h = 0.0;
	for (int i = 0; i < max_steps; i++) {
		vec4 v = plasma((ro + rd * s) / a, rd, 1.0, ctx, h, ed);
		float nf = min(s * inv_fade, 1.0);
		v.rgb *= nf;
		h *= nf;
		// trapezoid rule
		dens += (pv.rgb + v.rgb) * (0.5 * pdt);
		hsum += (ph + h) * (0.5 * pdt);
		if (s >= tf) {
			break;
		}
		pdt = min(min(v.w * a, dt_max), tf - s);
		s += pdt;
		pv = v;
		ph = h;
	}
	dens /= a;
	hsum /= a;

	// `ed` is now the distance from the plasma edge at the end of the ray (the surface, if it hit one)
	// (if the sample budget ran out first, treat it as no surface)
	hit = hit && s >= tf;
	bool inside_hit = hit && ed < 0.0;
	if (hit) {
		// Surfaces get the strike-line glow (already in the march: the rings sit on the tiles) and a
		// soft wash from the nearby edge. They are never painted with the plasma itself, so a mesh
		// inside the volume just blocks what is behind it.
		if (wall_light > 0.0) {
			// surface normal from the depth buffer
			vec3 hp = ro + rd * tf;
			vec3 nrm = normalize(cross(dFdx(hp), dFdy(hp)));
			float facing = 0.25 + 0.75 * abs(dot(nrm, rd));
			dens += ecol * (WALL_GAIN * wall_light * facing * exp(-max(ed, 0.0) * a / wall_falloff) * (0.45 + 1.1 * density));
		}
		dens += (contact_glow * 0.25 * h) * mix(ecol, vec3(1.0), 0.2);
	}

	vec3 c = dens * amp;
	// hue-preserving tonemap: stays pink instead of blowing out, only the hottest contact burns white
	float m = max(c.r, max(c.g, c.b));
	c /= 1.0 + m / peak;
	m = max(c.r, max(c.g, c.b));
	c = mix(c, vec3(m), whiten * smoothstep(0.6, 3.0, hsum * amp));

	if (debug_view == 1) {
		// blue = marched volume, red = opaque geometry inside the plasma edge
		c = c * 0.5 + vec3(0.0, 0.0, 0.08) + (inside_hit ? vec3(0.6, 0.0, 0.0) : vec3(0.0));
	}

	ALBEDO = c;
	ALPHA = 1.0;
}
