#version 150
in vec3 a_position;
in vec2 a_texcoord0;
out vec2 v_texcoord0;

void main() {
  gl_Position = vec4(a_position, 1.0);
  v_texcoord0 = a_texcoord0;
}
