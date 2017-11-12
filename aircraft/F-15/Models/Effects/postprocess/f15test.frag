#version 120

// uniform sampler2D current_scene_tex;

// void main()
// {
//   vec4 color;
//   vec2 coords = gl_TexCoord[0].xy;
//     color = texture2D(current_scene_tex, coords*5);
//     color.a = 1.0;
//     color.g = 1.0;
//     gl_FragColor = color;
//     gl_FragColor = gl_Color * texture2D(currentTexture, distortedTextureCoordinate);
// }

uniform sampler2D currentScene_tex; // Our render texture
uniform sampler2D distortionMapTexture; // Our heat distortion map texture

uniform int  TIME_FROM_INIT; // Time used to scroll the distortion map
uniform float distortionFactor; // Factor used to control severity of the effect
uniform float riseFactor; // Factor used to control how fast air rises
const float f[5] = float[](0.0, 1.0, 2.0, 3.0, 4.0);
const float w[5] = float[](0.2270270270, 0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162 );

void main()			
{
    gl_FragColor = vec4(0.0,0.0,0.0,1.0);//color ;
return;
vec2 distortionMapCoordinate = gl_TexCoord[0].st;
    vec4 color = texture2D( currentScene_tex, distortionMapCoordinate  );

    // We use the time value to scroll our distortion texture upwards
    // Since we enabled texture repeating, OpenGL takes care of
    // coordinates that lie outside of [0, 1] by discarding
    // the integer part and keeping the fractional part
    // Basically performing a "floating point modulo 1"
    // 1.1 = 0.1, 2.4 = 0.4, 10.3 = 0.3 etc.
    
    //distortionMapCoordinate.t -= (TIME_FROM_INIT/60) * riseFactor;
    //distortionMapCoordinate.t -= (TIME_FROM_INIT/60) * riseFactor;

    vec4 distortionMapValue = texture2D(distortionMapTexture, distortionMapCoordinate);

    // The values are normalized by OpenGL to lie in the range [0, 1]
    // We want negative offsets too, so we subtract 0.5 and multiply by 2
    // We end up with values in the range [-1, 1]
    vec2 distortionPositionOffset = distortionMapValue.xy;
    distortionPositionOffset -= vec2(0.5f, 0.5f);
    distortionPositionOffset *= 2.f;

    // The factor scales the offset and thus controls the severity
    distortionPositionOffset *= distortionFactor;

    // The latter 2 channels of the texture are unused... be creative
    vec2 distortionUnused = distortionMapValue.zw;

    // Since we all know that hot air rises and cools,
    // the effect loses its severity the higher up we get
    // We use the t (a.k.a. y) texture coordinate of the original texture
    // to tell us how "high up" we are and damp accordingly
    // Remember, OpenGL 0 is at the bottom
    distortionPositionOffset *= (1.f - gl_TexCoord[0].t);
vec2 fg_BufferSize = vec2(300,300);
    vec2 distortedTextureCoordinate = gl_TexCoord[0].st + distortionPositionOffset;
//	color = color * texture2D(currentScene_tex, distortedTextureCoordinate);
  	vec2 blurOffset = vec2(4,0)/fg_BufferSize ;
    vec2 coords = distortedTextureCoordinate;
    color = vec4( texture2D( currentScene_tex, coords + f[0] * blurOffset ).rgb * w[0], 1.0 );
    for (int i=1; i<5; ++i ) {
        color.rgb += texture2D( currentScene_tex, coords - f[i] * blurOffset ).rgb * w[i];
        color.rgb += texture2D( currentScene_tex, coords + f[i] * blurOffset ).rgb * w[i];
    }
    gl_FragColor = color ;

}

