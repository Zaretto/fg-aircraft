// -*-C++-*-

#version 120

varying vec3 vertex;
varying vec3 viewDir;

uniform float osg_SimulationTime;
uniform float thrust_collimation;
uniform float flame_radius_fraction;
uniform float thrust_density;
uniform float base_flame_density;
uniform float shock_frequency;
uniform float noise_strength;
uniform float noise_scale;
uniform float deflection_coeff;

uniform float flame_color_low_r;
uniform float flame_color_low_g;
uniform float flame_color_low_b;

uniform float flame_color_high_r;
uniform float flame_color_high_g;
uniform float flame_color_high_b;

uniform float base_flame_r;
uniform float base_flame_g;
uniform float base_flame_b;

uniform int use_shocks;
uniform int use_noise;

float Noise3D(in vec3 coord, in float wavelength);
float Noise2D(in vec2 coord, in float wavelength);

const int n_steps = 15;

float spherical_smoothstep (in vec3 pos)
{

float l = length(vec3 (pos.x/2.0, pos.y,pos.z) );

return 10.0 * thrust_density * base_flame_density *  (1.0 - smoothstep(0.5* flame_radius_fraction, flame_radius_fraction, l));

}



float thrust_flame (in vec3 pos)
{


//float noise = Noise3D(vec3(pos.x - osg_SimulationTime * 20.0 , pos.y, pos.z), 0.3);
float noise = 0.0;

pos.z +=8.0 * deflection_coeff;

float d_rad = length(pos.yz - vec2 (0.0, deflection_coeff * pos.x * pos.x));
//float longFade = smoothstep(0.0, 5.0, pos.x) ;
float longFade = pos.x/5.0;

float density = 1.0 - longFade;
float radius = flame_radius_fraction + thrust_collimation * 1.0 * pow((pos.x+0.1),0.5);

if (d_rad > radius) {return 0.0;}


if (use_noise ==1)
	{
	noise = Noise2D(vec2(pos.x - osg_SimulationTime * 30.0 , d_rad), noise_scale);
	}

density *= (1.0 - smoothstep(0.125, radius, d_rad)) * (1.0 - noise_strength + noise_strength* noise);

if (use_shocks == 1)
	{
	float shock = sin(pos.x * 10.0 * shock_frequency);
	density += shock * shock * shock * shock * (1.0 - longFade) * (1.0 - smoothstep(0.25*flame_radius_fraction, 0.5*flame_radius_fraction, d_rad)) *  (1.0 - smoothstep(0.0, 1.0, thrust_collimation));
	}


return 10.0 * thrust_density *  density / (radius/0.2);
}



void main()
{

vec3 vDir = normalize(viewDir);

float x_E, y_E, z_E;

if (vDir.x > 0.0) {x_E = 5.0;} else {x_E = 0.0;}
if (vDir.y > 0.0) {y_E = 1.0;} else {y_E = -1.0;}
if (vDir.z > 0.0) {z_E = 1.0;} else {z_E = -1.0;}

float t_x = (x_E - vertex.x) / vDir.x;
float t_y = (y_E - vertex.y) / vDir.y;
float t_z = (z_E - vertex.z) / vDir.z;

float t_min = min(t_x, t_y);
t_min = min(t_min, t_z);


float dt = t_min  / float(n_steps);

vec3 step = viewDir * dt;
vec3 pos = vertex;

float density1 = 0.0;
float density2 = 0.0;



for (int i = 0; i < n_steps; i++)
	{
	pos = pos + step;
	density1 += spherical_smoothstep(pos) * dt;
	density2 += thrust_flame(pos) * dt;
	}




float density = density1 + density2;
//density = clamp(density,0.0,1.0);
density = 1.0 - exp(-density);

density1 = 1.0 - exp(-density1);
density2 = 1.0 - exp(-density2);


vec3 flame_color_low = vec3 (flame_color_low_r, flame_color_low_g, flame_color_low_b);
vec3 flame_color_high = vec3 (flame_color_high_r, flame_color_high_g, flame_color_high_b);

vec3 color = mix(flame_color_low, flame_color_high, density2);
color = mix(color, vec3(0.8, 1.0, 1.0), density1);

vec4 finalColor = vec4 (color.rgb, density);

gl_FragColor = finalColor;
}
