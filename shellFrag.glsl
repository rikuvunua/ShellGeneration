#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

varying vec3 vNormal;
varying vec3 vViewDir;

uniform vec3 uBaseColor;
uniform vec3 uAmbientColor;
uniform vec3 uLightColor;
uniform vec3 uFillColor;
uniform vec3 uLightDir;
uniform vec3 uFillDir;
uniform vec3 uRimColor;
uniform vec3 uEnvTopColor;
uniform vec3 uEnvBottomColor;
uniform float uSpecularStrength;
uniform float uShininess;
uniform float uRimStrength;
uniform float uRimExponent;
uniform float uInteriorFactor;

vec3 toneMap(vec3 c) {
  return c / (c + vec3(1.0));
}

void main() {
  vec3 N = normalize(vNormal);
  vec3 V = normalize(vViewDir);
  vec3 L = normalize(uLightDir);
  vec3 F = normalize(uFillDir);

  float ndotl = max(dot(N, L), 0.0);
  float ndotf = max(dot(N, F), 0.0);

  float interior = clamp(uInteriorFactor, 0.0, 1.0);
  vec3 interiorWarm = mix(uBaseColor, vec3(0.93, 0.83, 0.70), interior);
  float diffuseScale = mix(1.0, 0.45, interior);
  float specScale = mix(1.0, 0.32, interior);
  float rimScale = mix(1.0, 0.28, interior);
  float ambientScale = mix(1.0, 0.6, interior);
  float envScale = mix(1.0, 0.45, interior);

  vec3 diffuse = interiorWarm * (uLightColor * ndotl + uFillColor * ndotf * 0.6) * diffuseScale;

  vec3 H = normalize(L + V);
  vec3 HF = normalize(F + V);
  float specKey = pow(max(dot(N, H), 0.0), uShininess);
  float specFill = pow(max(dot(N, HF), 0.0), uShininess * 0.6);
  vec3 specular = (uLightColor * specKey + uFillColor * specFill) * (uSpecularStrength * specScale);

  float fresnel = pow(1.0 - max(dot(N, V), 0.0), 3.0);
  float rimFactor = pow(1.0 - max(dot(N, V), 0.0), uRimExponent) * uRimStrength;
  vec3 rim = uRimColor * rimFactor * rimScale;

  float hemisphere = clamp(N.y * 0.5 + 0.5, 0.0, 1.0);
  vec3 envColor = mix(uEnvBottomColor, uEnvTopColor, hemisphere);
  vec3 env = envColor * fresnel * envScale;

  vec3 ambient = uAmbientColor * interiorWarm * ambientScale;

  vec3 finalColor = ambient + diffuse + specular + rim + env;
  finalColor = toneMap(finalColor);

  gl_FragColor = vec4(finalColor, 1.0);
}
