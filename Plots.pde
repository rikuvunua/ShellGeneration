// 扭转角折线图尺寸
final float TWIST_PLOT_WIDTH = 360;
final float TWIST_PLOT_HEIGHT = 240;
final float TWIST_PLOT_MARGIN = 20;
final float TWIST_PLOT_EXPORT_SCALE = 2.0f;

// 绘制扭转角随生长步数变化的简单 2D 折线图（默认绘制到屏幕）
void drawTwistAnglePlot2D(float originX, float originY, float plotWidth, float plotHeight) {
  drawTwistAnglePlot2D(g, originX, originY, plotWidth, plotHeight);
}

// 可绘制到任意 PGraphics，便于导出
void drawTwistAnglePlot2D(PGraphics pg, float originX, float originY, float plotWidth, float plotHeight) {
  pg.pushStyle();

  // 背景与边框
  pg.noStroke();
  pg.fill(255, 245);
  pg.rect(originX, originY, plotWidth, plotHeight);
  pg.stroke(0, 80);
  pg.noFill();
  pg.rect(originX, originY, plotWidth, plotHeight);

  // 绘制区域边距，确保轴线与文本不重叠
  float leftMargin = 60;   // 稍微收窄左侧留白，放大横向绘图区
  float rightMargin = 14;
  float topMargin = 16;
  float bottomMargin = 48; // 底部加大留给刻度与标题

  float axisLeft = originX + leftMargin;
  float axisRight = originX + plotWidth - rightMargin;
  float axisTop = originY + topMargin;
  float axisBottom = originY + plotHeight - bottomMargin;

  // 轴线
  pg.stroke(0, 80);
  pg.strokeWeight(0.75f);
  pg.line(axisLeft, axisBottom, axisRight, axisBottom); // x 轴
  pg.line(axisLeft, axisBottom, axisLeft, axisTop);     // y 轴

  // 坐标轴标签
  pg.fill(0);
  pg.textSize(11);
  pg.textAlign(CENTER, CENTER);
  pg.text("step", (axisLeft + axisRight) * 0.5f, originY + plotHeight - 12); // 轴标题更靠下

  pg.pushMatrix();
  pg.translate(axisLeft - 42, (axisTop + axisBottom) * 0.5f);
  pg.rotate(-HALF_PI);
  pg.text("twist angle", 0, 0);
  pg.popMatrix();

  int steps = max(numberOfStepGrowth, 0);
  if (steps > 0) {
    float[] values = new float[steps];
    float minVal = Float.MAX_VALUE;
    float maxVal = -Float.MAX_VALUE;
    for (int i = 0; i < steps; i++) {
      float val = getTwistAngleWithMutations(i);
      values[i] = val;
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }

    // 避免极小范围造成折线不可见
    if (abs(maxVal - minVal) < 1e-6f) {
      float padding = max(0.01f, abs(maxVal) * 0.1f);
      minVal -= padding;
      maxVal += padding;
    }

    int decimals = (abs(maxVal - minVal) < 1.0f) ? 2 : 1;

    // y 轴刻度
    pg.stroke(0, 80);
    pg.textSize(10);
    pg.textAlign(RIGHT, CENTER);
    for (int t = 0; t < 5; t++) {
      float ratio = t / 4.0f;
      float tickVal = lerp(minVal, maxVal, ratio);
      float ty = map(tickVal, minVal, maxVal, axisBottom, axisTop);
      pg.line(axisLeft - 6, ty, axisLeft, ty);
      pg.text(nf(tickVal, 0, decimals), axisLeft - 8, ty);
    }

    // x 轴刻度（0, N/4, N/2, 3N/4, N-1）
    pg.textAlign(CENTER, TOP);
    int[] tickIndices = {
      0,
      max(0, round((steps - 1) * 0.25f)),
      max(0, round((steps - 1) * 0.5f)),
      max(0, round((steps - 1) * 0.75f)),
      max(0, steps - 1)
    };
    int lastTick = -1;
    for (int i = 0; i < tickIndices.length; i++) {
      int idx = tickIndices[i];
      if (idx == lastTick || idx >= steps) {
        continue;
      }
      float tx = (steps == 1) ? axisLeft : map(idx, 0, steps - 1, axisLeft, axisRight);
      pg.line(tx, axisBottom, tx, axisBottom + 6);
      int labelValue = (idx == steps - 1) ? steps : idx; // 末尾显示总步数（如50）
      pg.text(labelValue, tx, axisBottom + 12); // 与轴标题错开
      lastTick = idx;
    }

    pg.stroke(0, 120, 255);
    pg.strokeWeight(2);
    pg.noFill();
    pg.beginShape();
    for (int i = 0; i < steps; i++) {
      float px = (steps == 1) ? axisLeft : map(i, 0, steps - 1, axisLeft, axisRight);
      float py = map(values[i], minVal, maxVal, axisBottom, axisTop);
      pg.vertex(px, py);
    }
    pg.endShape();
  }

  pg.popStyle();
}

// 导出 2x 分辨率的扭转角折线图
void exportTwistAnglePlotPNG2x() {
  float plotWidth = TWIST_PLOT_WIDTH;
  float plotHeight = TWIST_PLOT_HEIGHT;
  int exportWidth = round(plotWidth * TWIST_PLOT_EXPORT_SCALE);
  int exportHeight = round(plotHeight * TWIST_PLOT_EXPORT_SCALE);

  // 使用默认 2D 渲染器，避免 P2D 离屏缓冲偶发透明的问题
  PGraphics plotPG = createGraphics(exportWidth, exportHeight);
  plotPG.beginDraw();
  plotPG.colorMode(RGB, 255);
  plotPG.background(255); // 先铺底色，避免透明背景
  plotPG.pushMatrix();
  plotPG.scale(TWIST_PLOT_EXPORT_SCALE);
  drawTwistAnglePlot2D(plotPG, 0, 0, plotWidth, plotHeight);
  plotPG.popMatrix();
  plotPG.endDraw();

  String timestamp = new java.text.SimpleDateFormat("yyyyMMdd_HHmmss").format(new java.util.Date());
  String filename = "twist_plot_" + timestamp + "_2x.png";
  String filePath = sketchPath(filename);
  plotPG.save(filePath);
  println("Twist plot exported to " + filePath);
}
