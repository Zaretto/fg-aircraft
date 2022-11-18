//
// GLSL fragment shader that I bashed together from examples on shadertoy in an attempt to simulate a CRT display.
// see https://www.youtube.com/watch?v=D5u40s2opgk
// (C) Richard Harrison; December 2017, released under GPLV2 or later.

uniform sampler2D TextureUnit0;
uniform int TIME_FROM_INIT ;
uniform int DELTA_FRAME_TIME ;
float time;

float getCenterDistance(vec2 coord)
{
    return distance(coord, vec2(0.5)) * 2.0; //return difference between point on screen and the center with -1 and 1 at either edge
}

vec4 applyScanLines(vec4 color, vec2 coord, float number, float amount, float power, float drift)
{
    coord.y += time * drift; //animate scrolling coordinates (great for shifting moire effects with high number of lines)
    coord.y +=  cos(coord.y * time );
    float darkenAmount = 0.5+ 0.5 * sin(coord.y * 6.28 *number); //get darken amount as cos wave between 0 and 1, over number of lines across height
    darkenAmount = pow(darkenAmount, power); //bias darkenAmount towards wider light areas
        
    color.rgb -= darkenAmount * amount; //darken rgb colors by given gap darkness amount
        
    return color;
}


float onOff(float a, float b, float c)
{
	return smoothstep(c,c*0.77, sin(time + a*cos(time*b)));
}

float mono(vec4 color)
{
    return max(color.r, max(color.g, color.b));
    return (0.2125 * color.r) + (0.7154 * color.g) + (0.0721 * color.b);
}

//int line = 0;
vec2 bulgeCoords(vec2 coord, vec2 sourceCoord, float bulgeAmount)
{
    float centerDist = getCenterDistance(sourceCoord);
    
    coord.xy -= vec2(0.5); //reposition so scaling performed from center of image
    
    coord.xy *= 1.0 + centerDist * bulgeAmount; //scale up coordinates the further from center they are
    coord.xy *= 1.0 - bulgeAmount; //scale down oversampling to reduce tiling
    
    coord.xy += vec2(0.5); //restore position to center of view
    float f = min(10., time);
    coord.xy = coord.xy/10. *f;
    //coord.x += mod(time,10)/10.0;
    //slanted sync problem coord.x += sin(fract(time)*.1)+(coord.y/10.0);
    // rounded sin(fract(time)*.1)+tan(coord.y);
//    if (line < 10)
//    coord.x += line/10.;//
//    if (line ++ > 20) 
//    line = 0;
    return coord;
}

//applyScanLines(outputColor, scanLineCoord, 150.0, 0.25, 2.0, 0.01); //apply scan lines (with bulged coords)

vec3 getColor(vec2 p){
  
    float bar = mod(p.y + time*20., 1.) < 0.1 ?  1.2  : 1.;
    float middle = mono(texture2D(TextureUnit0, p));
    float off = 0.002;
    float sum = 0.;
   
       for (float i = -1.; i < 2.; i+=1.){
       {
            sum += mono(texture2D(TextureUnit0, (p+vec2(off*i, off*i*0.5))));
        }
    }

    return vec3(0.9)*middle + sum/10.*vec3(0.,1.,0.) * bar;
}

vec4 sampleRGBVignette(sampler2D source, vec2 coord, vec2 sourceCoord, float amount, float power)
{
    float centerDist = getCenterDistance(sourceCoord);
    centerDist = pow(centerDist, power); //bias distance from center to ramp up steeper towards edges
    
    vec2 sampleCoord = coord;
    vec4 outputColor = texture2D(source, fract(sampleCoord)); //get default sample image (for R)
    vec4 tColor=vec4(getColor(sampleCoord),1.0);
    outputColor = tColor;
    sampleCoord = bulgeCoords(coord, sourceCoord, amount * centerDist); //bulge sample coordinates by amount, multiply by center distance to reduce effect in center
    outputColor.g =tColor.g; //sample Green amount by G color abberation
    
    sampleCoord = bulgeCoords(coord, sourceCoord, amount * 2.0 * centerDist); //bulge sample coordinates by double amount for Blue (twice as far from R as G)
    outputColor.b =tColor.b; //sample Blue amount by B color abberation
    
    return outputColor;
}

vec4 applyVignette(vec4 color, vec2 sourceCoord, float amount, float scale, float power)
{
    float centerDist = getCenterDistance(sourceCoord);
    float darkenAmount = centerDist / scale; //get amount to darken current fragment by scaled distance from center
    darkenAmount = pow(darkenAmount, power); //bias darkenAmount towards edges of distance
    darkenAmount = min(1.0, darkenAmount); //clamp maximum darkenAmount to 1 so amount param can lighten outer regions of vignette 
    color.rgb -= darkenAmount * amount; //darken rgb colors by given vignette amount
    return color;
}


void main() {
    // time = iTime / 3.;
    for (int tt= 0; tt < 1; tt+=1)
    {
        time = DELTA_FRAME_TIME / 1000.0 + TIME_FROM_INIT / 2000.0;
        vec2 p = gl_TexCoord[0];//gl_FragCoord / resolution;
        float off = 0.0001;
        vec3 col = getColor(p);
        //        gl_FragColor = texture2D(TextureUnit0, gl_TexCoord[0]);
        //        return;
        vec2 sampleCoord = p;
        vec2 sourceCoord = p;
        //    sampleCoord = bulgeCoords(sampleCoord, sourceCoord, 0.1); //apply bulge effect to sample coords
    
        //vec4 outputColor = texture(iChannel0, fract(sampleCoord)); //to sample without RGB color abberation
    
        vec4 outputColor = sampleRGBVignette(TextureUnit0, sampleCoord, sourceCoord, 0.1, 2.0); //sample bulged coords with color abberation
        //vec4 outputColor = texture(TextureUnit0, sampleCoord);    
        float vignetteAmount = 1.2 + 0.15 * sin(time * 50.0); //set a fluctuating vignette intensity
        outputColor = applyVignette(outputColor, sourceCoord, vignetteAmount, 2.0, 2.5); //apply vignette to sampled color
    
        vec2 scanLineCoord = bulgeCoords(sourceCoord, sourceCoord, 0.2);  //get bulged coords to bulge scan lines
        outputColor = applyScanLines(outputColor, scanLineCoord, 150.0, 0.25, 2.0, 0.01); //apply scan lines (with bulged coords)


        //   col = col * mod(gl_TexCoord[0].y,2);
        gl_FragColor = vec4(0.,mono(outputColor),0.,1);
        //    gl_FragColor = vec4(1.,0.,0.,1);
    }
}
