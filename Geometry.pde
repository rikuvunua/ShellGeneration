void resetVectors() {
  // 初始化方向向量
  normGV[0] = new PVector(0, 0, 1);
  normSV[0] = new PVector(0, 1, 0);

  // 应用生长率计算实际长度
  for (int i = 0; i < numberOfStepGrowth; i++) {
    GVLength[i] = initGVL * pow(growthRate, i);
    SVLength[i] = initSVL * pow(growthRate, i);
  }

  // 基础向量（与 JS 版本一致）
  GV[0] = PVector.mult(normGV[0], GVLength[0]);
  SV[0] = PVector.mult(normSV[0], SVLength[0]);
  CV[0] = GV[0].copy();
  
  for (int i = 1; i < numberOfStepGrowth; i++) {
    normGV[i] = rotation(normGV[i-1], normSV[i-1], bendAngle);
    normGV[i].normalize();
    normSV[i] = rotation(normSV[i-1], normGV[i], twistAngle);
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
