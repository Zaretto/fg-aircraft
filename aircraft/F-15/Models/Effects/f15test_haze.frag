#version 120

uniform sampler2D currentScene_tex; // Our render texture
uniform sampler2D distortionMapTexture; // Our heat distortion map texture

uniform int  TIME_FROM_INIT; // Time used to scroll the distortion map
uniform float distortionFactor; // Factor used to control severity of the effect
uniform float riseFactor; // Factor used to control how fast air rises
const float f[5] = float[](0.0, 1.0, 2.0, 3.0, 4.0);
const float w[5] = float[](0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 );

void main()			
{
    vec2 distortionMapCoordinate = gl_TexCoord[0].xy;

    gl_FragColor = vec4(0.5,0.5,0.5,0.5,0.5);//color ;
return;
    vec4 color = texture2D( currentScene_tex, distortionMapCoordinate  );
//    vec4 color = texture2D( distortionMapTexture, distortionMapCoordinate  );

//    gl_FragColor = vec4(distortionMapCoordinate.x/1000,distortionMapCoordinate.y/1000,0.5,1.0);//color ;
    gl_FragColor = color;
}

