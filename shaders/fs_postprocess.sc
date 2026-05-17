#version 150
in vec2 v_texcoord0;
out vec4 out_color;

uniform sampler2D s_texColor;

void main() {
  vec4 col = texture(s_texColor, v_texcoord0);
  float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
  col.rgb = vec3(gray);
  out_color = col;
}
