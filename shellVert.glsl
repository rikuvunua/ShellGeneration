#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

attribute vec4 position;
attribute vec3 normal;

uniform mat4 transform;
uniform mat4 modelview;
uniform mat3 normalMatrix;

varying vec3 vNormal;
varying vec3 vViewDir;

void main() {
  vec4 mvPosition = modelview * position;
  vNormal = normalize(normalMatrix * normal);
  vViewDir = normalize(-mvPosition.xyz);
  gl_Position = transform * position;
}
