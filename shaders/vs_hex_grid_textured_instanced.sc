#version 150
in vec3 a_position;
in vec2 a_texcoord0;
in vec4 i_data0;
out vec2 v_texcoord0;
out vec2 v_world_xy;

uniform mat4 u_modelViewProj;

void main() {
  vec3 world = vec3(a_position.xy * i_data0.w + i_data0.xy, a_position.z + i_data0.z);
  gl_Position = u_modelViewProj * vec4(world, 1.0);
  v_texcoord0 = a_texcoord0;
  v_world_xy = world.xy;
}
