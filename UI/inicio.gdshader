shader_type canvas_item;

uniform vec4 bg_color = vec4(0.1, 0.1, 0.1, 1.0); // Gris oscuro por defecto

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (tex_color.a < 0.1) {
        COLOR = bg_color;
    } else {
        COLOR = tex_color;
    }
}