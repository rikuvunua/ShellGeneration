void resetVectors() {
  // 初始化方向向量
  normGV[0] = new PVector(0, 0, 1);
  normSV[0] = new PVector(0, 1, 0);

  // 应用生长率计算实际长度
  for (int i = 0; i < numberOfStepGrowth; i++) {
    GVLength[i] = initGVL * pow(growthRate, i);
    SVLength[i] = initSVL * pow(growthRate, i);
  }

  // 保持起始环为一个点（与原版保持一致，用于封闭壳体起点）
  if (GV[0] == null) GV[0] = new PVector();
  if (SV[0] == null) SV[0] = new PVector();
  if (CV[0] == null) CV[0] = new PVector();
  GV[0].set(0, 0, 0);
  SV[0].set(0, 0, 0);
  CV[0].set(0, 0, 0);
  
  for (int i = 1; i < numberOfStepGrowth; i++) {
    // 同时反向弯曲与扭转，让贝壳右旋且保持正向朝上
    float mutatedBendAngle = getBendAngleWithMutations(i);
    normGV[i] = rotation(normGV[i-1], normSV[i-1], -mutatedBendAngle);
    normGV[i].normalize();
    // 取负号让截面旋转方向变为右旋
    float mutatedTwistAngle = getTwistAngleWithMutations(i);
    normSV[i] = rotation(normSV[i-1], normGV[i], -mutatedTwistAngle);
    normSV[i].normalize();
    
    GV[i] = PVector.mult(normGV[i], GVLength[i]);
    SV[i] = PVector.mult(normSV[i], SVLength[i]);
    
    CV[i] = PVector.add(CV[i-1], GV[i]);
  }
  
  for (int i = 0; i < numberOfStepGrowth; i++) {
    // 侧向偏移基向量（SV 旋转 90 度）
    PVector vertical = rotation(SV[i], normGV[i], HALF_PI);
    PVector vertical2 = PVector.mult(vertical, sideShift);

    for (int j = 0; j < vertexCount; j++) {
      float angle = shape[j].y - HALF_PI;
      PVector vv1 = rotation(SV[i], normGV[i], angle);
      vv1.mult(shape[j].x);

      PVector vv2 = PVector.add(vertical2, vv1);

      PVector ringPoint = PVector.add(CV[i], vv2);
      rings[i][j] = ringPoint;

      // 计算外环和内环
      PVector normal = vv1.copy();
      normal.normalize();
      PVector offset = PVector.mult(normal, shellThickness / 2);

      ringsOuter[i][j] = PVector.add(ringPoint, offset);
      ringsInner[i][j] = PVector.sub(ringPoint, offset);
    }
  }

  computeSurfaceNormals();
}

void computeSurfaceNormals() {
  if (numberOfStepGrowth < 1) {
    return;
  }

  for (int i = 0; i < numberOfStepGrowth; i++) {
    int prevRingIndex = max(i - 1, 0);
    int nextRingIndex = min(i + 1, numberOfStepGrowth - 1);

    for (int j = 0; j < vertexCount; j++) {
      int prevJ = (j - 1 + vertexCount) % vertexCount;
      int nextJ = (j + 1) % vertexCount;

      PVector forward = PVector.sub(ringsOuter[nextRingIndex][j], ringsOuter[prevRingIndex][j]);
      PVector around = PVector.sub(ringsOuter[i][nextJ], ringsOuter[i][prevJ]);
      PVector normal = around.cross(forward);

      if (normal.magSq() < 1e-6f) {
        normal = PVector.sub(ringsOuter[i][j], CV[i]);
      }
      if (normal.magSq() < 1e-6f) {
        normal = new PVector(0, 0, 1);
      }
      normal.normalize();

      outerNormals[i][j].set(normal);
      innerNormals[i][j].set(-normal.x, -normal.y, -normal.z);
    }
  }
}

PVector rotation(PVector a, PVector b, float angle) {
  float cosAngle = cos(angle);
  float sinAngle = sin(angle);
  PVector result = new PVector(
    (cosAngle + b.x * b.x * (1 - cosAngle)) * a.x + (b.x * b.y * (1 - cosAngle) - b.z * sinAngle) * a.y + (b.z * b.x * (1 - cosAngle) + b.y * sinAngle) * a.z,
    (b.x * b.y * (1 - cosAngle) + b.z * sinAngle) * a.x + (cosAngle + b.y * b.y * (1 - cosAngle)) * a.y + (b.y * b.z * (1 - cosAngle) - b.x * sinAngle) * a.z,
    (b.z * b.x * (1 - cosAngle) - b.y * sinAngle) * a.x + (b.y * b.z * (1 - cosAngle) + b.x * sinAngle) * a.y + (cosAngle + b.z * b.z * (1 - cosAngle)) * a.z
  );
  return result;
}

int getVisibleRingCount() {
    return constrain(numberOfStepGrowth, 0, rings.length);
}

PVector getAnimatedRingPoint(int ringIndex, int vertexIndex) {
    return rings[ringIndex][vertexIndex];
}

PVector getAnimatedOuterPoint(int ringIndex, int vertexIndex) {
    return ringsOuter[ringIndex][vertexIndex];
}

PVector getAnimatedInnerPoint(int ringIndex, int vertexIndex) {
    return ringsInner[ringIndex][vertexIndex];
}

// 在顶点法线方向上偏移指定距离，供外轮廓使用
PVector getOffsetOuterPoint(int ringIndex, int vertexIndex, float offset) {
    PVector base = getAnimatedOuterPoint(ringIndex, vertexIndex).copy();
    PVector normal = outerNormals[ringIndex][vertexIndex];
    PVector expanded = PVector.mult(normal, offset);
    base.add(expanded);
    return base;
}

PVector getOffsetInnerPoint(int ringIndex, int vertexIndex, float offset) {
    PVector base = getAnimatedInnerPoint(ringIndex, vertexIndex).copy();
    PVector normal = innerNormals[ringIndex][vertexIndex];
    PVector expanded = PVector.mult(normal, offset);
    base.add(expanded);
    return base;
}
