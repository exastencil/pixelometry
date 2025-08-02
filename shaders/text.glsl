@ctype mat4 [16]f32

@vs vs
layout(binding=0) uniform vs_params {
    mat4 mvp;
};

in vec2 position;
in vec2 texcoord;
in vec4 color;

out vec2 uv;
out vec4 frag_color;

void main() {
    gl_Position = mvp * vec4(position, 0.0, 1.0);
    uv = texcoord;
    frag_color = color;
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
in vec4 frag_color;
out vec4 frag_color_out;

void main() {
    // Sample the texture
    vec4 tex_color = texture(sampler2D(tex, smp), uv);
    // Use the texture alpha as a mask and apply the text color
    frag_color_out = vec4(frag_color.rgb, tex_color.a * frag_color.a);
}
@end

@program text vs fs
