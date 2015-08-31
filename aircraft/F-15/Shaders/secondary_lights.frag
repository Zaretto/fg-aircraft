// -*-C++-*-

uniform int display_xsize;
uniform int display_ysize;
uniform float field_of_view;
uniform float view_pitch_offset;
uniform float view_heading_offset;

float light_distance_fading(in float dist)
{
return min(1.0, 10000.0/(dist*dist));
}

float fog_backscatter(in float avisibility)
{
return 0.5* min(1.0,10000.0/(avisibility*avisibility));
}



vec3 searchlight()
{

vec2 center = vec2 (float(display_xsize) * 0.5, float(display_ysize) * 0.4);

float headlightIntensity;  
float lightRadius = (float(display_xsize) *9.16 /field_of_view);
float angularDist = length(gl_FragCoord.xy -center);

if (angularDist < lightRadius)
	{
	headlightIntensity = pow(cos(angularDist/lightRadius * 1.57075),2.0);
	//headlightIntensity = headlightIntensity * 
	//headlightIntensity*= clamp(1.0 + 0.15 * log(1000.0/(dist*dist)),0.0,1.0);
	return  headlightIntensity * vec3 (0.5,0.5, 0.5);
	}
else return vec3 (0.0,0.0,0.0);
}

vec3 flashlight(in vec3 color, in float radius)
{

vec2 center = vec2 (float(display_xsize) * 0.5, float(display_ysize) * 0.4);

float headlightIntensity;
float lightRadius = (float(display_xsize) *radius /field_of_view);
float angularDist = length(gl_FragCoord.xy -center);

if (angularDist < lightRadius)
 	{
 	headlightIntensity = pow(cos(angularDist/lightRadius * 1.57075),2.0);
 	return headlightIntensity * color;
 	}
else return vec3 (0.0,0.0,0.0);
}


vec3 landing_light(in float offset)
{

float fov_h = field_of_view;
float fov_v = float(display_ysize)/float(display_xsize) * field_of_view; 

float yaw_offset;

if (view_heading_offset > 180.0)
	{yaw_offset = -360.0+view_heading_offset;}
else 
	{yaw_offset = view_heading_offset;}

float x_offset = (float(display_xsize) / fov_h * (yaw_offset + offset));
float y_offset = -(float(display_ysize) / fov_v * view_pitch_offset);

vec2 center = vec2 (float(display_xsize) * 0.5 + x_offset, float(display_ysize) * 0.4 + y_offset);



float landingLightIntensity;  
float lightRadius = (float(display_xsize) *9.16 /field_of_view);
float angularDist = length(gl_FragCoord.xy -center);

if (angularDist < lightRadius)
	{
	landingLightIntensity = pow(cos(angularDist/lightRadius * 1.57075),2.0);
	//landingLightIntensity *= min(1.0, 10000.0/(dist*dist));
	return  landingLightIntensity * vec3 (0.5,0.5, 0.5);
	}
else return vec3 (0.0,0.0,0.0);

}
