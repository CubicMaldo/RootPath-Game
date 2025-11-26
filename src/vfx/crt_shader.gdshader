shader_type canvas_item;

uniform float aberration : hint_range(0.0, 1.0) = 0.03;
uniform float brightness : hint_range(0.0, 2.0) = 1.4;
uniform bool discolor = true;
uniform float warp_amount : hint_range(0.0, 5.0) = 1.0;
uniform bool clip_warp = false;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec2 warp(vec2 uv) {
	vec2 dc = abs(0.5 - uv);
	dc *= dc;
	return uv + (uv - 0.5) * dc * (warp_amount - 1.0);
}

void fragment() {
	vec2 uv = warp(SCREEN_UV);
	vec2 text_uv = uv;
	vec2 clip_uv = uv;

	if (clip_warp) {
		text_uv = clip_uv;
		if (text_uv.x < 0.0 || text_uv.x > 1.0 || text_uv.y < 0.0 || text_uv.y > 1.0) {
			discard;
		}
	}

	vec4 text = texture(SCREEN_TEXTURE, text_uv);
	
	if (discolor) {
		float r = texture(SCREEN_TEXTURE, text_uv - vec2(aberration, 0.0)).r;
		float g = texture(SCREEN_TEXTURE, text_uv).g;
		float b = texture(SCREEN_TEXTURE, text_uv + vec2(aberration, 0.0)).b;
		text = vec4(r, g, b, 1.0);
	}

	text.rgb *= brightness;
	
	// Scanlines
	float scanline = sin(uv.y * 800.0) * 0.04;
	text.rgb -= scanline;
	
	// Vignette
	float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
	vignette = pow(16.0 * vignette, vignette_intensity);
	text.rgb *= mix(1.0, vignette, vignette_opacity);

	COLOR = text;
}
