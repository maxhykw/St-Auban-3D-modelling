uniform mat4 transformMatrix;
uniform mat3 normalMatrix;
uniform vec3 lightNormal;
uniform mat4 texMatrix;

uniform float deform;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;
attribute vec2 texCoord;

varying float sh;
varying float Z_interpole;

varying vec4 vertTexCoord;


varying vec4 vertColor;
varying vec3 vertNormal;
varying vec3 vertLightDir;

void main() {
  gl_Position = transformMatrix * position;
  
  vertTexCoord = texMatrix * vec4(texCoord, 1.0, 1.0);

  Z_interpole = position.z;
}
