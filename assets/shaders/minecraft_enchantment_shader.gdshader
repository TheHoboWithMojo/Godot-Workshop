shader_type canvas_item;

// Uniforms to control the overlay texture and transparency level
uniform sampler2D overlay_texture : hint_default_white;
uniform float zoom_factor : hint_range(1.0, 10.0) = 7.0;
uniform float move_speed : hint_range(0.0, 5.0) = 0.2;
uniform float transparency : hint_range(1.0, 100.0) = 60.0; // Transparency level between 1 and 100

void fragment() {
    // Base texture color
    vec4 base_color = texture(TEXTURE, UV);

    // Calculate offset for random movement based on time
    float offset_x = sin(TIME * move_speed * 1.3 + sin(TIME * move_speed * 0.7)) * 0.05;
    float offset_y = cos(TIME * move_speed * 0.9 + cos(TIME * move_speed * 0.5)) * 0.05;

    // Apply zoom and offset to UV coordinates for the overlay
    vec2 zoomed_uv = (UV - 0.5) / zoom_factor + 0.5 + vec2(offset_x, offset_y);

    // Sample the overlay texture
    vec4 overlay_color = texture(overlay_texture, zoomed_uv);

    // Convert transparency percentage to a 0.0 - 1.0 range
    float transparency_factor = clamp(transparency / 100.0, 0.0, 1.0);

    // Determine if the overlay should be applied per pixel
    float overlay_blend_factor = (base_color.a > 0.0) ? (transparency_factor * overlay_color.a) : 0.0;

    // Blend the overlay with the base texture using the computed blend factor
    COLOR = mix(base_color, overlay_color, overlay_blend_factor);
}