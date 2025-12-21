import controlP5.*;
import processing.data.XML;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import processing.serial.*;
import processing.opengl.*;

void setup() {
  fullScreen(P3D);
  shellShader = loadShader("shaders/shellFrag.glsl", "shaders/shellVert.glsl");
  configureShellShader();
  backgroundTopColor = color(0x19, 0x19, 0x19);
  backgroundBottomColor = color(0xbc, 0xe1, 0xe7);
  gradientNeedsUpdate = true;  
  
  initSerial();
  
  cp5 = new ControlP5(this);

  // 默认摄像机视角，若 XML 中未写入视角则使用这一套
  resetCameraView();
  
  initializeShapesAndRings(); // 确保在调用任何用 shape 的方法之前初始化它
  setupInterface();           // 初始化界面控件
  setupControlVertices();     // 初始化控制顶点
  loadParametersFromXML();    // 加载参数集
  updateDropdownParameterSets(); // 更新下拉列表
  resetVectors();             // 置向量
  saveState();                // 保存初始状态
}

void draw() {
  processSerial();

  int renderMode = (radio != null) ? (int)radio.getValue() : 1;
  if (useGradientBackground) {
    drawBackgroundGradient();
  } else {
    background(0xFF, 0xFF, 0xFF);
  }
  
  // 默认光照会在每帧被重置，补回灯光以获得与旧版相同的明暗效果
  lights();

  // 实时更新参数
  updateParametersFromSliders();

  resetVectors();

  // 如果启用了自动旋转，更新rotY
  if (isAutoRotating) {
    rotY += autoRotateSpeed;
  }

  pushMatrix();
  translate(width / 2 + panX, height / 2 + panY);
  scale(zoom);
  rotateX(rotX);
  rotateY(rotY);

  if (renderMode == 1) {
    drawOpenRings();
  } else if (renderMode == 2) {  // Show Shell Surface
    drawShellOutline();  // 新增的贴合外轮廓
    drawWireSurface();   // 现在显示线框表面
  } else {  // Show Surface (值为3)
    drawSurface();       // 现在显示实体表面（经典模式）
  }

  popMatrix();

  // 叠加扭转角折线图（先关闭深度测试避免与 3D 遮挡）
  if (showTwistPlot2D) {
    hint(DISABLE_DEPTH_TEST);
    float plotWidth = TWIST_PLOT_WIDTH;
    float plotHeight = TWIST_PLOT_HEIGHT;
    float plotMargin = TWIST_PLOT_MARGIN;
    float plotX = width - plotWidth - plotMargin;
    float plotY = height - plotHeight - plotMargin;
    drawTwistAnglePlot2D(plotX, plotY, plotWidth, plotHeight);
    hint(ENABLE_DEPTH_TEST);
  }

  drawCameraInfo();
  drawInterface();
  drawControlInterface();
  updateShapeFromControlVertices();
  
}

void resetCameraView() {
  rotX = radians(DEFAULT_CAMERA_ROT_X_DEG);
  rotY = radians(DEFAULT_CAMERA_ROT_Y_DEG);
  panX = DEFAULT_CAMERA_PAN_X;
  panY = DEFAULT_CAMERA_PAN_Y;
  zoom = DEFAULT_CAMERA_ZOOM;
}

void initializeShapesAndRings() {
  shape = new PVector[vertexCount];
  float angleStep = TWO_PI / vertexCount;
  for (int i = 0; i < vertexCount; i++) {
    // 半径固定为 1，角度等分（与 ShellShapeGenerator.js 保持一致）
    shape[i] = new PVector(1, angleStep * i, 0);
  }

  rings = new PVector[100][vertexCount];
  ringsOuter = new PVector[100][vertexCount];
  ringsInner = new PVector[100][vertexCount];
  outerNormals = new PVector[100][vertexCount];
  innerNormals = new PVector[100][vertexCount];

  for (int i = 0; i < 100; i++) {
    for (int j = 0; j < vertexCount; j++) {
      rings[i][j] = new PVector(0, 0, 0);
      ringsOuter[i][j] = new PVector(0, 0, 0);
      ringsInner[i][j] = new PVector(0, 0, 0);
      outerNormals[i][j] = new PVector(0, 0, 1);
      innerNormals[i][j] = new PVector(0, 0, -1);
    }
  }

  for (int i = 0; i < 100; i++) {
    GVLength[i] = initGVL * pow(growthRate, i);
    SVLength[i] = initSVL * pow(growthRate, i);
    normGV[i] = new PVector(0, 0, 0);
    normSV[i] = new PVector(0, 0, 0);
    GV[i] = new PVector(0, 0, 0);
    SV[i] = new PVector(0, 0, 0);
    CV[i] = new PVector(0, 0, 0);
  }

  controlVertices = new PVector[vertexCount];
  dragging = new boolean[vertexCount];
  PVector center = getControlCenter();
  for (int i = 0; i < vertexCount; i++) {
    controlVertices[i] = new PVector(center.x, center.y);
  }
}

void setVertexCount(int newCount) {
  setVertexCount(newCount, true);
}

void setVertexCount(int newCount, boolean preserveShape) {
  int constrainedCount = constrain(newCount, MIN_VERTEX_COUNT, MAX_VERTEX_COUNT);
  if (constrainedCount == vertexCount) {
    return;
  }

  PVector[] previousControls = null;
  if (preserveShape && controlVertices != null) {
    previousControls = new PVector[controlVertices.length];
    for (int i = 0; i < controlVertices.length; i++) {
      previousControls[i] = controlVertices[i].copy();
    }
  }

  vertexCount = constrainedCount;
  initializeShapesAndRings();

  if (previousControls != null && previousControls.length > 0) {
    PVector[] resampled = resampleControlVertices(previousControls, vertexCount);
    applyControlVertices(resampled);
  } else {
    setupControlVertices();
    updateShapeFromControlVertices();
  }

  resetVectors();
}

PVector[] resampleControlVertices(PVector[] source, int targetCount) {
  if (source == null || source.length == 0) {
    return createDefaultControlVertices(targetCount);
  }

  int sourceCount = source.length;
  PVector center = getControlCenter();
  PVector[] polar = new PVector[sourceCount];
  for (int i = 0; i < sourceCount; i++) {
    float radius = PVector.dist(source[i], center);
    float angle = atan2(source[i].y - center.y, source[i].x - center.x);
    polar[i] = new PVector(radius, angle);
  }

  PVector[] result = new PVector[targetCount];
  for (int i = 0; i < targetCount; i++) {
    float t = ((float)i / targetCount) * sourceCount;
    int idx0 = floor(t) % sourceCount;
    int idx1 = (idx0 + 1) % sourceCount;
    float frac = t - floor(t);

    float radius = lerp(polar[idx0].x, polar[idx1].x, frac);
    float angle = lerpAngle(polar[idx0].y, polar[idx1].y, frac);

    float px = center.x + cos(angle) * radius;
    float py = center.y + sin(angle) * radius;
    result[i] = new PVector(px, py);
  }

  return result;
}

PVector[] createDefaultControlVertices(int count) {
  PVector[] defaults = new PVector[count];
  float angleStep = TWO_PI / count;
  float controlRadius = 50;
  PVector center = getControlCenter();
  for (int i = 0; i < count; i++) {
    float angle = i * angleStep;
    float px = center.x + cos(angle) * controlRadius;
    float py = center.y + sin(angle) * controlRadius;
    defaults[i] = new PVector(px, py);
  }
  return defaults;
}

void applyControlVertices(PVector[] newVertices) {
  if (newVertices == null || newVertices.length != vertexCount) {
    setupControlVertices();
  } else {
    for (int i = 0; i < vertexCount; i++) {
      if (controlVertices[i] == null) {
        controlVertices[i] = new PVector();
      }
      controlVertices[i].set(newVertices[i]);
    }
  }
  updateShapeFromControlVertices();
}

float lerpAngle(float a, float b, float t) {
  float diff = atan2(sin(b - a), cos(b - a));
  return a + diff * t;
}

void drawOpenRings() {
  float strokeWeightValue = 1 / zoom; // 保持缩放一致的线条宽度
  strokeWeight(strokeWeightValue);
  int ringCount = getVisibleRingCount();
  if (ringCount <= 0) {
    return;
  }
  for (int i = 0; i < ringCount; i++) {
    beginShape();
    for (int j = 0; j < vertexCount; j++) {
      PVector point = getAnimatedRingPoint(i, j);
      vertex(point.x, point.y, point.z);
    }
    PVector firstPoint = getAnimatedRingPoint(i, 0);
    vertex(firstPoint.x, firstPoint.y, firstPoint.z);
    endShape();
  }
}

void drawSurface() {
  int ringCount = getVisibleRingCount();
  if (ringCount < 2) {
    return;
  }

  pushStyle();
  float strokeWeightValue = 0.5f / max(zoom, 0.0001f);
  strokeWeight(strokeWeightValue);
  fill(200);
  noStroke();

  // 绘制外表面（经典模式）
  for (int i = 0; i < ringCount - 1; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector outer00 = getAnimatedOuterPoint(i, j);
      PVector outer10 = getAnimatedOuterPoint(i + 1, j);
      PVector outer11 = getAnimatedOuterPoint(i + 1, nextJ);
      PVector outer01 = getAnimatedOuterPoint(i, nextJ);
      beginShape();
      vertex(outer00.x, outer00.y, outer00.z);
      vertex(outer10.x, outer10.y, outer10.z);
      vertex(outer11.x, outer11.y, outer11.z);
      vertex(outer01.x, outer01.y, outer01.z);
      endShape(CLOSE);
    }
  }

  // 绘制内表面
  for (int i = 0; i < ringCount - 1; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector inner00 = getAnimatedInnerPoint(i, j);
      PVector inner01 = getAnimatedInnerPoint(i, nextJ);
      PVector inner11 = getAnimatedInnerPoint(i + 1, nextJ);
      PVector inner10 = getAnimatedInnerPoint(i + 1, j);
      beginShape();
      vertex(inner00.x, inner00.y, inner00.z);
      vertex(inner01.x, inner01.y, inner01.z);
      vertex(inner11.x, inner11.y, inner11.z);
      vertex(inner10.x, inner10.y, inner10.z);
      endShape(CLOSE);
    }
  }

  // 绘制侧面
  for (int i = 0; i < ringCount; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector outer0 = getAnimatedOuterPoint(i, j);
      PVector outer1 = getAnimatedOuterPoint(i, nextJ);
      PVector inner1 = getAnimatedInnerPoint(i, nextJ);
      PVector inner0 = getAnimatedInnerPoint(i, j);
      beginShape();
      vertex(outer0.x, outer0.y, outer0.z);
      vertex(outer1.x, outer1.y, outer1.z);
      vertex(inner1.x, inner1.y, inner1.z);
      vertex(inner0.x, inner0.y, inner0.z);
      endShape(CLOSE);
    }
  }

  // 绘制首端面
  for (int j = 0; j < vertexCount; j++) {
    int nextJ = (j + 1) % vertexCount;
    PVector outer0 = getAnimatedOuterPoint(0, j);
    PVector outer1 = getAnimatedOuterPoint(0, nextJ);
    PVector inner1 = getAnimatedInnerPoint(0, nextJ);
    PVector inner0 = getAnimatedInnerPoint(0, j);
    beginShape();
    vertex(outer0.x, outer0.y, outer0.z);
    vertex(outer1.x, outer1.y, outer1.z);
    vertex(inner1.x, inner1.y, inner1.z);
    vertex(inner0.x, inner0.y, inner0.z);
    endShape(CLOSE);
  }

  // 绘制尾端面
  int lastIndex = ringCount - 1;
  for (int j = 0; j < vertexCount; j++) {
    int nextJ = (j + 1) % vertexCount;
    PVector outer0 = getAnimatedOuterPoint(lastIndex, j);
    PVector outer1 = getAnimatedOuterPoint(lastIndex, nextJ);
    PVector inner1 = getAnimatedInnerPoint(lastIndex, nextJ);
    PVector inner0 = getAnimatedInnerPoint(lastIndex, j);
    beginShape();
    vertex(outer0.x, outer0.y, outer0.z);
    vertex(outer1.x, outer1.y, outer1.z);
    vertex(inner1.x, inner1.y, inner1.z);
    vertex(inner0.x, inner0.y, inner0.z);
    endShape(CLOSE);
  }

  popStyle();
}

void updateShapeFromControlVertices() {
  PVector center = getControlCenter();
  float aspectRatio = lerp(1.0f, 0.2f, constrain(openingFlatten, 0, 1));
  float rotationRad = radians(openingRotationDeg);
  float cosRot = cos(rotationRad);
  float sinRot = sin(rotationRad);
  float controlRadius = 50;
  float angleStep = TWO_PI / max(vertexCount, 1);

  for (int i = 0; i < controlVertices.length; i++) {
    float baseAngle = i * angleStep;
    float x = cos(baseAngle) * controlRadius;
    float y = sin(baseAngle) * controlRadius;

    y *= aspectRatio; // 扁平化，minor axis = aspectRatio

    float xr = x * cosRot - y * sinRot;
    float yr = x * sinRot + y * cosRot;

    float scaledRadius = sqrt(xr * xr + yr * yr) / controlRadius;
    shape[i].x = scaledRadius;
    shape[i].y = atan2(yr, xr);

    controlVertices[i].set(center.x + xr, center.y + yr);
  }
}

// 添加新的绘制方法
void drawWireSurface() {
  float strokeWeightValue = 0.5 / zoom; // 保持缩放一致的线条宽度
  strokeWeight(strokeWeightValue);
  int ringCount = getVisibleRingCount();
  if (ringCount < 2) {
    return;
  }
  for (int i = 0; i < ringCount - 1; i++) {
    for (int j = 0; j < vertexCount - 1; j++) {
      PVector p00 = getAnimatedRingPoint(i, j);
      PVector p01 = getAnimatedRingPoint(i, j + 1);
      PVector p11 = getAnimatedRingPoint(i + 1, j + 1);
      PVector p10 = getAnimatedRingPoint(i + 1, j);
      beginShape();
      vertex(p00.x, p00.y, p00.z);
      vertex(p01.x, p01.y, p01.z);
      vertex(p11.x, p11.y, p11.z);
      vertex(p00.x, p00.y, p00.z);
      endShape(CLOSE);

      beginShape();
      vertex(p00.x, p00.y, p00.z);
      vertex(p10.x, p10.y, p10.z);
      vertex(p11.x, p11.y, p11.z);
      vertex(p00.x, p00.y, p00.z);
      endShape(CLOSE);
    }

    // 处理首尾相连的部分
    PVector pStartCurrent = getAnimatedRingPoint(i, vertexCount - 1);
    PVector pStartNext = getAnimatedRingPoint(i + 1, vertexCount - 1);
    PVector pFirstCurrent = getAnimatedRingPoint(i, 0);
    PVector pFirstNext = getAnimatedRingPoint(i + 1, 0);
    beginShape();
    vertex(pStartCurrent.x, pStartCurrent.y, pStartCurrent.z);
    vertex(pFirstCurrent.x, pFirstCurrent.y, pFirstCurrent.z);
    vertex(pFirstNext.x, pFirstNext.y, pFirstNext.z);
    vertex(pStartCurrent.x, pStartCurrent.y, pStartCurrent.z);
    endShape();

    beginShape();
    vertex(pStartCurrent.x, pStartCurrent.y, pStartCurrent.z);
    vertex(pStartNext.x, pStartNext.y, pStartNext.z);
    vertex(pFirstNext.x, pFirstNext.y, pFirstNext.z);
    vertex(pStartCurrent.x, pStartCurrent.y, pStartCurrent.z);
    endShape();
  }
}

// 在表面外侧绘制一个加厚的黑色轮廓，避免修改原有描边
void drawShellOutline() {
  int ringCount = getVisibleRingCount();
  if (ringCount < 2) {
    return;
  }

  float outlineOffset = 2f / max(zoom, 0.0001f); // 按缩放保持视觉厚度（外轮廓粗细为2）

  pushStyle();
  hint(DISABLE_DEPTH_TEST); // 不写入深度，让后续线框盖住轮廓内部
  noStroke();
  fill(0);

  // 外表面
  for (int i = 0; i < ringCount - 1; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector outer00 = getOffsetOuterPoint(i, j, outlineOffset);
      PVector outer10 = getOffsetOuterPoint(i + 1, j, outlineOffset);
      PVector outer11 = getOffsetOuterPoint(i + 1, nextJ, outlineOffset);
      PVector outer01 = getOffsetOuterPoint(i, nextJ, outlineOffset);
      beginShape();
      vertex(outer00.x, outer00.y, outer00.z);
      vertex(outer10.x, outer10.y, outer10.z);
      vertex(outer11.x, outer11.y, outer11.z);
      vertex(outer01.x, outer01.y, outer01.z);
      endShape(CLOSE);
    }
  }

  // 内表面
  for (int i = 0; i < ringCount - 1; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector inner00 = getOffsetInnerPoint(i, j, outlineOffset);
      PVector inner01 = getOffsetInnerPoint(i, nextJ, outlineOffset);
      PVector inner11 = getOffsetInnerPoint(i + 1, nextJ, outlineOffset);
      PVector inner10 = getOffsetInnerPoint(i + 1, j, outlineOffset);
      beginShape();
      vertex(inner00.x, inner00.y, inner00.z);
      vertex(inner01.x, inner01.y, inner01.z);
      vertex(inner11.x, inner11.y, inner11.z);
      vertex(inner10.x, inner10.y, inner10.z);
      endShape(CLOSE);
    }
  }

  // 侧面
  for (int i = 0; i < ringCount; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector outer0 = getOffsetOuterPoint(i, j, outlineOffset);
      PVector outer1 = getOffsetOuterPoint(i, nextJ, outlineOffset);
      PVector inner1 = getOffsetInnerPoint(i, nextJ, outlineOffset);
      PVector inner0 = getOffsetInnerPoint(i, j, outlineOffset);
      beginShape();
      vertex(outer0.x, outer0.y, outer0.z);
      vertex(outer1.x, outer1.y, outer1.z);
      vertex(inner1.x, inner1.y, inner1.z);
      vertex(inner0.x, inner0.y, inner0.z);
      endShape(CLOSE);
    }
  }

  // 首端面
  for (int j = 0; j < vertexCount; j++) {
    int nextJ = (j + 1) % vertexCount;
    PVector outer0 = getOffsetOuterPoint(0, j, outlineOffset);
    PVector outer1 = getOffsetOuterPoint(0, nextJ, outlineOffset);
    PVector inner1 = getOffsetInnerPoint(0, nextJ, outlineOffset);
    PVector inner0 = getOffsetInnerPoint(0, j, outlineOffset);
    beginShape();
    vertex(outer0.x, outer0.y, outer0.z);
    vertex(outer1.x, outer1.y, outer1.z);
    vertex(inner1.x, inner1.y, inner1.z);
    vertex(inner0.x, inner0.y, inner0.z);
    endShape(CLOSE);
  }

  // 尾端面
  int lastIndex = ringCount - 1;
  for (int j = 0; j < vertexCount; j++) {
    int nextJ = (j + 1) % vertexCount;
    PVector outer0 = getOffsetOuterPoint(lastIndex, j, outlineOffset);
    PVector outer1 = getOffsetOuterPoint(lastIndex, nextJ, outlineOffset);
    PVector inner1 = getOffsetInnerPoint(lastIndex, nextJ, outlineOffset);
    PVector inner0 = getOffsetInnerPoint(lastIndex, j, outlineOffset);
    beginShape();
    vertex(outer0.x, outer0.y, outer0.z);
    vertex(outer1.x, outer1.y, outer1.z);
    vertex(inner1.x, inner1.y, inner1.z);
    vertex(inner0.x, inner0.y, inner0.z);
    endShape(CLOSE);
  }

  hint(ENABLE_DEPTH_TEST);
  popStyle();
}

// 添加增量控制方法
