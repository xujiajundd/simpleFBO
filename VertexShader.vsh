attribute vec4 position;
attribute vec2 texCoord;
varying vec2 vTexCoord;
uniform mat4 modelViewProjectionMatrix;

void main()
{
    gl_Position = modelViewProjectionMatrix * position;
    vTexCoord = texCoord.xy;
}
