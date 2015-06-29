#version 120

uniform sampler2D current_scene_tex;

void main()			
{
    vec2 tex_coord = gl_TexCoord[0].xy;

    gl_FragColor = vec4(1.0,1.0,1.0,1.0,1.0);//color ;
//    gl_FragColor = vec4(0.5,0.5,0.5,0.5,0.5);//color ;
return;
    vec4 color = texture2D( current_scene_tex, tex_coord  );
    gl_FragColor = color;
}

