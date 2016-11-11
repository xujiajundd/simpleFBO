precision mediump float;

uniform sampler2D  uSampler;
varying vec2       vTexCoord;

void main()
{
    vec4 texCol = texture2D(uSampler, vTexCoord);
    gl_FragColor = vec4(texCol.rgb, 1.0);
}
