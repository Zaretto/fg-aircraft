// -*-C++-*-

#version 120

varying vec3 vertex;
varying vec3 viewDir;

void main()
{

vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);

vertex = gl_Vertex.xyz;
viewDir = normalize(vertex - ep.xyz);

gl_Position = ftransform();
gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;

gl_FrontColor = vec4 (1.0,1.0,1.0,1.0);
gl_BackColor = gl_FrontColor;
}
