ControlP5 cp5;
RadioButton radio;
Slider sliderVertexCount, sliderGrowthStep, sliderGrowthRate, sliderBendAngle, sliderTwistAngle, sliderConeHight, sliderConeWidth, sliderSideShift, sliderThickness;
Slider sliderOpeningFlatten, sliderOpeningRotation;
Slider sliderTwistGradient, sliderTwistWaveAmplitude, sliderTwistWaveFrequency, sliderTwistWavePhase;
Button resetButton, undoButton, redoButton;
Toggle toggleGradientBackground;
Toggle toggleShowTwistPlot;
Toggle toggleShowCameraInfo;
Toggle toggleTwistMod;
Toggle toggleSpiralOverlay;
Textfield sliderInputField = null;
boolean sliderInputPrimed = false; // first key replaces existing text

// UI spacing rules
final int UI_SPACING = 30;      // vertical step between stacked controls
final int UI_GROUP_GAP = 20;    // gap between groups
final int UI_BUTTON_GAP = 12;   // extra gap between stacked buttons

DropdownList dropdownParameterSets;

Group parametersGroup, openingShapeGroup, twistModGroup, displayGroup, exportGroup;

// UI state
boolean isSliderDragging = false;
ArrayList<Slider> allSliders = new ArrayList<Slider>();
Slider sliderBeingEdited = null;

void registerSlider(Slider slider) {
  if (slider != null) {
    allSliders.add(slider);
  }
}

void setupInterface() {
  // 创建参数组
  parametersGroup = cp5.addGroup("Parameters")
    .setPosition(20, 25)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(460)
    .setLabel("Parameters");

  int yPos = 10;
  int yStep = UI_SPACING;

  // 顶点数量滑块（可调 12-36）
  sliderVertexCount = cp5.addSlider("Vertex Count")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(MIN_VERTEX_COUNT, MAX_VERTEX_COUNT)
    .setValue(vertexCount)
    .setNumberOfTickMarks(MAX_VERTEX_COUNT - MIN_VERTEX_COUNT + 1)
    .setDecimalPrecision(0)
    .moveTo(parametersGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  sliderVertexCount.snapToTickMarks(true);
  registerSlider(sliderVertexCount);
  yPos += yStep;

  // 添加所有滑块
  sliderGrowthStep = cp5.addSlider("Growth Steps")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(0, 100)
    .setDecimalPrecision(0)
    .setValue(numberOfStepGrowth)
    .moveTo(parametersGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderGrowthStep);
  yPos += yStep;

  sliderGrowthRate = cp5.addSlider("Growth Rate")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(1.0f, 1.06f)
    .setValue(growthRate)
    .setDecimalPrecision(2)
    .moveTo(parametersGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderGrowthRate);
  yPos += yStep;

  sliderBendAngle = cp5.addSlider("Bending Angle")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(0, 100)
    .setDecimalPrecision(0)
    .setValue(bendAngle * 200)
    .moveTo(parametersGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderBendAngle);
  yPos += yStep;

  sliderTwistAngle = cp5.addSlider("Twisting Angle")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(0, 200)
    .setDecimalPrecision(0)
    .setValue(twistAngle * 1000)
    .moveTo(parametersGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderTwistAngle);
  yPos += yStep;

  sliderConeHight = cp5.addSlider("Cone Height")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(0, 100)
    .setDecimalPrecision(0)
    .setValue(initGVL * 40)
    .moveTo(parametersGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderConeHight);
  yPos += yStep;

  sliderConeWidth = cp5.addSlider("Cone Width")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(20, 80)
    .setDecimalPrecision(0)
    .setValue(initSVL * 10)
    .moveTo(parametersGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderConeWidth);
  yPos += yStep;

  sliderSideShift = cp5.addSlider("Side Shift")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(-100, 100)
    .setDecimalPrecision(0)
    .setValue(sideShift * 100)
    .moveTo(parametersGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  sliderSideShift.hide();
  registerSlider(sliderSideShift);

  // 记录 DropdownList 的位置
  int yDropdown = yPos;

  // 添加 RadioButton 和其他钮（在 DropdownList 之前）
  yPos += yStep; // 留出足够的空间

  // 添加 RadioButton
  radio = cp5.addRadioButton("radio")
    .setPosition(10, yPos)
    .setSize(20, 20)
    .setSpacingRow(6)            // 设置行间距
    .setSpacingColumn(160)       // 设置列间距
    .addItem("Show Opening Rings", 1)
    .addItem("Show Shell Surface", 2)   // 保持文字不变
    .addItem("Show 3D Model", 3)         // 保持文字不变
    .setItemsPerRow(1)           // 垂直排列避免重叠
    .activate(1)
    .moveTo(parametersGroup);

  yPos += yStep * 3;  // 为三个单选项留出空间
  //yPos += yStep; // 额外的间距，使后续按钮与单选项分隔开

  // 添加重置和保存按钮
  resetButton = cp5.addButton("Reset")
    .setPosition(10, yPos)
    .setSize(80, 30)
    .moveTo(parametersGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        resetParameters();
        setupControlVertices(); // 重置控制顶点
        saveState();
      }
    });

  cp5.addButton("SaveToXML")
    .setPosition(100, yPos)
    .setSize(80, 30)  // 减小宽度
    .moveTo(parametersGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        // 临时设置为-1，确保创建新参数集而不是更新现有的
        int originalIndex = currentParameterSetIndex;
        currentParameterSetIndex = -1;
        
        ParameterSet newPS = saveParametersToXML(); // 获取新参数集
        // 动态添加到参数集列表和下拉菜单
        parameterSets.add(newPS);
        dropdownParameterSets.addItem(newPS.name, parameterSets.size() - 1);
        // 设置当前选择为新添加的参数集
        currentParameterSetIndex = parameterSets.size() - 1;
        dropdownParameterSets.setValue(currentParameterSetIndex);
      }
    });

  // 添加Update按钮
  cp5.addButton("Update")
    .setPosition(190, yPos)  // 紧接着SaveToXML按钮
    .setSize(80, 30)
    .moveTo(parametersGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        updateCurrentParameterSet();
      }
    });

  yPos += 40; // 调整按钮的高度

  // 添加撤销和重做按钮
  undoButton = cp5.addButton("Undo")
    .setPosition(10, yPos)
    .setSize(80, 30)
    .moveTo(parametersGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        undo();
      }
    });

  redoButton = cp5.addButton("Redo")
    .setPosition(100, yPos)
    .setSize(80, 30)
    .moveTo(parametersGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        redo();
      }
    });

  // 添加Delete按钮
  cp5.addButton("Delete")
    .setPosition(190, yPos)  // 在Redo按钮右边
    .setSize(80, 30)
    .moveTo(parametersGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        deleteCurrentParameterSet();
      }
    });

  // 现在在预留的位置添加 DropdownList
  dropdownParameterSets = cp5.addDropdownList("Parameter Sets")
    .setPosition(10, yDropdown)  // 使用之前记录的位置
    .setSize(200, 200)
    .setItemHeight(20)
    .setBarHeight(20)
    .setOpen(false)
    .moveTo(parametersGroup)
    .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        if (event.getController().getValue() >= 0) {
          currentParameterSetIndex = (int)event.getController().getValue();
          applyParameterSet(parameterSets.get(currentParameterSetIndex));
          event.getController().setCaptionLabel("Parameter Set " + (currentParameterSetIndex + 1));
        }
      }
    });

  // 统一 Parameters 组高度：取最后一行按钮底部与下拉菜单底部的较大值，再加固定留白
  int paramsButtonsBottom = yPos + 30;           // 最后一排按钮高度 30
  int paramsDropdownBottom = yDropdown + 200;    // 下拉区域高度 200
  int paramsContentBottom = max(paramsButtonsBottom, paramsDropdownBottom);
  parametersGroup.setBackgroundHeight(paramsContentBottom + UI_GROUP_GAP);
  // 更新 yPos 为屏幕坐标，便于后续组定位
  yPos = (int)(parametersGroup.getPosition()[1] + parametersGroup.getBackgroundHeight() + UI_GROUP_GAP);

  // 开口形状控制组
  openingShapeGroup = cp5.addGroup("Opening Shape")
    .setPosition(20, yPos)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(90)
    .setLabel("Opening Shape");

  int yOpeningPos = 10;

  sliderOpeningFlatten = cp5.addSlider("Opening Flatten")
    .setPosition(10, yOpeningPos)
    .setSize(200, 20)
    .setRange(0, 1)
    .setValue(openingFlatten)
    .setDecimalPrecision(2)
    .moveTo(openingShapeGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderOpeningFlatten);

  yOpeningPos += yStep;

  sliderOpeningRotation = cp5.addSlider("Opening Rotation")
    .setPosition(10, yOpeningPos)
    .setSize(200, 20)
    .setRange(-180, 180)
    .setValue(openingRotationDeg)
    .setDecimalPrecision(0)
    .moveTo(openingShapeGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderOpeningRotation);

  // 统一底部留白（最后控件高度 20）
  int lastOpeningTop = yOpeningPos;
  openingShapeGroup.setBackgroundHeight((int)(lastOpeningTop + 20 + UI_GROUP_GAP));
  yPos += openingShapeGroup.getBackgroundHeight() + UI_GROUP_GAP;

  // 扭转渐变叠波组
  twistModGroup = cp5.addGroup("Twist Mod")
    .setPosition(20, yPos)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(140)
    .setLabel("Twist Mod");

  int yTwistPos = 10;

  sliderTwistGradient = cp5.addSlider("Twist Gradient (deg/step)")
    .setPosition(10, yTwistPos)
    .setSize(200, 20)
    .setRange(-1.0f, 1.0f)
    .setValue(degrees(twistGradient))
    .setDecimalPrecision(2)
    .moveTo(twistModGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderTwistGradient);

  yTwistPos += yStep;

  sliderTwistWaveAmplitude = cp5.addSlider("Twist Wave Amp (deg)")
    .setPosition(10, yTwistPos)
    .setSize(200, 20)
    .setRange(0, 10.0f)
    .setValue(degrees(twistWaveAmplitude))
    .setDecimalPrecision(2)
    .moveTo(twistModGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderTwistWaveAmplitude);

  yTwistPos += yStep;

  sliderTwistWaveFrequency = cp5.addSlider("Twist Wave Freq")
    .setPosition(10, yTwistPos)
    .setSize(200, 20)
    .setRange(0, 2.0f)
    .setValue(twistWaveFrequency)
    .setDecimalPrecision(2)
    .moveTo(twistModGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderTwistWaveFrequency);

  yTwistPos += yStep;

  sliderTwistWavePhase = cp5.addSlider("Twist Wave Phase")
    .setPosition(10, yTwistPos)
    .setSize(200, 20)
    .setRange(0, TWO_PI)
    .setValue(twistWavePhase)
    .setDecimalPrecision(2)
    .moveTo(twistModGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderTwistWavePhase);

  // 统一底部留白（最后控件高度 20）
  int lastTwistTop = yTwistPos;
  twistModGroup.setBackgroundHeight((int)(lastTwistTop + 20 + UI_GROUP_GAP));
  yPos += twistModGroup.getBackgroundHeight() + UI_GROUP_GAP;

  // 显示/绘图组
  displayGroup = cp5.addGroup("Display")
    .setPosition(20, yPos)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(100)
    .setLabel("Display");

  int yDisplayPos = 10;

  int displayColWidth = (int)((parametersGroup.getWidth() - 20 - UI_BUTTON_GAP) / 2);
  int displayLeftX = 10;
  int displayRightX = 10 + displayColWidth + UI_BUTTON_GAP;

  toggleGradientBackground = cp5.addToggle("Gradient Background")
    .setPosition(displayLeftX, yDisplayPos)
    .setSize(20, 20) // 方形样式
    .setValue(useGradientBackground)
    .setCaptionLabel("Gradient Background")
    .moveTo(displayGroup)
    .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        useGradientBackground = event.getController().getValue() > 0.5f;
        gradientNeedsUpdate = true;
      }
    });
  toggleGradientBackground.getCaptionLabel()
    .align(ControlP5.LEFT, ControlP5.CENTER)
    .setPadding((int)(toggleGradientBackground.getWidth() + 6), 0); // 文本放到方形右侧

  // 交换右侧：第一行显示 Twist Mod 开关
  toggleTwistMod = cp5.addToggle("TwistModEnabled")
    .setPosition(displayRightX, yDisplayPos)
    .setSize(20, 20)
    .setValue(twistModEnabled)
    .setCaptionLabel("Enable Twist Mod")
    .moveTo(displayGroup)
    .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        twistModEnabled = event.getController().getValue() > 0.5f;
      }
    });
  toggleTwistMod.getCaptionLabel()
    .align(ControlP5.LEFT, ControlP5.CENTER)
    .setPadding((int)(toggleTwistMod.getWidth() + 6), 0);

  yDisplayPos += yStep;

  // 第二行：左侧显示扭转图开关，右侧摄像机信息
  toggleShowTwistPlot = cp5.addToggle("ShowTwistPlot")
    .setPosition(displayLeftX, yDisplayPos)
    .setSize(20, 20) // 方形样式
    .setValue(showTwistPlot2D)
    .setCaptionLabel("Show Twist Plot")
    .moveTo(displayGroup)
    .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        showTwistPlot2D = event.getController().getValue() > 0.5f;
      }
    });
  toggleShowTwistPlot.getCaptionLabel()
    .align(ControlP5.LEFT, ControlP5.CENTER)
    .setPadding((int)(toggleShowTwistPlot.getWidth() + 6), 0); // 文本放到方形右侧

  toggleShowCameraInfo = cp5.addToggle("ShowCameraInfo")
    .setPosition(displayRightX, yDisplayPos)
    .setSize(20, 20) // 方形样式
    .setValue(showCameraInfo)
    .setCaptionLabel("Show Camera Info")
    .moveTo(displayGroup)
    .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        showCameraInfo = event.getController().getValue() > 0.5f;
      }
    });
  toggleShowCameraInfo.getCaptionLabel()
    .align(ControlP5.LEFT, ControlP5.CENTER)
    .setPadding((int)(toggleShowCameraInfo.getWidth() + 6), 0); // 文本放到方形右侧

  yDisplayPos += yStep;

  // 第三行：螺线开关（左侧）
  toggleSpiralOverlay = cp5.addToggle("ShowSpiralOverlay")
    .setPosition(displayLeftX, yDisplayPos)
    .setSize(20, 20)
    .setValue(showSpiralOverlay)
    .setCaptionLabel("Show Spiral Overlay")
    .moveTo(displayGroup)
    .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        showSpiralOverlay = event.getController().getValue() > 0.5f;
      }
    });
  toggleSpiralOverlay.getCaptionLabel()
    .align(ControlP5.LEFT, ControlP5.CENTER)
    .setPadding((int)(toggleSpiralOverlay.getWidth() + 6), 0);

  // 统一底部留白（最后控件高度 20）
  int lastDisplayTop = yDisplayPos;
  displayGroup.setBackgroundHeight((int)(lastDisplayTop + 20 + UI_GROUP_GAP));
  yPos += displayGroup.getBackgroundHeight() + UI_GROUP_GAP;

  // 创建导出组
  exportGroup = cp5.addGroup("Export")
    .setPosition(20, yPos)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(140)
    .setLabel("Export");

  int yExportPos = 10;

  sliderThickness = cp5.addSlider("Thickness")
    .setPosition(10, yExportPos)
    .setSize(200, 20)
    .setRange(0, 50)
    .setValue(1)
    .setDecimalPrecision(0)
    .moveTo(exportGroup)
    .onRelease(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        saveState();
        isSliderDragging = false;
      }
    })
    .onPress(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        isSliderDragging = true;
      }
    });
  registerSlider(sliderThickness);

  yExportPos += yStep;

  // Export按钮：根据 Parameters 组宽度拆分为同一行的两列
  int exportButtonsWidth = (int)((parametersGroup.getWidth() - 20 - UI_BUTTON_GAP) / 2);
  int exportButtonsY = yExportPos;

  cp5.addButton("ExportSTL")
    .setPosition(10, exportButtonsY)
    .setSize(exportButtonsWidth, 30)
    .setLabel("Export STL")
    .moveTo(exportGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        export3DModel();
      }
    });

  cp5.addButton("ExportPlotPNG")
    .setPosition(10 + exportButtonsWidth + UI_BUTTON_GAP, exportButtonsY)
    .setSize(exportButtonsWidth, 30)
    .setLabel("Export Plot PNG (2x)")
    .moveTo(exportGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        exportTwistAnglePlotPNG2x();
      }
    });

  // 为底部留白做准备
  yExportPos = exportButtonsY + 30;
  exportGroup.setBackgroundHeight((int)(yExportPos + UI_GROUP_GAP));

  setupSliderInputField();

  // 在所有界面元素创建完成后，将下拉菜单置于最顶层
  dropdownParameterSets.bringToFront();
  parametersGroup.bringToFront();
  dropdownParameterSets.bringToFront();  // 再次调用确保它在参数组之上
}

void drawInterface() {
  enforceSliderInputCleanState();
  cp5.draw();
}

void drawCameraInfo() {
  if (!showCameraInfo) {
    return;
  }
  // 在左下角显示摄像机视角、平移和缩放数值
  pushStyle();
  textAlign(LEFT, TOP);
  textSize(12);

  String[] lines = {
    "rotX: " + nf(degrees(rotX), 0, 1) + " deg",
    "rotY: " + nf(degrees(rotY), 0, 1) + " deg",
    "pan:  (" + nf(panX, 0, 1) + ", " + nf(panY, 0, 1) + ")",
    "zoom: " + nf(zoom, 0, 2)
  };

  int padding = 8;
  int lineH = 16;
  float boxW = 160; // 固定宽度
  float boxH = 80;
  float x = 20; // 与左侧 UI 对齐
  float y = height - boxH - 20;

  noStroke();
  fill(0, 110); // 稍高对比度，提高清晰度
  rect(x, y, boxW, boxH, 6); // 略带圆角

  fill(255);
  for (int i = 0; i < lines.length; i++) {
    text(lines[i], x + padding, y + padding + i * lineH);
  }

  popStyle();
}

void updateParametersFromSliders() {
  int desiredVertexCount = int(round(sliderVertexCount.getValue()));
  if (desiredVertexCount != vertexCount) {
    setVertexCount(desiredVertexCount);
  }

  numberOfStepGrowth = round(sliderGrowthStep.getValue());
  if (sliderGrowthRate != null) {
    growthRate = sliderGrowthRate.getValue();
  }
  bendAngle = 0.005f * round(sliderBendAngle.getValue());
  twistAngle = 0.001f * round(sliderTwistAngle.getValue());
  initGVL = 0.025f * round(sliderConeHight.getValue());
  initSVL = 0.1f * round(sliderConeWidth.getValue());
  sideShift = 0.01f * round(sliderSideShift.getValue());
  shellThickness = 0.1f * round(sliderThickness.getValue());
  openingFlatten = sliderOpeningFlatten.getValue();
  openingRotationDeg = round(sliderOpeningRotation.getValue());
  if (sliderTwistGradient != null) {
    twistGradient = radians(sliderTwistGradient.getValue());
  }
  if (sliderTwistWaveAmplitude != null) {
    twistWaveAmplitude = radians(sliderTwistWaveAmplitude.getValue());
  }
  if (sliderTwistWaveFrequency != null) {
    twistWaveFrequency = sliderTwistWaveFrequency.getValue();
  }
  if (sliderTwistWavePhase != null) {
    twistWavePhase = sliderTwistWavePhase.getValue();
  }
}

void updateSliders() {
  if (sliderVertexCount != null) {
    sliderVertexCount.setValue(vertexCount);
  }
  sliderGrowthStep.setValue(round(numberOfStepGrowth));
  if (sliderGrowthRate != null) {
    sliderGrowthRate.setValue(growthRate);
  }
  sliderBendAngle.setValue(round(bendAngle * 200));
  sliderTwistAngle.setValue(round(twistAngle * 1000));
  sliderConeHight.setValue(round(initGVL * 40));
  sliderConeWidth.setValue(round(initSVL * 10));
  sliderSideShift.setValue(round(sideShift * 100));
  sliderThickness.setValue(round(shellThickness * 10));
  sliderOpeningFlatten.setValue(openingFlatten);
  sliderOpeningRotation.setValue(round(openingRotationDeg));
  if (sliderTwistGradient != null) {
    sliderTwistGradient.setValue(degrees(twistGradient));
  }
  if (sliderTwistWaveAmplitude != null) {
    sliderTwistWaveAmplitude.setValue(degrees(twistWaveAmplitude));
  }
  if (sliderTwistWaveFrequency != null) {
    sliderTwistWaveFrequency.setValue(twistWaveFrequency);
  }
  if (sliderTwistWavePhase != null) {
    sliderTwistWavePhase.setValue(twistWavePhase);
  }
}

void updateDropdownParameterSets() {
    dropdownParameterSets.clear();
    for (int i = 0; i < parameterSets.size(); i++) {
        dropdownParameterSets.addItem("Parameter Set " + (i + 1), i);
    }
    
    // 如果当前是新参数状态，显示"New Parameter"
    if (currentParameterSetIndex == -1) {
        cp5.getController("Parameter Sets").setCaptionLabel("New Parameter");
    }
}

void setupSliderInputField() {
  sliderInputField = cp5.addTextfield("SliderInputField")
    .setPosition(-10000, -10000)
    .setSize(80, 22)
    .setAutoClear(false)
    .setInputFilter(ControlP5Constants.FLOAT)
    .setVisible(false);
  sliderInputField.getCaptionLabel().setVisible(false);
}

boolean isSliderInputActive() {
  return sliderInputField != null && sliderInputField.isVisible();
}

boolean isMouseOverSliderInputField() {
  if (!isSliderInputActive()) {
    return false;
  }
  float[] pos = sliderInputField.getAbsolutePosition();
  float sx = pos[0];
  float sy = pos[1];
  return mouseX >= sx && mouseX <= sx + sliderInputField.getWidth() &&
         mouseY >= sy && mouseY <= sy + sliderInputField.getHeight();
}

boolean tryStartSliderInput() {
  if (sliderInputField == null) {
    return false;
  }

  for (Slider slider : allSliders) {
    if (slider == null || !slider.isVisible()) {
      continue;
    }

    float[] pos = slider.getAbsolutePosition();
    float sx = pos[0];
    float sy = pos[1];
    if (mouseX >= sx && mouseX <= sx + slider.getWidth() && mouseY >= sy && mouseY <= sy + slider.getHeight()) {
      beginSliderInput(slider);
      return true;
    }
  }

  return false;
}

void beginSliderInput(Slider slider) {
  sliderBeingEdited = slider;
  isSliderDragging = false;
  float[] pos = slider.getAbsolutePosition();
  sliderInputField.setPosition(pos[0], pos[1]);
  sliderInputField.setSize(slider.getWidth(), slider.getHeight());
  sliderInputField.setText(nf(slider.getValue(), 0, slider.getDecimalPrecision()));
  sliderInputPrimed = true;
  slider.hide();

  sliderInputField.setVisible(true);
  sliderInputField.bringToFront();
  sliderInputField.setFocus(true);
}

void commitSliderInput() {
  if (sliderBeingEdited == null) {
    closeSliderInput();
    return;
  }

  float typedValue = parseFloat(sliderInputField.getText());
  if (!Float.isNaN(typedValue)) {
    int precision = sliderBeingEdited.getDecimalPrecision();
    if (precision > 0) {
      float factor = pow(10, precision);
      typedValue = round(typedValue * factor) / factor;
    } else {
      typedValue = round(typedValue);
    }
    typedValue = constrain(typedValue, sliderBeingEdited.getMin(), sliderBeingEdited.getMax());
    sliderBeingEdited.setValue(typedValue);
    saveState();
  }

  closeSliderInput();
}

void cancelSliderInput() {
  closeSliderInput();
}

void closeSliderInput() {
  if (sliderBeingEdited != null) {
    sliderBeingEdited.show();
  }

  sliderBeingEdited = null;
  sliderInputField.setVisible(false);
  sliderInputField.setFocus(false);
  sliderInputField.keepFocus(false);
  sliderInputField.clear();
  sliderInputField.setPosition(-10000, -10000); // move offscreen to avoid blocking clicks
  isSliderDragging = false;
  sliderInputPrimed = false;

  // 兜底：确保所有滑块回到可见状态
  for (Slider s : allSliders) {
    if (s != null) {
      s.show();
    }
  }
}

// 防御：偶发情况下 Textfield 可能保持焦点或可见，导致其它 slider 被“锁”。 
void enforceSliderInputCleanState() {
  if (sliderInputField == null) {
    return;
  }

  boolean visibleWithoutTarget = sliderInputField.isVisible() && sliderBeingEdited == null;
  boolean hiddenButFocused = !sliderInputField.isVisible() && sliderInputField.isFocus();
  if (visibleWithoutTarget || hiddenButFocused) {
    closeSliderInput();
  }

  // 兜底：确保所有滑块可见，避免偶发隐藏后无法交互
  for (Slider s : allSliders) {
    if (s != null && !s.isVisible()) {
      s.show();
    }
  }
}
