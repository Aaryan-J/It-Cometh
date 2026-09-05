shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float grainAmount: hint_range(0.0, 0.1) = 0.04;
uniform float grainSize: hint_range(0.1, 10.0) = 1.8;

uniform float vignetteIntensity: hint_range(0.0, 3.0) = 1.2;
uniform float vignetteOpacity: hint_range(0.0, 1.0) = 0.85;

uniform vec4 tintColor: source_color = vec4(0.85, 0.9, 1.0, 1.0);

float generateNoise(vec2 uv, float time) {
	return fract(sin(dot(uv.xy + vec2(time, time), vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec3 sceneColor = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	
	sceneColor *= tintColor.rgb;
	
	float noise = generateNoise(floor(UV * (1000.0 / grainSize)) / (1000.0 / grainSize), TIME);
	sceneColor += vec3(noise - 0.5) * grainAmount;
	
	vec2 uvCentered = UV - 0.5;
	float distFromCenter = length(uvCentered);
	
	float vignette = smoothstep(0.5, 0.5 - (vignetteIntensity * 0.3), distFromCenter);
	
	sceneColor = mix(sceneColor * vignette, sceneColor, 1.0 - vignetteOpacity);
	
	COLOR = vec4(sceneColor, 1.0);
}