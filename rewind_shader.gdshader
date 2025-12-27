shader_type canvas_item;

uniform bool rewinding = false;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    if (rewinding) {
        // Blue tint
        color.rgb = mix(color.rgb, vec3(0.5, 0.7, 1.0), 0.3 * intensity);
        
        // Vignette effect (darken edges)
        vec2 uv_center = UV - 0.5;
        float vignette = 1.0 - dot(uv_center, uv_center) * 0.8;
        color.rgb *= vignette;
        
        // Scan lines
        float scan_line = sin(FRAGCOORD.y * 3.0 + TIME * 20.0) * 0.05 + 0.95;
        color.rgb *= scan_line;
        
        // Chromatic aberration (red/blue shift) - simplified
        float shift_amount = 0.003 * intensity;
        color.r = texture(TEXTURE, UV + vec2(shift_amount, 0.0)).r;
        color.b = texture(TEXTURE, UV - vec2(shift_amount, 0.0)).b;
    }
    
    COLOR = color;
}