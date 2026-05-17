#version 150
in vec2 v_texcoord0;
out vec4 out_color;

uniform sampler2D s_texColor;

void main() {
  out_color = texture(s_texColor, v_texcoord0);
}
