#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform float fraction;
uniform sampler2D texture;

varying float Z_interpole;
varying vec4 vertTexCoord;


void main() {
  // Regle de trois par rapport a l'enonce : (z mod 100) 
  float remainer = mod(Z_interpole, 1.0);
  
  // Rivière qui coule d'un lac (avec dégradé)
  if (Z_interpole <= -201) {
    gl_FragColor = vec4(0.0, 0.2, 1.0, 1.0) * texture2D(texture, vertTexCoord.st);
  } else if (Z_interpole <= -200) {
    gl_FragColor = vec4(0.0, 0.4, 1.0, 1.0) * texture2D(texture, vertTexCoord.st);
  
  // Végétation
  } else if (Z_interpole <= -198.5) {
    gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0) * texture2D(texture, vertTexCoord.st);

  // Couleur noire lorsque la division entiere est entre 0 et 0.2
  } else if (remainer <= 0.05) {
    gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  
  } else { 
    gl_FragColor = texture2D(texture, vertTexCoord.st) ;
  }
  
}