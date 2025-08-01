@ctype mat4 [16]f32

@vs vs
layout(binding=0) uniform vs_params {
    mat4 mvp;
};

in vec2 position;
in vec4 color;

out vec4 frag_color;

void main() {
    gl_Position = mvp * vec4(position, 0.0, 1.0);
    frag_color = color;
}
@end

@fs fs
in vec4 frag_color;
out vec4 frag_color_out;

void main() {
    frag_color_out = frag_color;
}
@end

@program pixel vs fs
