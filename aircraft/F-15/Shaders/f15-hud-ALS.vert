// -*-C++-*-
#version 120

varying vec2 rawPos;
varying vec2 nPos;
varying vec3 vertPos;
varying vec3 normal;
varying vec3 light_diffuse;
varying vec3 refl_vec;
varying float splash_angle;
varying float Mie;
varying float ambient_fraction;

uniform float ground_scattering;
uniform float hazeLayerAltitude;
uniform float moonlight;
uniform float terminator;
uniform float splash_x;
uniform float splash_y;
uniform float splash_z;

const float EarthRadius = 5800000.0;
const float terminator_width = 200000.0;

float light_func (in float x, in float a, in float b, in float c, in float d, in float e)
{
//x = x - 0.5;

// use the asymptotics to shorten computations
if (x < -15.0) {return 0.0;}

return e / pow((1.0 + a * exp(-b * (x-c)) ),(1.0/d));
}


void main()
{

vec3 shadedFogColor = vec3(0.55, 0.67, 0.88);
vec3 moonLightColor = vec3 (0.095, 0.095, 0.15) * moonlight;

// geometry for lighting
vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
vec3 relPos = gl_Vertex.xyz - ep.xyz;
vec3 lightFull = (gl_ModelViewMatrixInverse * gl_LightSource[0].position).xyz;
vec3 lightHorizon = normalize(vec3(lightFull.x,lightFull.y, 0.0));
float dist = length(relPos);
float vertex_alt = max(gl_Vertex.z,100.0);
float scattering = ground_scattering + (1.0 - ground_scattering) * smoothstep(hazeLayerAltitude -100.0, hazeLayerAltitude + 100.0, vertex_alt); 
float yprime_alt = - sqrt(2.0 * EarthRadius * vertex_alt);
float earthShade = 0.6 * (1.0 - smoothstep(-terminator_width+ terminator, terminator_width + terminator, yprime_alt)) + 0.4;
float lightArg = (terminator-yprime_alt)/100000.0;

// light computation

vec3 light_ambient;

light_diffuse.b = light_func(lightArg, 1.330e-05, 0.264, 3.827, 1.08e-05, 1.0);
light_diffuse.g = light_func(lightArg, 3.931e-06, 0.264, 3.827, 7.93e-06, 1.0);
light_diffuse.r = light_func(lightArg, 8.305e-06, 0.161, 3.827, 3.04e-05, 1.0);
light_diffuse = light_diffuse * scattering;


light_ambient.r = light_func(lightArg, 0.236, 0.253, 1.073, 0.572, 0.33);
light_ambient.g = light_ambient.r * 0.4/0.33; 
light_ambient.b = light_ambient.r * 0.5/0.33; 

float intensity;

if (earthShade < 0.5)
	{
	intensity = length(light_ambient.xyz); 

	light_ambient.rgb = intensity * normalize(mix(light_ambient.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.8,earthShade) ));
	light_ambient.rgb = light_ambient.rgb +   moonLightColor *  (1.0 - smoothstep(0.4, 0.5, earthShade));

	intensity = length(light_diffuse.xyz); 
	light_diffuse.rgb = intensity * normalize(mix(light_diffuse.rgb,  shadedFogColor, 1.0 -smoothstep(0.4, 0.7,earthShade) ));
	}


float MieFactor =   dot(normalize(lightFull), normalize(relPos));
Mie =  smoothstep(0.9,1.0, MieFactor) * earthShade * earthShade * scattering;


// get a reflection vector for cube map

vec4 ecPosition = gl_ModelViewMatrix * gl_Vertex;
normal = -normalize(gl_NormalMatrix * gl_Normal);
vec4 reflect_eye = vec4(reflect(ecPosition.xyz, normal), 0.0);
vec3 reflVec_stat = normalize(gl_ModelViewMatrixInverse * reflect_eye).xyz;
refl_vec = reflVec_stat;

// get a projection plane orthogonal to the splash vector

vec3 splash_vec = vec3 (splash_x, splash_y, splash_z);
vec3 corrected_splash = normalize(splash_vec);

float angle = abs(dot(corrected_splash, gl_Normal));


//corrected_splash = normalize(corrected_splash + 0.4* gl_Normal );
	

vec3 base_1 = vec3 (-corrected_splash.y, corrected_splash.x, 0.0);
vec3 base_2 = cross (corrected_splash, base_1);

base_1 = normalize(base_1);
base_2 = normalize(base_2);

rawPos = vec2 (dot(gl_Vertex.xyz, base_1), dot(gl_Vertex.xyz, base_2));

base_1 = vec3 (-gl_Normal.y, gl_Normal.x, 0.0);
base_2 = cross(gl_Normal, base_1);

base_1 = normalize(base_1);
base_2 = normalize(base_2);

nPos = vec2 (dot(gl_Vertex.xyz, base_1), dot(gl_Vertex.xyz, base_2));

vertPos = gl_Vertex.xyz;

splash_angle = dot(gl_Normal, corrected_splash);

ambient_fraction = length(light_ambient.rgb)/(length(light_diffuse.rgb +light_ambient.rgb ) + 0.01);


gl_Position = ftransform();
gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;

vec4 diffuse_color = gl_FrontMaterial.diffuse;
vec4 ambient_color = gl_FrontMaterial.ambient;

vec4 constant_term = gl_FrontMaterial.emission + ambient_color * vec4 (light_diffuse.rgb + light_ambient.rgb,1.0);
constant_term.a = min(diffuse_color.a, ambient_color.a);

gl_FrontColor = constant_term;
gl_BackColor = gl_FrontColor;

}
