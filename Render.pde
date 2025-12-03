// 渲染辅助（法线/背景/着色器）
void emitVertexWithNormal(PVector position, PVector normalVector) {
  PVector n = (normalVector != null) ? normalVector : new PVector(0, 0, 1);
  if (n.magSq() < 1e-6f) {
    n = new PVector(0, 0, 1);
  }
  normal(n.x, n.y, n.z);
  vertex(position.x, position.y, position.z);
}

PVector computeSideNormal(int ringIndex, int vertexIndex) {
  int prevIndex = (vertexIndex - 1 + vertexCount) % vertexCount;
  int nextIndex = (vertexIndex + 1) % vertexCount;

  PVector thickness = PVector.sub(ringsOuter[ringIndex][vertexIndex], ringsInner[ringIndex][vertexIndex]);
  PVector ringDirection = PVector.sub(ringsOuter[ringIndex][nextIndex], ringsOuter[ringIndex][prevIndex]);
  PVector normalCandidate = thickness.cross(ringDirection);

  if (normalCandidate.magSq() < 1e-6f) {
    normalCandidate = outerNormals[ringIndex][vertexIndex].copy();
  }
  if (normalCandidate.magSq() < 1e-6f) {
    normalCandidate = new PVector(0, 0, 1);
  }

  normalCandidate.normalize();

  PVector outward = PVector.sub(ringsOuter[ringIndex][vertexIndex], CV[ringIndex]);
  if (normalCandidate.dot(outward) < 0) {
    normalCandidate.mult(-1);
  }

  return normalCandidate;
}

PVector computeCapNormal(int ringIndex, boolean isFront) {
  if (numberOfStepGrowth < 1) {
    return new PVector(0, 0, isFront ? -1 : 1);
  }

  int clampedIndex = constrain(ringIndex, 0, numberOfStepGrowth - 1);
  PVector base = (normGV[clampedIndex] != null) ? normGV[clampedIndex].copy() : new PVector(0, 0, 1);
  if (base.magSq() < 1e-6f) {
    base.set(0, 0, 1);
  }
  base.normalize();
  if (isFront) {
    base.mult(-1);
  }

  // 确保法线朝向外部
  PVector sample = outerNormals[clampedIndex][0];
  if (sample != null && base.dot(sample) < 0) {
    base.mult(-1);
  }

  return base;
}

void drawBackgroundGradient() {
  if (backgroundGradient == null || backgroundGradient.width != width || backgroundGradient.height != height || gradientNeedsUpdate) {
    generateBackgroundGradient();
  }

  if (backgroundGradient != null) {
    background(backgroundGradient);
  } else {
    background(0);
  }
}

void generateBackgroundGradient() {
  if (width <= 0 || height <= 0) {
    return;
  }

  if (backgroundGradient == null || backgroundGradient.width != width || backgroundGradient.height != height) {
    backgroundGradient = createImage(width, height, RGB);
  }

  backgroundGradient.loadPixels();

  float centerX = width * 0.5f;
  float centerY = 0;
  float maxDist = dist(0, height, centerX, centerY);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float d = dist(x, y, centerX, centerY);
      float vertical = (float) y / max(height - 1, 1);
      float t = constrain((d / maxDist) * 0.75f + vertical * 0.25f, 0, 1);
      int c = lerpColor(backgroundTopColor, backgroundBottomColor, t);
      backgroundGradient.pixels[y * width + x] = c;
    }
  }

  backgroundGradient.updatePixels();
  gradientNeedsUpdate = false;
}

void configureShellShader() {
  if (shellShader == null) {
    return;
  }

  PVector keyLightDir = new PVector(-0.35f, -0.45f, 0.82f);
  keyLightDir.normalize();
  shellShader.set("uLightDir", keyLightDir.x, keyLightDir.y, keyLightDir.z);

  PVector fillLightDir = new PVector(0.55f, -0.2f, 0.35f);
  fillLightDir.normalize();
  shellShader.set("uFillDir", fillLightDir.x, fillLightDir.y, fillLightDir.z);

  shellShader.set("uBaseColor", 248f / 255f, 246f / 255f, 242f / 255f);
  shellShader.set("uAmbientColor", 214f / 255f, 208f / 255f, 198f / 255f);
  shellShader.set("uLightColor", 255f / 255f, 221f / 255f, 206f / 255f);
  shellShader.set("uFillColor", 205f / 255f, 215f / 255f, 240f / 255f);
  shellShader.set("uSpecularStrength", 2.3f);
  shellShader.set("uShininess", 140.0f);
  shellShader.set("uRimColor", 255f / 255f, 204f / 255f, 170f / 255f);
  shellShader.set("uRimStrength", 0.82f);
  shellShader.set("uRimExponent", 1.8f);
  shellShader.set("uEnvTopColor", 245f / 255f, 250f / 255f, 255f / 255f);
  shellShader.set("uEnvBottomColor", 210f / 255f, 182f / 255f, 150f / 255f);
  shellShader.set("uInteriorFactor", 0.0f);
}
