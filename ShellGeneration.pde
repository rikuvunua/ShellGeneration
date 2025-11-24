import controlP5.*;
import processing.data.XML;
import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import processing.serial.*;
import processing.opengl.*;

ControlP5 cp5;
RadioButton radio;
Slider sliderVertexCount, sliderGrowthStep, sliderBendAngle, sliderTwistAngle, sliderConeHight, sliderConeWidth, sliderSideShift, sliderThickness;
Button resetButton, undoButton, redoButton;
CheckBox checkboxReferenceVectors, checkboxMotherCurve;

DropdownList dropdownParameterSets;

Group parametersGroup, exportGroup;

float rotX = 0;
float rotY = 0;
float lastMouseX, lastMouseY;
float zoom = 1;
boolean isDragging = false;
boolean isPanning = false;
float panX = 0;
float panY = 0;
boolean isDraggingControlVertex = false;

int numberOfStepGrowth = 50;
float bendAngle = 0.3f;
float twistAngle = 0.05f;
float initGVL = 1.5f;
float initSVL = 3f;
float sideShift = 0;
float growthRate = 1.03f;
float shellThickness = 1.0f;  // 默认厚度

// 顶点数量控制（默认 12，可扩展）
static final int MIN_VERTEX_COUNT = 12;
static final int MAX_VERTEX_COUNT = 36;
int vertexCount = MIN_VERTEX_COUNT;

PVector[] shape;
PVector[][] rings;
PVector[][] ringsOuter;
PVector[][] ringsInner;
PVector[][] outerNormals;
PVector[][] innerNormals;
float[] GVLength = new float[100];
float[] SVLength = new float[100];
PVector[] normGV = new PVector[100];
PVector[] normSV = new PVector[100];
PVector[] GV = new PVector[100];
PVector[] SV = new PVector[100];
PVector[] CV = new PVector[100];

PVector[] controlVertices;
boolean[] dragging;

ArrayList<PVector> exportVertices;
ArrayList<int[]> exportFaces;

ArrayList<ShellState> undoStack = new ArrayList<ShellState>();
ArrayList<ShellState> redoStack = new ArrayList<ShellState>();
int maxUndoSteps = 10;
boolean isUndoingOrRedoing = false;  // 防止在撤销/重做时重复记录状态

// 用于跟踪滑块是否正在被拖动
boolean isSliderDragging = false;

boolean showGrowthVectors = false;
boolean showMotherCurve = false;

// 参数集列表
ArrayList<ParameterSet> parameterSets = new ArrayList<ParameterSet>();
int currentParameterSetIndex = 0;

float autoRotateSpeed = -0.003; // 负值表示逆时针旋转
boolean isAutoRotating = false; // 控制是否自动旋转

// 添加115200串口支持
Serial controlPort;  // 115200串口对象
String controlData = "";  // 存储控制数据

PShader shellShader;
int backgroundTopColor;
int backgroundBottomColor;
PImage backgroundGradient;
boolean gradientNeedsUpdate = true;

void setup() {
  fullScreen(P3D);
  shellShader = loadShader("shellFrag.glsl", "shellVert.glsl");
  configureShellShader();
  backgroundTopColor = color(0x19, 0x19, 0x19);
  backgroundBottomColor = color(0xbc, 0xe1, 0xe7);
  gradientNeedsUpdate = true;
  
  // 初始化115200控制串口
  println("Available serial ports:");
  printArray(Serial.list());  // 打印所有可用串口
  try {
    if (Serial.list().length > 5) {
      String controlPortName = Serial.list()[5];  // 使用第5个端口作为控制端口
      controlPort = new Serial(this, controlPortName, 115200);
      println("Connected to control port: " + controlPortName);
    } else {
      println("Not enough serial ports available for control");
    }
  } catch (Exception e) {
    println("Error connecting to control serial port:");
    println(e.getMessage());
  }
  
  cp5 = new ControlP5(this);
  
  initializeShapesAndRings(); // 确保在调用任何用 shape 的方法之前初始化它
  setupInterface();           // 初始化界面控件
  setupControlVertices();     // 初始化控制顶点
  loadParametersFromXML();    // 加载参数集
  updateDropdownParameterSets(); // 更新下拉列表
  resetVectors();             // 置向量
  saveState();                // 保存初始状态

  rotX = radians(-17.5);
  rotY = radians(0);
  panX = 35;
  panY = -375;
  zoom = 5.5;
}

void draw() {
  // 处理115200串口控制数据
  while (controlPort != null && controlPort.available() > 0) {
    String inString = controlPort.readStringUntil('\n');
    if (inString != null) {
      controlData = trim(inString);
      println("Control Data Received: " + controlData);
      
      // 解析控制数据 "bending,twisting,coneWidth"
      String[] values = split(controlData, ',');
      if (values.length == 3) {
        try {
          int bendingDelta = int(values[0]);
          int twistingDelta = int(values[1]);
          int coneWidthDelta = int(values[2]);
          
          // 应用增量控制
          applyIncrementalControl(bendingDelta, twistingDelta, coneWidthDelta);
          
        } catch (NumberFormatException e) {
          println("Error parsing control data: " + controlData);
        }
      }
    }
  }

  drawBackgroundGradient();
  
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

  if (radio.getValue() == 1) {
    drawOpenRings();
  } else if (radio.getValue() == 2) {  // Show Shell Surface
    drawWireSurface();  // 现在显示线框表面
  } else {  // Show Surface (值为3)
    if (shellShader != null) {
      shader(shellShader);
      drawSurface();      // 现在显示实体表面
      resetShader();
    } else {
      drawSurface();
    }
  }

  boolean shouldDrawVectors = showGrowthVectors;
  boolean shouldDrawMotherCurve = showMotherCurve;
  if (shouldDrawVectors || shouldDrawMotherCurve) {
    hint(DISABLE_DEPTH_TEST);
    if (shouldDrawMotherCurve) {
      drawCenter();
    }
    if (shouldDrawVectors) {
      drawReferenceVectors();
    }
    hint(ENABLE_DEPTH_TEST);
  }
  popMatrix();

  drawInterface();
  drawControlInterface();
  updateShapeFromControlVertices();
  
  // 显示串口状态信息
  drawSerialStatus();
}

void controlEvent(ControlEvent event) {
  if (checkboxReferenceVectors != null && event.isFrom(checkboxReferenceVectors)) {
    updateReferenceVisibility();
  }
  if (checkboxMotherCurve != null && event.isFrom(checkboxMotherCurve)) {
    updateMotherCurveVisibility();
  }
}

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

  isDraggingControlVertex = false;
  for (int i = 0; i < controlVertices.length; i++) {
    if (dist(mouseX, mouseY, controlVertices[i].x, controlVertices[i].y) < 10) {
      dragging[i] = true;
      isDraggingControlVertex = true;
    }
  }
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

  for (int i = 0; i < controlVertices.length; i++) {
    if (dragging[i]) {
      controlVertices[i].set(mouseX, mouseY);
    }
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
  sliderGrowthStep = cp5.addSlider("Growth")
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

  sliderBendAngle = cp5.addSlider("Bending Angle")
    .setPosition(10, yPos)
    .setSize(200, 20)
    .setRange(-100, 100)
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
    .setRange(-200, 200)
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
    .setRange(0, 100)
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

  checkboxReferenceVectors = cp5.addCheckBox("Reference Vectors")
    .setPosition(10, yPos)
    .setSize(18, 18)
    .setItemsPerRow(1)
    .setSpacingRow(6)
    .setSpacingColumn(100)
    .addItem("Growth Vector", 0)
    .moveTo(parametersGroup);
  checkboxReferenceVectors.deactivateAll();
  updateReferenceVisibility();
  checkboxMotherCurve = cp5.addCheckBox("Mother Curve Toggle")
    .setPosition(150, yPos)
    .setSize(18, 18)
    .setItemsPerRow(1)
    .setSpacingRow(6)
    .setSpacingColumn(100)
    .addItem("Mother Curve", 0)
    .moveTo(parametersGroup);
  checkboxMotherCurve.deactivateAll();
  updateMotherCurveVisibility();
  yPos += yStep;

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

  yPos += yStep + 75;

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
  cp5.addButton("ExportOBJ")
    .setPosition(10, yExportPos)
    .setSize(200, 30)
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

void resetParameters() {
    // 重置所有参数为指定的默认值
    setVertexCount(MIN_VERTEX_COUNT, false);
    numberOfStepGrowth = 50;
    bendAngle = 0.3;  // 60/200 因为界面值要除以200
    twistAngle = 0.05;  // 50/1000 因为界面值要除以1000
    initGVL = 1.5;  // 60/40 因为界面值要除以40
    initSVL = 3.0;  // 30/10 因为界面值要除以10
    sideShift = 0;
    shellThickness = 1;
    
    // 重置当前参数集索引
    currentParameterSetIndex = -1;
    
    // 更新滑块显示
    if (sliderVertexCount != null) {
        sliderVertexCount.setValue(vertexCount);
    }
    sliderGrowthStep.setValue(50);  // Growth
    sliderBendAngle.setValue(60);   // Bending Angle
    sliderTwistAngle.setValue(50);  // Twisting Angle
    sliderConeHight.setValue(60);   // Cone Height
    sliderConeWidth.setValue(30);   // Cone Width
    sliderSideShift.setValue(0);    // Side Shift
    sliderThickness.setValue(1);    // Thickness
    
    // 设置下拉菜单显示"New Parameter"
    cp5.getController("Parameter Sets").setCaptionLabel("New Parameter");
    
    // 重置向量
    resetVectors();
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

// 修改drawCenter方法来显示中心线
void drawCenter() {
  float strokeWeightValue = max(1.0f, 1.8f / zoom); // 保持缩放一致的线条宽度
  
  // 绘制原始生长路径
  stroke(220, 60, 60);  // 红色显示母曲线
  strokeWeight(strokeWeightValue);
  int ringCount = getVisibleRingCount();
  for (int i = 0; i < ringCount - 1; i++) {
    connectVector(CV[i], CV[i + 1]);
  }
}

void drawReferenceVectors() {
  if (!showGrowthVectors) {
    return;
  }

  float lineStroke = max(1.0f, 2.0f / zoom);
  float arrowHeadSize = max(4.0f, 8.0f / zoom);
  int growthColor = color(70, 140, 255);

  int ringCount = getVisibleRingCount();
  for (int i = 0; i < ringCount; i++) {
    PVector center = CV[i];
    if (center == null) {
      continue;
    }

    PVector direction = normGV[i];
    float magnitude = GVLength[i];
    drawVectorArrow(center, direction, magnitude, growthColor, lineStroke, arrowHeadSize);
  }

  strokeWeight(1);
}

void drawVectorArrow(PVector origin, PVector direction, float magnitude, int colorValue, float lineStroke, float arrowHeadSize) {
  if (direction == null) {
    return;
  }

  PVector dir = direction.copy();
  if (dir.magSq() < 1e-6f) {
    return;
  }

  dir.normalize();
  float length = max(5f, min(60f, magnitude * 1.25f));
  PVector end = PVector.add(origin, PVector.mult(dir, length));

  stroke(colorValue);
  strokeWeight(lineStroke);
  line(origin.x, origin.y, origin.z, end.x, end.y, end.z);

  // draw arrowhead (two short lines forming a V)
  PVector reference = new PVector(0, 0, 1);
  PVector perpendicular = dir.cross(reference);
  if (perpendicular.magSq() < 1e-6f) {
    reference.set(0, 1, 0);
    perpendicular = dir.cross(reference);
  }
  perpendicular.normalize();
  PVector side = PVector.mult(perpendicular, arrowHeadSize * 0.6f);
  PVector back = PVector.mult(dir, -arrowHeadSize);
  PVector left = PVector.add(end, PVector.add(back, side));
  PVector right = PVector.add(end, PVector.sub(back, side));

  line(end.x, end.y, end.z, left.x, left.y, left.z);
  line(end.x, end.y, end.z, right.x, right.y, right.z);
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
  noStroke();
  fill(248, 246, 242);

  // 绘制外表面
  if (shellShader != null) {
    shellShader.set("uInteriorFactor", 0.0f);
  }
  for (int i = 0; i < ringCount - 1; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector outer00 = getAnimatedOuterPoint(i, j);
      PVector outer10 = getAnimatedOuterPoint(i + 1, j);
      PVector outer11 = getAnimatedOuterPoint(i + 1, nextJ);
      PVector outer01 = getAnimatedOuterPoint(i, nextJ);
      beginShape(QUADS);
      emitVertexWithNormal(outer00, outerNormals[i][j]);
      emitVertexWithNormal(outer10, outerNormals[i + 1][j]);
      emitVertexWithNormal(outer11, outerNormals[i + 1][nextJ]);
      emitVertexWithNormal(outer01, outerNormals[i][nextJ]);
      endShape(CLOSE);
    }
  }

  // 绘制内表面
  if (shellShader != null) {
    shellShader.set("uInteriorFactor", 1.0f);
  }
  for (int i = 0; i < ringCount - 1; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector inner00 = getAnimatedInnerPoint(i, j);
      PVector inner01 = getAnimatedInnerPoint(i, nextJ);
      PVector inner11 = getAnimatedInnerPoint(i + 1, nextJ);
      PVector inner10 = getAnimatedInnerPoint(i + 1, j);
      beginShape(QUADS);
      emitVertexWithNormal(inner00, innerNormals[i][j]);
      emitVertexWithNormal(inner01, innerNormals[i][nextJ]);
      emitVertexWithNormal(inner11, innerNormals[i + 1][nextJ]);
      emitVertexWithNormal(inner10, innerNormals[i + 1][j]);
      endShape(CLOSE);
    }
  }

  // 绘制侧面
  if (shellShader != null) {
    shellShader.set("uInteriorFactor", 0.35f);
  }
  for (int i = 0; i < ringCount; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;
      PVector n0 = computeSideNormal(i, j);
      PVector n1 = computeSideNormal(i, nextJ);
      PVector outer0 = getAnimatedOuterPoint(i, j);
      PVector outer1 = getAnimatedOuterPoint(i, nextJ);
      PVector inner1 = getAnimatedInnerPoint(i, nextJ);
      PVector inner0 = getAnimatedInnerPoint(i, j);
      beginShape(QUADS);
      emitVertexWithNormal(outer0, n0);
      emitVertexWithNormal(outer1, n1);
      emitVertexWithNormal(inner1, n1);
      emitVertexWithNormal(inner0, n0);
      endShape(CLOSE);
    }
  }

  // 绘制首端面
  if (shellShader != null) {
    shellShader.set("uInteriorFactor", 0.55f);
  }
  PVector frontNormal = computeCapNormal(0, true);
  for (int j = 0; j < vertexCount; j++) {
    int nextJ = (j + 1) % vertexCount;
    PVector outer0 = getAnimatedOuterPoint(0, j);
    PVector outer1 = getAnimatedOuterPoint(0, nextJ);
    PVector inner1 = getAnimatedInnerPoint(0, nextJ);
    PVector inner0 = getAnimatedInnerPoint(0, j);
    beginShape(QUADS);
    emitVertexWithNormal(outer0, frontNormal);
    emitVertexWithNormal(outer1, frontNormal);
    emitVertexWithNormal(inner1, frontNormal);
    emitVertexWithNormal(inner0, frontNormal);
    endShape(CLOSE);
  }

  // 绘制尾端面
  int lastIndex = ringCount - 1;
  if (shellShader != null) {
    shellShader.set("uInteriorFactor", 0.45f);
  }
  PVector backNormal = computeCapNormal(lastIndex, false);
  for (int j = 0; j < vertexCount; j++) {
    int nextJ = (j + 1) % vertexCount;
    beginShape(QUADS);
    emitVertexWithNormal(getAnimatedOuterPoint(lastIndex, j), backNormal);
    emitVertexWithNormal(getAnimatedOuterPoint(lastIndex, nextJ), backNormal);
    emitVertexWithNormal(getAnimatedInnerPoint(lastIndex, nextJ), backNormal);
    emitVertexWithNormal(getAnimatedInnerPoint(lastIndex, j), backNormal);
    endShape(CLOSE);
  }

  popStyle();
}

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

void connectVector(PVector a, PVector b) {
  beginShape(LINES);
  vertex(a.x, a.y, a.z);
  vertex(b.x, b.y, b.z);
  endShape();
}

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

void updateShapeFromControlVertices() {
  PVector center = getControlCenter();
  for (int i = 0; i < controlVertices.length; i++) {
    PVector controlVertex = controlVertices[i];
    float distance = PVector.dist(controlVertex, center);
    shape[i].x = distance / 50; // 根据与中心的距离更新形状半径
    shape[i].y = atan2(controlVertex.y - center.y, controlVertex.x - center.x); // 根据控制顶点位置更新角度
  }
}

ParameterSet saveParametersToXML() {
  String filePath = sketchPath("assets/shell_parameters.xml");
  XML xml;
  
  // 检查XML文件是否存在
  File file = new File(filePath);
  if (file.exists()) {
    xml = loadXML(filePath);  // 加载现有的XML文件
    
    // 如果是更新现有参数集，直接更新对应位置的参数
    if (currentParameterSetIndex >= 0) {
      XML[] paramSets = xml.getChildren("ParameterSet");
      if (currentParameterSetIndex < paramSets.length) {
        // 获取要更新的参数集
        XML paramSet = paramSets[currentParameterSetIndex];
        
        // 清除原有的子节点
        for (XML child : paramSet.getChildren()) {
          paramSet.removeChild(child);
        }
        
        // 更新参数
        paramSet.addChild("VertexCount").setContent(Integer.toString(vertexCount));
        paramSet.addChild("NumberOfStepGrowth").setContent(Integer.toString(numberOfStepGrowth));
        paramSet.addChild("BendAngle").setContent(Float.toString(bendAngle));
        paramSet.addChild("TwistAngle").setContent(Float.toString(twistAngle));
        paramSet.addChild("InitGVL").setContent(Float.toString(initGVL));
        paramSet.addChild("InitSVL").setContent(Float.toString(initSVL));
        paramSet.addChild("SideShift").setContent(Float.toString(sideShift));
        paramSet.addChild("ShellThickness").setContent(Float.toString(shellThickness));

        // 更新控制顶点
        XML controlVerticesXML = paramSet.addChild("ControlVertices");
        for (int i = 0; i < controlVertices.length; i++) {
          XML vertexXML = controlVerticesXML.addChild("Vertex");
          vertexXML.addChild("X").setContent(Float.toString(controlVertices[i].x));
          vertexXML.addChild("Y").setContent(Float.toString(controlVertices[i].y));
        }
        
        saveXML(xml, filePath);
        
        // 更新内存中的参数集对象
        ParameterSet currentPS = parameterSets.get(currentParameterSetIndex);
        currentPS.vertexCount = vertexCount;
        currentPS.numberOfStepGrowth = numberOfStepGrowth;
        currentPS.bendAngle = bendAngle;
        currentPS.twistAngle = twistAngle;
        currentPS.initGVL = initGVL;
        currentPS.initSVL = initSVL;
        currentPS.sideShift = sideShift;
        currentPS.shellThickness = shellThickness;
        currentPS.controlVertices = new PVector[vertexCount];
        for (int i = 0; i < vertexCount; i++) {
          currentPS.controlVertices[i] = controlVertices[i].copy();
        }

        return currentPS;
      }
    }
  } else {
    xml = new XML("ShellParameters");  // 如果文件不存在，则创建新的XML根
  }

  // 如果是新建参数集，使用原来的逻辑
  XML paramSet = xml.addChild("ParameterSet");

  // 添加所有参数
  paramSet.addChild("VertexCount").setContent(Integer.toString(vertexCount));
  paramSet.addChild("NumberOfStepGrowth").setContent(Integer.toString(numberOfStepGrowth));
  paramSet.addChild("BendAngle").setContent(Float.toString(bendAngle));
  paramSet.addChild("TwistAngle").setContent(Float.toString(twistAngle));
  paramSet.addChild("InitGVL").setContent(Float.toString(initGVL));
  paramSet.addChild("InitSVL").setContent(Float.toString(initSVL));
  paramSet.addChild("SideShift").setContent(Float.toString(sideShift));
  paramSet.addChild("ShellThickness").setContent(Float.toString(shellThickness));

  // 添加控制顶点
  XML controlVerticesXML = paramSet.addChild("ControlVertices");
  for (int i = 0; i < controlVertices.length; i++) {
    XML vertexXML = controlVerticesXML.addChild("Vertex");
    vertexXML.addChild("X").setContent(Float.toString(controlVertices[i].x));
    vertexXML.addChild("Y").setContent(Float.toString(controlVertices[i].y));
  }
  
  // 保存XML文件
  saveXML(xml, filePath);

  // 创建新的ParameterSet对象
  ParameterSet newPS = new ParameterSet();
  newPS.name = "Parameter Set " + (parameterSets.size() + 1);
  newPS.vertexCount = vertexCount;
  newPS.numberOfStepGrowth = numberOfStepGrowth;
  newPS.bendAngle = bendAngle;
  newPS.twistAngle = twistAngle;
  newPS.initGVL = initGVL;
  newPS.initSVL = initSVL;
  newPS.sideShift = sideShift;
  newPS.shellThickness = shellThickness;
  newPS.controlVertices = new PVector[vertexCount];
  for (int i = 0; i < vertexCount; i++) {
    newPS.controlVertices[i] = controlVertices[i].copy();
  }
  
  return newPS;
}

void loadParametersFromXML() {
  String filePath = sketchPath("assets/shell_parameters.xml");
  File file = new File(filePath);
  if (file.exists()) {
    XML xml = loadXML(filePath);

    XML[] paramsSets = xml.getChildren("ParameterSet");
    if (paramsSets.length == 0) {
      return;
    }

    parameterSets.clear();

    int index = 1;
    for (XML params : paramsSets) {
      ParameterSet ps = new ParameterSet();
      ps.name = "Parameter Set " + index;

      if (params.getChild("NumberOfStepGrowth") != null) {
        ps.numberOfStepGrowth = Integer.parseInt(params.getChild("NumberOfStepGrowth").getContent());
      }

      if (params.getChild("BendAngle") != null) {
        ps.bendAngle = Float.parseFloat(params.getChild("BendAngle").getContent());
      }

      if (params.getChild("TwistAngle") != null) {
        ps.twistAngle = Float.parseFloat(params.getChild("TwistAngle").getContent());
      }

      if (params.getChild("InitGVL") != null) {
        ps.initGVL = Float.parseFloat(params.getChild("InitGVL").getContent());
      }

      if (params.getChild("InitSVL") != null) {
        ps.initSVL = Float.parseFloat(params.getChild("InitSVL").getContent());
      }

      if (params.getChild("SideShift") != null) {
        ps.sideShift = Float.parseFloat(params.getChild("SideShift").getContent());
      }

      if (params.getChild("ShellThickness") != null) {
        ps.shellThickness = Float.parseFloat(params.getChild("ShellThickness").getContent());
      }

      int loadedVertexCount = vertexCount;
      if (params.getChild("VertexCount") != null) {
        loadedVertexCount = constrain(Integer.parseInt(params.getChild("VertexCount").getContent()), MIN_VERTEX_COUNT, MAX_VERTEX_COUNT);
      }

      XML controlVerticesXML = params.getChild("ControlVertices");
      if (controlVerticesXML != null) {
        XML[] vertices = controlVerticesXML.getChildren("Vertex");
        PVector[] loadedVertices = new PVector[vertices.length];
        for (int i = 0; i < vertices.length; i++) {
          float x = Float.parseFloat(vertices[i].getChild("X").getContent());
          float y = Float.parseFloat(vertices[i].getChild("Y").getContent());
          loadedVertices[i] = new PVector(x, y);
        }

        if (loadedVertexCount <= 0) {
          loadedVertexCount = constrain(vertices.length, MIN_VERTEX_COUNT, MAX_VERTEX_COUNT);
        }

        if (loadedVertices.length == loadedVertexCount) {
          ps.controlVertices = loadedVertices;
        } else {
          ps.controlVertices = resampleControlVertices(loadedVertices, loadedVertexCount);
        }
      } else {
        loadedVertexCount = max(loadedVertexCount, MIN_VERTEX_COUNT);
        ps.controlVertices = createDefaultControlVertices(loadedVertexCount);
      }

      ps.vertexCount = ps.controlVertices != null ? ps.controlVertices.length : loadedVertexCount;
      
      parameterSets.add(ps);
      index++;
    }

    // 应用第一个参数集
    if (parameterSets.size() > 0) {
      applyParameterSet(parameterSets.get(0));
    }
  }
}

void updateSliders() {
  if (sliderVertexCount != null) {
    sliderVertexCount.setValue(vertexCount);
  }
  sliderGrowthStep.setValue(numberOfStepGrowth);
  sliderBendAngle.setValue(bendAngle * 200);
  sliderTwistAngle.setValue(twistAngle * 1000);
  sliderConeHight.setValue(initGVL * 40);
  sliderConeWidth.setValue(initSVL * 10);
  sliderSideShift.setValue(sideShift * 100);
  sliderThickness.setValue(shellThickness * 10);
}

void updateDropdownParameterSets() {
    dropdownParameterSets.clear();
    for (int i = 0; i < parameterSets.size(); i++) {
        dropdownParameterSets.addItem("Parameter Set " + (i + 1), i);
    }
    
    // 如果当前是新参数状态���显示"New Parameter"
    if (currentParameterSetIndex == -1) {
        cp5.getController("Parameter Sets").setCaptionLabel("New Parameter");
    }
}

void updateReferenceVisibility() {
  if (checkboxReferenceVectors == null) {
    showGrowthVectors = false;
    return;
  }

  Toggle item = checkboxReferenceVectors.getItem(0);
  showGrowthVectors = item != null && item.getState();
}

void updateMotherCurveVisibility() {
  if (checkboxMotherCurve == null) {
    showMotherCurve = false;
    return;
  }

  Toggle item = checkboxMotherCurve.getItem(0);
  showMotherCurve = item != null && item.getState();
}

void applyParameterSet(ParameterSet ps) {
  int desiredVertexCount = ps.vertexCount > 0 ? ps.vertexCount : (ps.controlVertices != null ? ps.controlVertices.length : vertexCount);
  desiredVertexCount = constrain(desiredVertexCount, MIN_VERTEX_COUNT, MAX_VERTEX_COUNT);

  if (desiredVertexCount != vertexCount) {
    setVertexCount(desiredVertexCount, false);
  }

  numberOfStepGrowth = ps.numberOfStepGrowth;
  bendAngle = ps.bendAngle;
  twistAngle = ps.twistAngle;
  initGVL = ps.initGVL;
  initSVL = ps.initSVL;
  sideShift = ps.sideShift;
  shellThickness = ps.shellThickness;

  if (ps.controlVertices != null) {
    PVector[] sourceVertices;
    if (ps.controlVertices.length == vertexCount) {
      sourceVertices = new PVector[vertexCount];
      for (int i = 0; i < vertexCount; i++) {
        sourceVertices[i] = ps.controlVertices[i].copy();
      }
    } else {
      sourceVertices = resampleControlVertices(ps.controlVertices, vertexCount);
    }
    applyControlVertices(sourceVertices);
  } else {
    applyControlVertices(createDefaultControlVertices(vertexCount));
  }
  
  resetVectors();

  // 更新所有UI控件
  updateSliders();
}

void export3DModel() {
  exportVertices = new ArrayList<PVector>();
  exportFaces = new ArrayList<int[]>();

  int[][][] vertexIndices = new int[numberOfStepGrowth][vertexCount][2];
  int vertexCounter = 0;

  // 添加顶点（保持不变）
  for (int i = 0; i < numberOfStepGrowth; i++) {
    for (int j = 0; j < vertexCount; j++) {
      exportVertices.add(ringsOuter[i][j]);
      vertexIndices[i][j][0] = vertexCounter++;
      exportVertices.add(ringsInner[i][j]);
      vertexIndices[i][j][1] = vertexCounter++;
    }
  }

  // 外表面 - 保持不变，因为已经正确
  for (int i = 0; i < numberOfStepGrowth - 1; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;

      int v1 = vertexIndices[i][j][0];
      int v2 = vertexIndices[i + 1][j][0];
      int v3 = vertexIndices[i + 1][nextJ][0];
      int v4 = vertexIndices[i][nextJ][0];

      exportFaces.add(new int[]{v1, v3, v2});
      exportFaces.add(new int[]{v1, v4, v3});
    }
  }

  // 内表面 - 修改顶点顺序
  for (int i = 0; i < numberOfStepGrowth - 1; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;

      int v1 = vertexIndices[i][j][1];
      int v2 = vertexIndices[i + 1][j][1];
      int v3 = vertexIndices[i + 1][nextJ][1];
      int v4 = vertexIndices[i][nextJ][1];

      exportFaces.add(new int[]{v1, v2, v3}); // 修改为常顺序
      exportFaces.add(new int[]{v1, v3, v4}); // 修改为正常顺序
    }
  }

  // 侧面（厚度）- 修改顶点顺序
  for (int i = 0; i < numberOfStepGrowth; i++) {
    for (int j = 0; j < vertexCount; j++) {
      int nextJ = (j + 1) % vertexCount;

      int v1 = vertexIndices[i][j][0];
      int v2 = vertexIndices[i][nextJ][0];
      int v3 = vertexIndices[i][nextJ][1];
      int v4 = vertexIndices[i][j][1];

      exportFaces.add(new int[]{v1, v2, v3}); // 修改为正常顺序
      exportFaces.add(new int[]{v1, v3, v4}); // 修改为正��顺��
    }
  }

  // 修改起始端的顶点顺序
  for (int j = 0; j < vertexCount; j++) {
    int nextJ = (j + 1) % vertexCount;
    int v1 = vertexIndices[0][j][0];
    int v2 = vertexIndices[0][nextJ][0];
    int v3 = vertexIndices[0][nextJ][1];
    int v4 = vertexIndices[0][j][1];
    
    // 修改后：确保面片朝向内部
    exportFaces.add(new int[]{v2, v1, v3});  // 顺时针顺序，使法线朝内
    exportFaces.add(new int[]{v4, v3, v1});  // 顺时针顺序，使法线朝内
  }

  // 结束端保持不变
  int lastIndex = numberOfStepGrowth - 1;
  for (int j = 0; j < vertexCount; j++) {
    int nextJ = (j + 1) % vertexCount;
    int v1 = vertexIndices[lastIndex][j][0];
    int v2 = vertexIndices[lastIndex][nextJ][0];
    int v3 = vertexIndices[lastIndex][nextJ][1];
    int v4 = vertexIndices[lastIndex][j][1];
    
    exportFaces.add(new int[]{v1, v2, v3});
    exportFaces.add(new int[]{v1, v3, v4});
  }

  writeOBJFile();
}

void writeOBJFile() {
  // 确定保存OBJ文件的目录
  String dirPath = sketchPath("../model/obj/");
  File dir = new File(dirPath);
  if (!dir.exists()) {
    dir.mkdirs(); // 如果目录不存在，则创建
  }

  // 获取目中已有的OBJ文件，匹配"shell_model_*.obj"模式
  String[] fileNames = dir.list();
  int maxNumber = 0;
  for (String name : fileNames) {
    if (name.startsWith("shell_model_") && name.endsWith(".obj")) {
      // 提取编号部分
      String numberStr = name.substring("shell_model_".length(), name.length() - 4); // 去除前缀和".obj"
      try {
        int number = Integer.parseInt(numberStr);
        if (number > maxNumber) {
          maxNumber = number;
        }
      } catch (NumberFormatException e) {
        // 忽略不符合命名规则的文件
      }
    }
  }
  int nextNumber = maxNumber + 1;
  // 格式化编号确保有两位数，如"01"
  String numberStr = String.format("%02d", nextNumber);

  // 构建文件路径
  String filePath = dirPath + "shell_model_" + numberStr + ".obj";
  PrintWriter output = createWriter(filePath);

  // 写入顶点
  for (PVector v : exportVertices) {
    output.println("v " + v.x + " " + v.y + " " + v.z);
  }

  // 写入面
  for (int[] face : exportFaces) {
    // 注意：OBJ索引从1开始
    output.println("f " + (face[0] + 1) + " " + (face[1] + 1) + " " + (face[2] + 1));
  }

  output.flush();
  output.close();

}

void updateParametersFromSliders() {
  int desiredVertexCount = int(round(sliderVertexCount.getValue()));
  if (desiredVertexCount != vertexCount) {
    setVertexCount(desiredVertexCount);
  }

  numberOfStepGrowth = (int)sliderGrowthStep.getValue();
  bendAngle = 0.005f * sliderBendAngle.getValue();
  twistAngle = 0.001f * sliderTwistAngle.getValue();
  initGVL = 0.025f * sliderConeHight.getValue();
  initSVL = 0.1f * sliderConeWidth.getValue();
  sideShift = 0.01f * sliderSideShift.getValue();
  shellThickness = 0.1f * sliderThickness.getValue();
}

void saveState() {
  // 创建当前状态的副本
  ShellState currentState = new ShellState();
  currentState.numberOfStepGrowth = numberOfStepGrowth;
  currentState.bendAngle = bendAngle;
  currentState.twistAngle = twistAngle;
  currentState.initGVL = initGVL;
  currentState.initSVL = initSVL;
  currentState.sideShift = sideShift;
  currentState.shellThickness = shellThickness;
  currentState.vertexCount = vertexCount;
  currentState.controlVertices = new PVector[vertexCount];
  for (int i = 0; i < vertexCount; i++) {
    currentState.controlVertices[i] = controlVertices[i].copy();
  }

  // 将当前状态添加到撤销栈
  undoStack.add(currentState);

  // 限制撤销栈的大小
  if (undoStack.size() > maxUndoSteps) {
    undoStack.remove(0);
  }

  // 清空重做栈
  redoStack.clear();
}

void undo() {
    if (undoStack.size() > 1) {  // 确保至少有两个状态
        isUndoingOrRedoing = true;
        
        // 获取当前状态并移动到重做栈
        ShellState currentState = undoStack.remove(undoStack.size() - 1);
        redoStack.add(currentState);

        // 获取上一个状态
        ShellState prevState = undoStack.get(undoStack.size() - 1);
        
        // 如果是删除操作的撤销
        if (prevState.type != null && prevState.type.equals("DELETE")) {
            // 恢复被删除的参数集
            parameterSets.add(prevState.parameterSetIndex, prevState.deletedParameterSet);
            // 更��XML文��
            saveParameterSetToXML(prevState.deletedParameterSet, prevState.parameterSetIndex);
            // 更新UI
            currentParameterSetIndex = prevState.parameterSetIndex;
            updateDropdownParameterSets();
            dropdownParameterSets.setValue(currentParameterSetIndex);
            applyParameterSet(prevState.deletedParameterSet);
        } else {
            // 普通状态的撤销
            applyState(prevState);
        }
        
        isUndoingOrRedoing = false;
    }
}

void redo() {
  if (redoStack.size() > 0) {
    isUndoingOrRedoing = true;
    // 从重做栈获取状���并应用
    ShellState redoState = redoStack.remove(redoStack.size() - 1);
    applyState(redoState);

    // 将状态添加回撤销栈
    undoStack.add(redoState);
    isUndoingOrRedoing = false;
  }
}

void applyState(ShellState state) {
  numberOfStepGrowth = state.numberOfStepGrowth;
  bendAngle = state.bendAngle;
  twistAngle = state.twistAngle;
  initGVL = state.initGVL;
  initSVL = state.initSVL;
  sideShift = state.sideShift;
  shellThickness = state.shellThickness;

  if (state.vertexCount != vertexCount) {
    setVertexCount(state.vertexCount, false);
  }

  if (state.controlVertices != null) {
    for (int i = 0; i < controlVertices.length && i < state.controlVertices.length; i++) {
      controlVertices[i].set(state.controlVertices[i]);
    }
    updateShapeFromControlVertices();
  }
  resetVectors();

  updateSliders();
}

class ShellState {
  int numberOfStepGrowth;
  float bendAngle;
  float twistAngle;
  float initGVL;
  float initSVL;
  float sideShift;
  float shellThickness;
  PVector[] controlVertices;
  int vertexCount;
  
  // 新增字段用于删除操作
  String type;  // "DELETE" 或 null
  ParameterSet deletedParameterSet;
  int parameterSetIndex;
  
  ShellState copy() {
      ShellState newState = new ShellState();
      newState.numberOfStepGrowth = this.numberOfStepGrowth;
      newState.bendAngle = this.bendAngle;
      newState.twistAngle = this.twistAngle;
      newState.initGVL = this.initGVL;
      newState.initSVL = this.initSVL;
      newState.sideShift = this.sideShift;
      newState.shellThickness = this.shellThickness;
      newState.vertexCount = this.vertexCount;
      
      if (this.controlVertices != null) {
          newState.controlVertices = new PVector[this.controlVertices.length];
          for (int i = 0; i < this.controlVertices.length; i++) {
              newState.controlVertices[i] = this.controlVertices[i].copy();
          }
      }
      
      newState.type = this.type;
      newState.deletedParameterSet = this.deletedParameterSet != null ? 
          this.deletedParameterSet.copy() : null;
      newState.parameterSetIndex = this.parameterSetIndex;
      
      return newState;
  }
}

class ParameterSet {
    String name;
    int vertexCount;
    int numberOfStepGrowth;
    float bendAngle;
    float twistAngle;
    float initGVL;
    float initSVL;
    float sideShift;
    float shellThickness;
    PVector[] controlVertices;
    
    ParameterSet copy() {
        ParameterSet newPS = new ParameterSet();
        newPS.name = this.name;
        newPS.vertexCount = this.vertexCount;
        newPS.numberOfStepGrowth = this.numberOfStepGrowth;
        newPS.bendAngle = this.bendAngle;
        newPS.twistAngle = this.twistAngle;
        newPS.initGVL = this.initGVL;
        newPS.initSVL = this.initSVL;
        newPS.sideShift = this.sideShift;
        newPS.shellThickness = this.shellThickness;
        
        if (this.controlVertices != null) {
            newPS.controlVertices = new PVector[this.controlVertices.length];
            for (int i = 0; i < this.controlVertices.length; i++) {
                newPS.controlVertices[i] = this.controlVertices[i].copy();
            }
        }
        
    return newPS;
  }
}

// 添加更新当前参数集的方法
void updateCurrentParameterSet() {
    if (currentParameterSetIndex >= 0 && currentParameterSetIndex < parameterSets.size()) {
        // 更新内存中的参数集
        ParameterSet currentPS = parameterSets.get(currentParameterSetIndex);
        
        // 更新参数集的所有值
        currentPS.numberOfStepGrowth = numberOfStepGrowth;
        currentPS.bendAngle = bendAngle;
        currentPS.twistAngle = twistAngle;
        currentPS.initGVL = initGVL;
        currentPS.initSVL = initSVL;
        currentPS.sideShift = sideShift;
        currentPS.shellThickness = shellThickness;
        currentPS.vertexCount = vertexCount;
        
        // 更新控制顶点
        if (currentPS.controlVertices == null || currentPS.controlVertices.length != vertexCount) {
            currentPS.controlVertices = new PVector[vertexCount];
        }
        for (int i = 0; i < vertexCount; i++) {
            currentPS.controlVertices[i] = controlVertices[i].copy();
        }
        
        // 保存到XML文件
        saveParametersToXML();
        
    }
}

// 添加删除参数集的方法
void deleteCurrentParameterSet() {
    if (currentParameterSetIndex < 0 || currentParameterSetIndex >= parameterSets.size()) {
        return;
    }

    // 保存删除前的状态用于撤销
    ShellState deleteState = new ShellState();
    deleteState.type = "DELETE";
    deleteState.deletedParameterSet = parameterSets.get(currentParameterSetIndex).copy();
    deleteState.parameterSetIndex = currentParameterSetIndex;
    undoStack.add(deleteState);

    // 先从内存中删除参数集
    parameterSets.remove(currentParameterSetIndex);
    
    // 从XML文件中删除
    deleteParameterSetFromXML(currentParameterSetIndex);

    // 重新设置当前索引
    if (parameterSets.size() > 0) {
        // 设置为第一个参数集
        currentParameterSetIndex = 0;
        
        // 先清除下拉菜单
        dropdownParameterSets.clear();
        
        // 重新添加所有选项
        for (int i = 0; i < parameterSets.size(); i++) {
            dropdownParameterSets.addItem("Parameter Set " + (i + 1), i);
        }
        
        // 设置下拉菜单值并应用参数
        dropdownParameterSets.setValue(0);
        applyParameterSet(parameterSets.get(0));
    } else {
        currentParameterSetIndex = -1;
        dropdownParameterSets.clear();
        resetParameters();
    }
}

// 添加从XML文件中删除参数集的方法
void deleteParameterSetFromXML(int index) {
    String filePath = sketchPath("assets/shell_parameters.xml");
    File file = new File(filePath);
    if (file.exists()) {
        XML xml = loadXML(filePath);
        XML[] paramSets = xml.getChildren("ParameterSet");
        if (index < paramSets.length) {
            xml.removeChild(paramSets[index]);
            saveXML(xml, filePath);
        }
    }
}

// 添加将参数集保存到特定位置的方法
void saveParameterSetToXML(ParameterSet ps, int index) {
    String filePath = sketchPath("assets/shell_parameters.xml");
    XML xml;
    File file = new File(filePath);
    
    if (file.exists()) {
        xml = loadXML(filePath);
    } else {
        xml = new XML("ShellParameters");
    }

    XML[] existingParams = xml.getChildren("ParameterSet");
    XML paramSet;
    
    if (index < existingParams.length) {
        paramSet = existingParams[index];
    } else {
        paramSet = xml.addChild("ParameterSet");
    }

    // 清除现有子节点
    for (XML child : paramSet.getChildren()) {
        paramSet.removeChild(child);
    }

    int count = ps.vertexCount > 0 ? ps.vertexCount : (ps.controlVertices != null ? ps.controlVertices.length : vertexCount);
    count = constrain(count, MIN_VERTEX_COUNT, MAX_VERTEX_COUNT);

    ps.vertexCount = count;

    paramSet.addChild("VertexCount").setContent(Integer.toString(count));
    paramSet.addChild("NumberOfStepGrowth").setContent(Integer.toString(ps.numberOfStepGrowth));
    paramSet.addChild("BendAngle").setContent(Float.toString(ps.bendAngle));
    paramSet.addChild("TwistAngle").setContent(Float.toString(ps.twistAngle));
    paramSet.addChild("InitGVL").setContent(Float.toString(ps.initGVL));
    paramSet.addChild("InitSVL").setContent(Float.toString(ps.initSVL));
    paramSet.addChild("SideShift").setContent(Float.toString(ps.sideShift));
    paramSet.addChild("ShellThickness").setContent(Float.toString(ps.shellThickness));

    XML controlVerticesXML = paramSet.addChild("ControlVertices");
    PVector[] vertices = ps.controlVertices;
    if (vertices == null) {
        vertices = createDefaultControlVertices(count);
    } else if (vertices.length != count) {
        vertices = resampleControlVertices(vertices, count);
    }
    for (int i = 0; i < vertices.length; i++) {
        XML vertexXML = controlVerticesXML.addChild("Vertex");
        vertexXML.addChild("X").setContent(Float.toString(vertices[i].x));
        vertexXML.addChild("Y").setContent(Float.toString(vertices[i].y));
    }

    saveXML(xml, filePath);
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

// 添加增量控制方法
void applyIncrementalControl(int bendingDelta, int twistingDelta, int coneWidthDelta) {
    // 保存当前状态用于撤销
    if (!isUndoingOrRedoing) {
        saveState();
    }
    
    // 应用bending angle增量
    if (bendingDelta != 0) {
        float currentBending = sliderBendAngle.getValue();
        float newBending = constrain(currentBending + bendingDelta, -100, 100);
        sliderBendAngle.setValue(newBending);
        bendAngle = 0.005f * newBending;
        println("Bending angle changed by " + bendingDelta + " to " + newBending);
    }
    
    // 应用twisting angle增量
    if (twistingDelta != 0) {
        float currentTwisting = sliderTwistAngle.getValue();
        float newTwisting = constrain(currentTwisting + (twistingDelta * 2), -200, 200);
        sliderTwistAngle.setValue(newTwisting);
        twistAngle = 0.001f * newTwisting;
        println("Twisting angle changed by " + (twistingDelta * 2) + " to " + newTwisting);
    }
    
    // 应用cone width增量
    if (coneWidthDelta != 0) {
        float currentConeWidth = sliderConeWidth.getValue();
        float newConeWidth = constrain(currentConeWidth + coneWidthDelta, 0, 100);
        sliderConeWidth.setValue(newConeWidth);
        initSVL = 0.1f * newConeWidth;
        println("Cone width changed by " + coneWidthDelta + " to " + newConeWidth);
    }
    
    // 更新参数并重新计算
    updateParametersFromSliders();
    resetVectors();
}

// 添加串口状态显示方法
void drawSerialStatus() {
  pushMatrix();
  pushStyle();
  
  // 重置变换
  resetMatrix();
  
  // 设置文本样式
  textAlign(LEFT, TOP);
  textSize(12);
  fill(255);
  stroke(0);
  strokeWeight(1);
  
  int yPos = 10;
  int xPos = width - 200;
  
  // 显示控制串口状态
  if (controlPort != null) {
    text("Control Port: Connected", xPos, yPos);
    text("Last Control: " + controlData, xPos, yPos + 15);
  } else {
    text("Control Port: Disconnected", xPos, yPos);
  }
  
  // 显示当前参数值
  text("Bending: " + nf(bendAngle, 0, 3), xPos, yPos + 40);
  text("Twisting: " + nf(twistAngle, 0, 3), xPos, yPos + 55);
  text("Cone Width: " + nf(initSVL, 0, 2), xPos, yPos + 70);
  
  popStyle();
  popMatrix();
}
