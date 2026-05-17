#version 150
in vec2 v_texcoord0;
in vec2 v_world_xy;
out vec4 out_color;

uniform sampler2D s_texColor;
uniform vec4 u_terrainLod; // x=camera_x y=camera_y z=near_radius w=inv_fade_range

void main() {
  vec4 tex = texture(s_texColor, v_texcoord0);
  vec4 flat_col = vec4(0.58, 0.72, 0.52, 1.0);
  float dist = distance(v_world_xy, u_terrainLod.xy);
  float t = clamp((dist - u_terrainLod.z) * u_terrainLod.w, 0.0, 1.0);
  out_color = mix(tex, flat_col, t);
}
