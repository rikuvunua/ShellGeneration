void mousePressed() {
  if (mouseButton == CENTER) {
    lastMouseX = mouseX;
    lastMouseY = mouseY;
    isPanning = true;
  } else if (mouseButton == RIGHT) {
    // 右键点击切换自动旋转
    isAutoRotating = !isAutoRotating;
  } else if (mouseX > 240 && mouseY > 100) {
    lastMouseX = mouseX;
    lastMouseY = mouseY;
    isDragging = true;
  }

  isDraggingControlVertex = false; // 顶点控制已禁用
}

void mouseDragged() {
  if (isDragging && !isDraggingControlVertex) {
    float dx = radians(mouseX - lastMouseX);
    float dy = radians(mouseY - lastMouseY);
    rotX += dy;
    rotY += dx;
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  } else if (isPanning) {
    float dx = mouseX - lastMouseX;
    float dy = mouseY - lastMouseY;
    panX += dx;
    panY += dy;
    lastMouseX = mouseX;
    lastMouseY = mouseY;
  }
}

void mouseReleased() {
  if (isDraggingControlVertex) {
    saveState();
  }

  isDragging = false;
  isPanning = false;
  isDraggingControlVertex = false;
  for (int i = 0; i < controlVertices.length; i++) {
    dragging[i] = false;
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoom += e * 0.05;
  zoom = constrain(zoom, 0.1, 7.5); // 限制缩放级别
}

// 串口增量控制
void applyIncrementalControl(int bendingDelta, int twistingDelta, int growthRateDelta) {
    // 保存当前状态用于撤销
    if (!isUndoingOrRedoing) {
        saveState();
    }
    
    // 应用bending angle增量
    if (bendingDelta != 0) {
        float currentBending = sliderBendAngle.getValue();
        float newBending = constrain(currentBending + bendingDelta, 0, 100);
        sliderBendAngle.setValue(newBending);
        bendAngle = 0.005f * newBending;
        println("Bending angle changed by " + bendingDelta + " to " + newBending);
    }
    
    // 应用twisting angle增量
    if (twistingDelta != 0) {
        float currentTwisting = sliderTwistAngle.getValue();
        float newTwisting = constrain(currentTwisting + (twistingDelta * 2), 0, 200);
        sliderTwistAngle.setValue(newTwisting);
        twistAngle = 0.001f * newTwisting;
        println("Twisting angle changed by " + (twistingDelta * 2) + " to " + newTwisting);
    }
    
    // 应用growth rate增量（UI 隐藏时直接调整变量）
    if (growthRateDelta != 0) {
        float base = sliderGrowthRate != null ? sliderGrowthRate.getValue() : growthRate;
        float newGrowthRate = constrain(base + (growthRateDelta * 0.001f), 1.03f, 1.05f);
        if (sliderGrowthRate != null) {
          sliderGrowthRate.setValue(newGrowthRate);
        }
        growthRate = newGrowthRate;
        println("Growth rate changed by " + (growthRateDelta * 0.001f) + " to " + nf(newGrowthRate, 0, 3));
    }
    
    // 更新参数并重新计算
    updateParametersFromSliders();
    resetVectors();
}
