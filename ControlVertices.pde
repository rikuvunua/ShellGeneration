PVector getControlCenter() {
  return new PVector(width - 100, 100);
}

void setupControlVertices() {
  float angleStep = TWO_PI / vertexCount;
  float controlRadius = 50;
  float centerX = width - 100;
  float centerY = 100;

  for (int i = 0; i < vertexCount; i++) {
    float angle = i * angleStep;
    float px = centerX + cos(angle) * controlRadius;
    float py = centerY + sin(angle) * controlRadius;

    if (controlVertices[i] == null) {
      controlVertices[i] = new PVector();
    }
    controlVertices[i].set(px, py);

    if (shape[i] == null) {
      shape[i] = new PVector();
    }
    shape[i].x = controlRadius / 50f;
    shape[i].y = angle;
  }
}

void drawControlInterface() {
  // 绘制背景
  fill(255, 255, 255);
  noStroke();
  beginShape();
  for (PVector cv : controlVertices) {
    vertex(cv.x, cv.y);
  }
  endShape(CLOSE);

  // 绘制顶点之间的线
  stroke(0);
  strokeWeight(2);
  beginShape();
  for (PVector cv : controlVertices) {
    vertex(cv.x, cv.y);
  }
  endShape(CLOSE);

  // 绘制控制顶点
  fill(255);
  for (PVector cv : controlVertices) {
    ellipse(cv.x, cv.y, 10, 10);
  }
}
