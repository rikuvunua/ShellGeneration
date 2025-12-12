ControlP5 cp5;
RadioButton radio;
Slider sliderVertexCount, sliderGrowthStep, sliderGrowthRate, sliderBendAngle, sliderTwistAngle, sliderConeHight, sliderConeWidth, sliderSideShift, sliderThickness;
Slider sliderOpeningFlatten, sliderOpeningRotation;
Slider sliderTwistGradient, sliderTwistWaveAmplitude, sliderTwistWaveFrequency, sliderTwistWavePhase;
Button resetButton, undoButton, redoButton;
Toggle toggleGradientBackground;

DropdownList dropdownParameterSets;

Group parametersGroup, openingShapeGroup, twistModGroup, exportGroup;

// UI state
boolean isSliderDragging = false;

void setupInterface() {
  // 创建参数组
  parametersGroup = cp5.addGroup("Parameters")
    .setPosition(20, 25)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(460)
    .setLabel("Parameters");

  int yPos = 10;
  int yStep = 30;

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
  yPos += yStep;

  // 添加所有滑块
  sliderGrowthStep = cp5.addSlider("Growth Steps")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(0, 100)
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
  yPos += yStep;

  sliderGrowthRate = cp5.addSlider("Growth Rate")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(1.0f, 1.05f)
    .setValue(growthRate)
    .setDecimalPrecision(3)
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
  yPos += yStep;

  sliderBendAngle = cp5.addSlider("Bending Angle")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(0, 100)
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
  yPos += yStep;

  sliderTwistAngle = cp5.addSlider("Twisting Angle")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(0, 200)
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
  yPos += yStep;

  sliderConeHight = cp5.addSlider("Cone Height")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(0, 100)
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
  yPos += yStep;

  sliderConeWidth = cp5.addSlider("Cone Width")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(20, 80)
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
  yPos += yStep;

  sliderSideShift = cp5.addSlider("Side Shift")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(-100, 100)
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
  yPos += yStep;

  toggleGradientBackground = cp5.addToggle("Gradient Background")
    .setPosition(10, yPos)
    .setSize(20, 20)
    .setValue(useGradientBackground)
    .setMode(ControlP5.SWITCH)
    .setCaptionLabel("Gradient Background")
    .moveTo(parametersGroup)
    .onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        useGradientBackground = event.getController().getValue() > 0.5f;
        gradientNeedsUpdate = true;
      }
    });
  yPos += yStep;

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
    .activate(0)
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

  // 开口形状控制组
  yPos += 85;
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

  yOpeningPos += yStep;

  sliderOpeningRotation = cp5.addSlider("Opening Rotation")
    .setPosition(10, yOpeningPos)
    .setSize(200, 20)
    .setRange(-180, 180)
    .setValue(openingRotationDeg)
    .setDecimalPrecision(1)
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

  yPos += openingShapeGroup.getBackgroundHeight() + 20;

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
    .setDecimalPrecision(3)
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

  yTwistPos += yStep;

  sliderTwistWaveAmplitude = cp5.addSlider("Twist Wave Amp (deg)")
    .setPosition(10, yTwistPos)
    .setSize(200, 20)
    .setRange(0, 10.0f)
    .setValue(degrees(twistWaveAmplitude))
    .setDecimalPrecision(3)
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

  yTwistPos += yStep;

  sliderTwistWaveFrequency = cp5.addSlider("Twist Wave Freq")
    .setPosition(10, yTwistPos)
    .setSize(200, 20)
    .setRange(0, 2.0f)
    .setValue(twistWaveFrequency)
    .setDecimalPrecision(3)
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

  yTwistPos += yStep;

  sliderTwistWavePhase = cp5.addSlider("Twist Wave Phase")
    .setPosition(10, yTwistPos)
    .setSize(200, 20)
    .setRange(0, TWO_PI)
    .setValue(twistWavePhase)
    .setDecimalPrecision(3)
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

  yPos += twistModGroup.getBackgroundHeight() + 20;

  // 创建导出组
  exportGroup = cp5.addGroup("Export")
    .setPosition(20, yPos)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(90)
    .setLabel("Export");

  int yExportPos = 10;

  sliderThickness = cp5.addSlider("Thickness")
    .setPosition(10, yExportPos)
    .setSize(200, 20)
    .setRange(0, 50)
    .setValue(1)
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

  yExportPos += yStep;

  // Export按钮
  cp5.addButton("ExportSTL")
    .setPosition(10, yExportPos)
    .setSize(200, 30)
    .setLabel("Export STL")
    .moveTo(exportGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        export3DModel();
      }
    });

  // 在所有界面元素创建完成后，将下拉菜单置于最顶层
  dropdownParameterSets.bringToFront();
  parametersGroup.bringToFront();
  dropdownParameterSets.bringToFront();  // 再次调用确保它在参数组之上
}

void drawInterface() {
  cp5.draw();
}

void updateParametersFromSliders() {
  int desiredVertexCount = int(round(sliderVertexCount.getValue()));
  if (desiredVertexCount != vertexCount) {
    setVertexCount(desiredVertexCount);
  }

  numberOfStepGrowth = (int)sliderGrowthStep.getValue();
  if (sliderGrowthRate != null) {
    growthRate = sliderGrowthRate.getValue();
  }
  bendAngle = 0.005f * sliderBendAngle.getValue();
  twistAngle = 0.001f * sliderTwistAngle.getValue();
  initGVL = 0.025f * sliderConeHight.getValue();
  initSVL = 0.1f * sliderConeWidth.getValue();
  sideShift = 0.01f * sliderSideShift.getValue();
  shellThickness = 0.1f * sliderThickness.getValue();
  openingFlatten = sliderOpeningFlatten.getValue();
  openingRotationDeg = sliderOpeningRotation.getValue();
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
  sliderGrowthStep.setValue(numberOfStepGrowth);
  if (sliderGrowthRate != null) {
    sliderGrowthRate.setValue(growthRate);
  }
  sliderBendAngle.setValue(bendAngle * 200);
  sliderTwistAngle.setValue(twistAngle * 1000);
  sliderConeHight.setValue(initGVL * 40);
  sliderConeWidth.setValue(initSVL * 10);
  sliderSideShift.setValue(sideShift * 100);
  sliderThickness.setValue(shellThickness * 10);
  sliderOpeningFlatten.setValue(openingFlatten);
  sliderOpeningRotation.setValue(openingRotationDeg);
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
