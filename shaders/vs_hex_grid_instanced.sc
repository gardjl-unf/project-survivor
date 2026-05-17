#version 150
in vec3 a_position;
in vec4 i_data0;
in vec4 i_data1;
out vec4 v_color0;

uniform mat4 u_modelViewProj;

void main() {
  vec3 world = vec3(a_position.xy * i_data0.w + i_data0.xy, a_position.z + i_data0.z);
  gl_Position = u_modelViewProj * vec4(world, 1.0);
  v_color0 = i_data1;
}
