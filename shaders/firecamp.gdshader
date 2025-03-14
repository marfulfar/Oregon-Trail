shader_type canvas_item;

uniform float intensity = 1.0;

render_mode blend_add;

void fragment() {
    float dist = distance(UV, vec2(0.5, 0.5)); // Calculate distance from center
    float falloff = 1.0 - smoothstep(0.0, 0.8, dist); // Adjust falloff range
    COLOR = texture(TEXTURE, UV) * intensity * falloff;
}