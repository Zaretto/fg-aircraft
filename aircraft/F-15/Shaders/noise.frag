// -*-C++-*-

// This is a library of noise functions, taking a coordinate vector and a wavelength
// as input and returning a number [0:1] as output.

// * Noise2D(in vec2 coord, in float wavelength) is 2d Perlin noise
// * Noise3D(in vec3 coord, in float wavelength) is 3d Perlin noise
// * DotNoise2D(in vec2 coord, in float wavelength, in float fractionalMaxDotSize, in float dDensity)
//   is sparse dot noise and takes a dot density parameter
// * DropletNoise2D(in vec2 coord, in float wavelength, in float fractionalMaxDotSize, in float dDensity)
//   is sparse dot noise modified to look like liquid and takes a dot density parameter
// * VoronoiNoise2D(in vec2 coord, in float wavelength, in float xrand, in float yrand)
//   is a function mapping the terrain into random domains, based on Voronoi tiling of a regular grid
//   distorted with xrand and yrand
// * SlopeLines2D(in vec2 coord, in vec2 gradDir, in float wavelength, in float steepness)
//   computes a semi-random set of lines along the direction of steepest descent, allowing to
//   simulate e.g. water erosion patterns
// * Strata3D(in vec3 coord, in float wavelength, in float variation)
//   computers a vertically stratified random pattern, appropriate e.g. for rock textures 

// Thorsten Renk 2014

#version 120


float rand2D(in vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rand3D(in vec3 co){
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233,144.7272))) * 43758.5453);
}

float cosine_interpolate(in float a, in float b, in float x)
{
	float ft = x * 3.1415927;
	float f = (1.0 - cos(ft)) * .5;

	return  a*(1.0-f) + b*f;
}

float simple_interpolate(in float a, in float b, in float x)
{
return a + smoothstep(0.0,1.0,x) * (b-a);
}

float interpolatedNoise2D(in float x, in float y)
{
      float integer_x    = x - fract(x);
      float fractional_x = x - integer_x;

      float integer_y    = y - fract(y);
      float fractional_y = y - integer_y;

      float v1 = rand2D(vec2(integer_x, integer_y));
      float v2 = rand2D(vec2(integer_x+1.0, integer_y));
      float v3 = rand2D(vec2(integer_x, integer_y+1.0));
      float v4 = rand2D(vec2(integer_x+1.0, integer_y +1.0));

      float i1 = simple_interpolate(v1 , v2 , fractional_x);
      float i2 = simple_interpolate(v3 , v4 , fractional_x);

      return simple_interpolate(i1 , i2 , fractional_y);
}

float interpolatedNoise3D(in float x, in float y, in float z)
{
      float integer_x    = x - fract(x);
      float fractional_x = x - integer_x;

      float integer_y    = y - fract(y);
      float fractional_y = y - integer_y;

      float integer_z    = z - fract(z);
      float fractional_z = z - integer_z;

      float v1 = rand3D(vec3(integer_x, integer_y, integer_z));
      float v2 = rand3D(vec3(integer_x+1.0, integer_y, integer_z));
      float v3 = rand3D(vec3(integer_x, integer_y+1.0, integer_z));
      float v4 = rand3D(vec3(integer_x+1.0, integer_y +1.0, integer_z));

      float v5 = rand3D(vec3(integer_x, integer_y, integer_z+1.0));
      float v6 = rand3D(vec3(integer_x+1.0, integer_y, integer_z+1.0));
      float v7 = rand3D(vec3(integer_x, integer_y+1.0, integer_z+1.0));
      float v8 = rand3D(vec3(integer_x+1.0, integer_y +1.0, integer_z+1.0));


      float i1 = simple_interpolate(v1,v5, fractional_z);
      float i2 = simple_interpolate(v2,v6, fractional_z);
      float i3 = simple_interpolate(v3,v7, fractional_z);
      float i4 = simple_interpolate(v4,v8, fractional_z);

      float ii1 = simple_interpolate(i1,i2,fractional_x);
      float ii2 = simple_interpolate(i3,i4,fractional_x);
 

      return simple_interpolate(ii1 , ii2 , fractional_y);
}


float Noise2D(in vec2 coord, in float wavelength)
{
return interpolatedNoise2D(coord.x/wavelength, coord.y/wavelength);

}

float Noise3D(in vec3 coord, in float wavelength)
{
return interpolatedNoise3D(coord.x/wavelength, coord.y/wavelength, coord.z/wavelength);
}

float dotNoise2D(in float x, in float y, in float fractionalMaxDotSize, in float dDensity)
{
	float integer_x    = x - fract(x);
    float fractional_x = x - integer_x;

    float integer_y    = y - fract(y);
    float fractional_y = y - integer_y;

	if (rand2D(vec2(integer_x+1.0, integer_y +1.0)) > dDensity)
		{return 0.0;}

    float xoffset = (rand2D(vec2(integer_x, integer_y)) -0.5);
    float yoffset = (rand2D(vec2(integer_x+1.0, integer_y)) - 0.5);
    float dotSize = 0.5 * fractionalMaxDotSize * max(0.25,rand2D(vec2(integer_x, integer_y+1.0)));

	
	vec2 truePos = vec2 (0.5 + xoffset * (1.0 - 2.0 * dotSize) , 0.5 + yoffset * (1.0 -2.0 * dotSize));

	float distance = length(truePos - vec2(fractional_x, fractional_y));
	
	return 1.0 - smoothstep (0.3 * dotSize, 1.0* dotSize, distance);
}

float DotNoise2D(in vec2 coord, in float wavelength, in float fractionalMaxDotSize, in float dDensity)
{
return dotNoise2D(coord.x/wavelength, coord.y/wavelength, fractionalMaxDotSize, dDensity);
}

float dropletNoise2D(in float x, in float y, in float fractionalMaxDotSize, in float dDensity)
{
    float integer_x    = x - fract(x);
    float fractional_x = x - integer_x;

    float integer_y    = y - fract(y);
    float fractional_y = y - integer_y;

	if (rand2D(vec2(integer_x+1.0, integer_y +1.0)) > dDensity)
		{return 0.0;}

    float xoffset = (rand2D(vec2(integer_x, integer_y)) -0.5);
    float yoffset = (rand2D(vec2(integer_x+1.0, integer_y)) - 0.5);
    float dotSize = 0.5 * fractionalMaxDotSize * max(0.25,rand2D(vec2(integer_x, integer_y+1.0)));

    float x1offset = 2.0 * (rand2D(vec2(integer_x+5.0, integer_y)) -0.5);
    float y1offset = 2.0 * (rand2D(vec2(integer_x, integer_y + 5.0)) - 0.5);
    float x2offset = 2.0 * (rand2D(vec2(integer_x-5.0, integer_y)) -0.5);
    float y2offset = 2.0 * (rand2D(vec2(integer_x-5.0, integer_y -5.0)) - 0.5);
    float smear = (rand2D(vec2(integer_x + 3.0, integer_y)) -0.5);

	
	vec2 truePos = vec2 (0.5 + xoffset * (1.0 - 4.0 * dotSize) , 0.5 + yoffset * (1.0 -4.0 * dotSize));
	vec2 secondPos = truePos + vec2 (dotSize * x1offset, dotSize * y1offset);
	vec2 thirdPos = truePos + vec2 (dotSize * x2offset, dotSize * y2offset);

	float distance = length(truePos - vec2(fractional_x, fractional_y));
	float dist1 = length(secondPos - vec2(fractional_x, fractional_y));
	float dist2 = length(thirdPos - vec2(fractional_x, fractional_y));	

	return clamp(3.0 - smoothstep (0.3 * dotSize, 1.0* dotSize, distance) - smoothstep (0.3 * dotSize, 1.0* dotSize, dist1) - smoothstep ((0.1 + 0.5 * smear) * dotSize, 1.0* dotSize, dist2), 0.0,1.0);
}

float DropletNoise2D(in vec2 coord, in float wavelength, in float fractionalMaxDotSize, in float dDensity)
{
return dropletNoise2D(coord.x/wavelength, coord.y/wavelength, fractionalMaxDotSize, dDensity);
}

float voronoiNoise2D(in float x, in float y, in float xrand, in float yrand)
{
	float integer_x    = x - fract(x);
    float fractional_x = x - integer_x;

    float integer_y    = y - fract(y);
    float fractional_y = y - integer_y;

	float val[4];
	
	val[0] = rand2D(vec2(integer_x, integer_y));
	val[1] = rand2D(vec2(integer_x+1.0, integer_y));
	val[2] = rand2D(vec2(integer_x, integer_y+1.0));
	val[3] = rand2D(vec2(integer_x+1.0, integer_y+1.0));

	float xshift[4];
	
	xshift[0] = xrand * (rand2D(vec2(integer_x+0.5, integer_y)) - 0.5);
	xshift[1] = xrand * (rand2D(vec2(integer_x+1.5, integer_y)) -0.5);
	xshift[2] = xrand * (rand2D(vec2(integer_x+0.5, integer_y+1.0))-0.5);
	xshift[3] = xrand * (rand2D(vec2(integer_x+1.5, integer_y+1.0))-0.5);

	float yshift[4];
	
	yshift[0] = yrand * (rand2D(vec2(integer_x, integer_y +0.5)) - 0.5);
	yshift[1] = yrand * (rand2D(vec2(integer_x+1.0, integer_y+0.5)) -0.5);
	yshift[2] = yrand * (rand2D(vec2(integer_x, integer_y+1.5))-0.5);
	yshift[3] = yrand * (rand2D(vec2(integer_x+1.5, integer_y+1.5))-0.5);
	
	
	float dist[4];
	
	dist[0] = sqrt((fractional_x + xshift[0]) * (fractional_x + xshift[0]) + (fractional_y + yshift[0]) * (fractional_y + yshift[0]));
	dist[1] = sqrt((1.0 -fractional_x + xshift[1]) * (1.0-fractional_x+xshift[1]) + (fractional_y +yshift[1]) * (fractional_y+yshift[1]));
	dist[2] = sqrt((fractional_x + xshift[2]) * (fractional_x + xshift[2]) + (1.0-fractional_y +yshift[2]) * (1.0-fractional_y + yshift[2]));
	dist[3] = sqrt((1.0-fractional_x + xshift[3]) * (1.0-fractional_x + xshift[3]) + (1.0-fractional_y +yshift[3]) * (1.0-fractional_y + yshift[3]));
	


	int i, i_min;
	float dist_min = 100.0;
	for (i=0; i<4;i++)
		{
		if (dist[i] < dist_min)
			{
			dist_min = dist[i];
			i_min = i;
			}
		}
	
	return val[i_min];
	//return val[0];
	
}

float VoronoiNoise2D(in vec2 coord, in float wavelength, in float xrand, in float yrand)	
{
return voronoiNoise2D(coord.x/wavelength, coord.y/wavelength, xrand, yrand);
}

float slopeLines2D(in float x, in float y, in float sx, in float sy, in float steepness)
{
	float integer_x    = x - fract(x);
    float fractional_x = x - integer_x;

    float integer_y    = y - fract(y);
    float fractional_y = y - integer_y;

	vec2 O = vec2 (0.2 + 0.6* rand2D(vec2 (integer_x, integer_y+1)), 0.3 + 0.4* rand2D(vec2 (integer_x+1, integer_y)));
	vec2 S = vec2 (sx, sy);
	vec2 P = vec2 (-sy, sx);
	vec2 X = vec2 (fractional_x, fractional_y);
	
	float radius = 0.0 + 0.3  * rand2D(vec2 (integer_x, integer_y));
	
	float b = (X.y - O.y + O.x * S.y/S.x - X.x * S.y/S.x) / (P.y - P.x * S.y/S.x);
	float a = (X.x - O.x - b*P.x)/S.x;
	
	return (1.0 - smoothstep(0.7 * (1.0-steepness), 1.2* (1.0 - steepness), 0.6* abs(a))) * (1.0 - smoothstep(0.0, 1.0 * radius,abs(b)));
	
	
}


float SlopeLines2D(in vec2 coord, in vec2 gradDir, in float wavelength, in float steepness)
{
return slopeLines2D(coord.x/wavelength, coord.y/wavelength, gradDir.x, gradDir.y, steepness);
}


float strata3D(in float x, in float y, in float z, in float variation)
{
	float integer_x    = x - fract(x);
    	float fractional_x = x - integer_x;

    	float integer_y    = y - fract(y);
    	float fractional_y = y - integer_y;
	
	float integer_z = z - fract(z);
	float fractional_z = z - integer_z;
	
	float rand_value_low = rand3D(vec3(0.0, 0.0, integer_z));
	float rand_value_high = rand3D(vec3(0.0, 0.0, integer_z+1));
	
	float rand_var = 0.5 - variation + 2.0 * variation * rand3D(vec3(integer_x, integer_y, integer_z));
	
	
	return (1.0 - smoothstep(rand_var -0.15, rand_var + 0.15,  fract(z))) * rand_value_low +  smoothstep(rand_var-0.15, rand_var + 0.15, fract(z)) * rand_value_high;
	
}	


float Strata3D(in vec3 coord, in float wavelength, in float variation)
{
return strata3D(coord.x/wavelength, coord.y/wavelength, coord.z/wavelength, variation);
}
