#version 150
in vec2 v_texcoord0;
in vec4 v_color0;
out vec4 out_color;

uniform sampler2D s_texColor;

void main() {
  vec4 texel = texture(s_texColor, v_texcoord0);
  vec4 result = texel * v_color0;
  
  // Alpha test for pixel art - discard fully transparent pixels
  if (result.a < 0.01) {
    discard;
  }
  
  out_color = result;
}
