import controlP5.*;
import processing.data.XML;
import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import processing.serial.*;
import java.util.HashMap;
import processing.sound.*;

ControlP5 cp5;
RadioButton radio;
Slider sliderGrowthStep, sliderBendAngle, sliderTwistAngle, sliderConeHight, sliderConeWidth, sliderSideShift, sliderThickness;
Button resetButton, undoButton, redoButton;

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

// 添加常量定义
static final int VERTEX_COUNT = 12;  // 替换原来的硬编码12

PVector[] shape = new PVector[VERTEX_COUNT];
PVector[][] rings = new PVector[100][VERTEX_COUNT];
PVector[][] ringsOuter = new PVector[100][VERTEX_COUNT];
PVector[][] ringsInner = new PVector[100][VERTEX_COUNT];
float[] GVLength = new float[100];
float[] SVLength = new float[100];
PVector[] normGV = new PVector[100];
PVector[] normSV = new PVector[100];
PVector[] GV = new PVector[100];
PVector[] SV = new PVector[100];
PVector[] CV = new PVector[100];

PVector[] controlVertices = new PVector[VERTEX_COUNT];
boolean[] dragging = new boolean[VERTEX_COUNT];

ArrayList<PVector> exportVertices;
ArrayList<int[]> exportFaces;

ArrayList<ShellState> undoStack = new ArrayList<ShellState>();
ArrayList<ShellState> redoStack = new ArrayList<ShellState>();
int maxUndoSteps = 10;
boolean isUndoingOrRedoing = false;  // 防止在撤销/重做时重复记录状态

// 用于跟踪滑块是否正在被拖动
boolean isSliderDragging = false;

// 参数集列表
ArrayList<ParameterSet> parameterSets = new ArrayList<ParameterSet>();
int currentParameterSetIndex = 0;

float autoRotateSpeed = -0.003; // 负值表示逆时针旋转
boolean isAutoRotating = false; // 控制是否自动旋转

// 刺状突起的控制参数
float spikeScale = 0;        // 将初始值改为0，其他参数保持不变
float spikeFrequency = 3.0;    
float spikeWidth = 0.15;       
int spikeVertex = 4;           

Serial myPort;  // 串口对象
String rfidData = "";  // 存储RFID数据
HashMap<String, Integer> rfidMappings = new HashMap<String, Integer>();  // 存储RFID标签到参数组的映射

// 修改状态变量
boolean isTransitioning = false;
boolean isRegrowing = false;
float transitionProgress = 0;
float regrowProgress = 0;
float originalGrowthValue;
ShellState startState = null;
ShellState targetState = null;
float transitionDuration = 2.75; // 保持原有的过渡时间
float regrowDuration = 2.25; // 重生动画持续1.5秒

int nextParameterSetIndex = -1;

// 修改声音相关变量
SoundFile[] scanSounds;
String[] soundFiles = {
    "mv_box_rotor_01_g #15076.wav",
    "mv_box_rotor_02_b #15228.wav",
    "mv_box_rotor_03_d #15152.wav",
    "mv_box_rotor_04_f #15187.wav",
    "mv_box_rotor_05_g_oct #15126.wav"
};
int lastPlayedIndex = -1;  // 记录上次播放的音效索引

float[] customGrowthRates = new float[100];  // 存储每一步的生长率
float growthVariation = 0.0f;               // 生长率变化幅度
float growthFrequency = 0.1f;               // 生长率变化频率
boolean useCustomGrowth = true;              // 是否使用自定义生长
int growthPattern = 0;                       // 生长模式：0=周期性，1=渐变，2=随机

// 添加正弦波参数
float waveAmplitude = 0.0f;  // 波浪幅度
float waveFrequency = 0.0f;  // 波浪频率
float wavePhase = 0.0f;      // 波浪相位

// Add new variables for play animation
boolean isPlaying = false;
float playProgress = 0;
float playDuration = 2.0; // Duration in seconds
float targetGrowthValue = 100;  // 这个变量我们会在点击Play时更新

void setup() {
  fullScreen(P3D);
  
  // 添加串口初始化代码
  println("Available serial ports:");
  printArray(Serial.list());  // 打印所有可用串口
  
  try {
    String portName = Serial.list()[4];  // 使用第4个端口
    myPort = new Serial(this, portName, 9600);
    println("Connected to port: " + portName);
  } catch (Exception e) {
    println("Error connecting to serial port:");
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

  loadRFIDMappings();  // 在setup中加载RFID映射

  // 初始化音效数组
  scanSounds = new SoundFile[soundFiles.length];
  for (int i = 0; i < soundFiles.length; i++) {
    scanSounds[i] = new SoundFile(this, "../asset/sound/" + soundFiles[i]);
  }
}

void draw() {
  // Add play animation handling at the start of draw()
  if (isPlaying) {
      playProgress += (1.0 / frameRate) / playDuration;
      
      if (playProgress >= 1.0) {
          isPlaying = false;
          playProgress = 0;
          // 确保在动画结束时精确达到目标值
          sliderGrowthStep.setValue(targetGrowthValue);
          numberOfStepGrowth = int(targetGrowthValue);
      } else {
          // Use easeInOutQuart for smooth animation
          float smoothProgress = easeInOutQuart(playProgress);
          float currentGrowth = lerp(1, targetGrowthValue, smoothProgress);
          sliderGrowthStep.setValue(currentGrowth);
          numberOfStepGrowth = max(1, int(currentGrowth));
      }
  }

  // 处理动画
  if (isTransitioning || isRegrowing) {
    // 使用interpolateStates方法来处理所有状态的插值
    interpolateStates(startState, targetState, transitionProgress);
    
    // 更新进度
    if (isTransitioning) {
      transitionProgress += 0.01;
      if (transitionProgress >= 1.0) {
        isTransitioning = false;
        transitionProgress = 0;
      }
    }
    
    if (isRegrowing) {
      regrowProgress += 0.01;
      if (regrowProgress >= 1.0) {
        isRegrowing = false;
        regrowProgress = 0;
      }
    }
  }
  
  // 在串口数据处理部分添加状态反馈
  while (myPort != null && myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    if (inString != null) {
      rfidData = trim(inString);
      println("RFID Data Received: " + rfidData);
      
      Integer parameterIndex = rfidMappings.get(rfidData);
      if (parameterIndex != null) {
        // 随机播放一个不同的音效
        if (scanSounds != null && scanSounds.length > 0) {
          int soundIndex = getRandomSoundIndex();
          scanSounds[soundIndex].play();
          println("Playing sound: " + soundFiles[soundIndex]);  // 调试信息
        }
        
        if (parameterIndex == currentParameterSetIndex) {
          // 相同标签的重生动画
          if (!isRegrowing) {  // 防止动画重叠
            originalGrowthValue = float(targetState != null ? targetState.numberOfStepGrowth : numberOfStepGrowth);
            startRegrowth();
          }
        } else {
          // 不同标签的过渡动画
          if (!isTransitioning && !isRegrowing) {
            // 保存当前的生长值用于缩小动画
            originalGrowthValue = float(numberOfStepGrowth);
            startTransition(parameterSets.get(parameterIndex));
            nextParameterSetIndex = parameterIndex;
          }
        }
      }
    }
  }

  background(100);
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
    drawSurface();      // 现在显示实体表面
  }
  popMatrix();

  drawInterface();
  drawControlInterface();
  updateShapeFromControlVertices();
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
    .setBackgroundHeight(365)
    .setLabel("Parameters");

  int yPos = 10;
  int yStep = 30;

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
    .setSpacingRow(4)            // 设置行间距
    .setSpacingColumn(100)       // 设置列间距
    .addItem("Show Opening Rings", 1)
    .addItem("Show Shell Surface", 2)   // 保持文字不变
    .addItem("Show 3D Model", 3)         // 保持文字不变
    .setItemsPerRow(2)           // 第一行显示两个选项
    .activate(0)
    .moveTo(parametersGroup);

  yPos += yStep * 2;  // 保持两行的垂直空间

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

  yPos += yStep + 10;

  // 在添加 exportGroup 之前,添加 spikeGroup
  yPos += yStep + 10; // 为新组添加一些间距

  // 添加刺状突起控制组
  Group spikeGroup = cp5.addGroup("Spikes")
    .setPosition(20, yPos)  // 使用相同的左边距
    .setWidth(280)         // 保持与其他组相同的宽度
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(140)
    .setLabel("Spikes");

  // 刺的大小滑块
  cp5.addSlider("Spike Scale")
     .setPosition(10, 10)
     .setSize(200, 20)    // 保持与其他滑相同的宽度
     .setRange(0, 5)
     .setValue(0)
     .moveTo(spikeGroup)
     .onChange(new CallbackListener() {
       public void controlEvent(CallbackEvent event) {
         spikeScale = event.getController().getValue();
       }
     });

  // 刺的频率滑块
  cp5.addSlider("Spike Frequency")
     .setPosition(10, 40)
     .setSize(200, 20)
     .setRange(0, 10)
     .setValue(0)
     .moveTo(spikeGroup)
     .onChange(new CallbackListener() {
       public void controlEvent(CallbackEvent event) {
         spikeFrequency = event.getController().getValue();
       }
     });

  // 刺的宽度滑块
  cp5.addSlider("Spike Width")
     .setPosition(10, 70)
     .setSize(200, 20)
     .setRange(0.05, 0.3)
     .setValue(spikeWidth)
     .moveTo(spikeGroup)
     .onChange(new CallbackListener() {
       public void controlEvent(CallbackEvent event) {
         spikeWidth = event.getController().getValue();
       }
     });

  // 刺的置滑块
  cp5.addSlider("Spike Position")
     .setPosition(10, 100)
     .setSize(200, 20)
     .setRange(0, 11)
     .setValue(spikeVertex)
     .moveTo(spikeGroup)
     .onChange(new CallbackListener() {
       public void controlEvent(CallbackEvent event) {
         spikeVertex = int(event.getController().getValue());
       }
     });

  yPos += 150; // 为 exportGroup 腾出空间

  // 添加波浪控制组 (移到这里)
  Group waveGroup = cp5.addGroup("Wave Control")
    .setPosition(20, yPos)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(100)
    .setLabel("Wave Control");

  // 波浪幅度滑块
  cp5.addSlider("Wave Amplitude")
     .setPosition(10, 10)
     .setSize(200, 20)
     .setRange(0, 0.5)
     .setValue(waveAmplitude)
     .moveTo(waveGroup)
     .onChange(new CallbackListener() {
       public void controlEvent(CallbackEvent event) {
         waveAmplitude = event.getController().getValue();
         if (!isSliderDragging) saveState();
       }
     });

  // 波浪频率滑块
  cp5.addSlider("Wave Frequency")
     .setPosition(10, 40)
     .setSize(200, 20)
     .setRange(0, 2)
     .setValue(waveFrequency)
     .moveTo(waveGroup)
     .onChange(new CallbackListener() {
       public void controlEvent(CallbackEvent event) {
         waveFrequency = event.getController().getValue();
         if (!isSliderDragging) saveState();
       }
     });

  // 波浪相位滑块
  cp5.addSlider("Wave Phase")
     .setPosition(10, 70)
     .setSize(200, 20)
     .setRange(0, TWO_PI)
     .setValue(wavePhase)
     .moveTo(waveGroup)
     .onChange(new CallbackListener() {
       public void controlEvent(CallbackEvent event) {
         wavePhase = event.getController().getValue();
         if (!isSliderDragging) saveState();
       }
     });

  yPos += 110;  // 为下一个组更新位置

  // 首先创建生长模式组
  Group growthGroup = cp5.addGroup("Growth Pattern")
    .setPosition(20, yPos)
    .setWidth(280)
    .setBackgroundColor(color(0, 0, 0, 20))
    .setBackgroundHeight(90)
    .setLabel("Growth Pattern");

  int yGrowthPos = 10;
  
  // 添加生长变化幅度滑块
  cp5.addSlider("Growth Variation")
     .setPosition(10, yGrowthPos)
     .setSize(200, 20)
     .setRange(0, 0.5)
     .setValue(growthVariation)
     .moveTo(growthGroup)
     .addListener(new ControlListener() {
         public void controlEvent(ControlEvent event) {
             growthVariation = event.getController().getValue();
         }
     });
     
  yGrowthPos += 30;
  
  // 添加生长频率滑块
  cp5.addSlider("Growth Frequency")
     .setPosition(10, yGrowthPos)
     .setSize(200, 20)
     .setRange(0.1, 1.0)
     .setValue(growthFrequency)
     .moveTo(growthGroup)
     .addListener(new ControlListener() {
         public void controlEvent(ControlEvent event) {
             growthFrequency = event.getController().getValue();
         }
     });

  // 更新yPos，为导出组留出空间
  yPos += 100;  // growthGroup的高度加上一些间距

  // 然后创建导出组 (移到这里)
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

  // Export按钮和Play按钮并排放置
  cp5.addButton("ExportOBJ")
    .setPosition(10, yExportPos)
    .setSize(95, 30)  // 减小宽度以容纳Play按钮
    .moveTo(exportGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        export3DModel();
      }
    });

  // Play按钮放在Export按钮右边
  cp5.addButton("Play")
    .setPosition(115, yExportPos)  // 紧接着Export按钮
    .setSize(95, 30)  // 与Export按钮相同大小
    .moveTo(exportGroup)
    .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent event) {
        targetGrowthValue = sliderGrowthStep.getValue(); // 获取当前Growth值作为目标
        sliderGrowthStep.setValue(1); // 设置初始值为1
        numberOfStepGrowth = 1;
        isPlaying = true;
        playProgress = 0;
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
    numberOfStepGrowth = 50;
    bendAngle = 0.3;  // 60/200 因为界面值要除以200
    twistAngle = 0.05;  // 50/1000 因为界面值要除以1000
    initGVL = 1.5;  // 60/40 因为界面值要除以40
    initSVL = 3.0;  // 30/10 因为界面值要除以10
    sideShift = 0;
    shellThickness = 1;
    
    // 重置刺状突起参数
    spikeScale = 0;
    spikeFrequency = 0;
    spikeWidth = 0.05;
    spikeVertex = 0;
    
    // 重置生长模式参数
    growthVariation = 0;
    growthFrequency = 0.1;
    useCustomGrowth = true;
    growthPattern = 0;
    
    // 重置波浪参数
    waveAmplitude = 0;
    waveFrequency = 0;  // Reset wave frequency to 0
    wavePhase = 0;
    
    // 重置控制顶点
    setupControlVertices();
    
    // 重置当前参数集索引
    currentParameterSetIndex = -1;
    
    // 更新滑块显示
    sliderGrowthStep.setValue(50);  // Growth
    sliderBendAngle.setValue(60);   // Bending Angle
    sliderTwistAngle.setValue(50);  // Twisting Angle
    sliderConeHight.setValue(60);   // Cone Height
    sliderConeWidth.setValue(30);   // Cone Width
    sliderSideShift.setValue(0);    // Side Shift
    sliderThickness.setValue(1);    // Thickness
    
    // 更新刺状突起和生长模式的控制器
    Controller c;
    
    c = cp5.getController("Growth Variation");
    if (c != null) c.setValue(0);
    
    c = cp5.getController("Growth Frequency");
    if (c != null) c.setValue(0.1);
    
    c = cp5.getController("Spike Scale");
    if (c != null) c.setValue(0);
    
    c = cp5.getController("Spike Frequency");
    if (c != null) c.setValue(0);
    
    c = cp5.getController("Spike Width");
    if (c != null) c.setValue(0.05);
    
    c = cp5.getController("Spike Position");
    if (c != null) c.setValue(0);
    
    // Update wave control sliders
    c = cp5.getController("Wave Amplitude");
    if (c != null) c.setValue(0);
    
    c = cp5.getController("Wave Frequency");
    if (c != null) c.setValue(0);
    
    c = cp5.getController("Wave Phase");
    if (c != null) c.setValue(0);
    
    // 设置下拉菜单显示"New Parameter"
    cp5.getController("Parameter Sets").setCaptionLabel("New Parameter");
    
    // 重置向量
    resetVectors();
}

void initializeShapesAndRings() {
  for (int i = 0; i < VERTEX_COUNT; i++) {
    shape[i] = new PVector(1, 1, 1);
  }

  for (int i = 0; i < 100; i++) {
    for (int j = 0; j < VERTEX_COUNT; j++) {
      rings[i][j] = new PVector(0, 0, 0);
      ringsOuter[i][j] = new PVector(0, 0, 0);
      ringsInner[i][j] = new PVector(0, 0, 0);
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
}

void resetVectors() {
  // 初始化方向向量
  normGV[0] = new PVector(0, 0, 1);
  normSV[0] = new PVector(0, 1, 0);
  
  // 计算自定义生长率
  if (useCustomGrowth) {
    float baseRate = 1.03f;
    for (int i = 0; i < numberOfStepGrowth; i++) {
      float variation = sin(i * growthFrequency) * growthVariation;
      customGrowthRates[i] = baseRate + variation;
    }
  }

  // 应用生长率计算实际长度
  GVLength[0] = initGVL;
  SVLength[0] = initSVL;
  
  for (int i = 1; i < numberOfStepGrowth; i++) {
    if (useCustomGrowth) {
      GVLength[i] = GVLength[i-1] * customGrowthRates[i];
      SVLength[i] = SVLength[i-1] * customGrowthRates[i];
    } else {
      GVLength[i] = initGVL * pow(growthRate, i);
      SVLength[i] = initSVL * pow(growthRate, i);
    }
    
    // 计算波浪效果
    float waveOffset = sin(i * waveFrequency + wavePhase) * waveAmplitude;
    
    // 修改生长向量和方向，加入波浪效果
    normGV[i] = rotation(normGV[i-1], normSV[i-1], -bendAngle + waveOffset);
    normGV[i].normalize();
    normSV[i] = rotation(normSV[i-1], normGV[i], -twistAngle);
    normSV[i].normalize();
    
    GV[i] = PVector.mult(normGV[i], GVLength[i]);
    SV[i] = PVector.mult(normSV[i], SVLength[i]);
    
    CV[i] = PVector.add(CV[i-1], GV[i]);
    CV[i].x += sideShift;
  }
  
  for (int i = 0; i < numberOfStepGrowth; i++) {
    for (int j = 0; j < VERTEX_COUNT; j++) {
      float angle = shape[j].y - HALF_PI;
      PVector vv1 = rotation(SV[i], normGV[i], angle);
      vv1.mult(shape[j].x);

      // 添加刺状突起的计算
      float progress = float(i) / numberOfStepGrowth;
      float spikeFactor = 1.0;

      // 计算与目标顶点的距离
      float vertexDistance = min(
          abs(j - spikeVertex),
          abs(j - spikeVertex + VERTEX_COUNT),
          abs(j - spikeVertex - VERTEX_COUNT)
      );

      // 如果在刺的影响范围内
      if (vertexDistance < (VERTEX_COUNT * spikeWidth)) {
          float spikePhase = progress * TWO_PI * spikeFrequency;
          float spikeValue = pow(sin(spikePhase) * 0.5 + 0.5, 0.7);
          
          float influence = 1.0 - (vertexDistance / (VERTEX_COUNT * spikeWidth));
          influence = pow(smoothstep(influence), 1.5);
          
          spikeFactor = 1.0 + (spikeValue * spikeScale * influence);
      }

      // 应用刺状突起
      vv1.mult(spikeFactor);

      PVector ringPoint = PVector.add(CV[i], vv1);
      rings[i][j] = ringPoint;

      // 计算外环和内环
      PVector normal = vv1.copy();
      normal.normalize();
      PVector offset = PVector.mult(normal, shellThickness / 2);

      ringsOuter[i][j] = PVector.add(ringPoint, offset);
      ringsInner[i][j] = PVector.sub(ringPoint, offset);
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

// 修改drawCenter方法来显示波形
void drawCenter() {
  float strokeWeightValue = 1 / zoom; // 保持缩放一致的线条宽度
  
  // 绘制原始生长路径
  stroke(100);  // 灰色表示原始路径
  strokeWeight(strokeWeightValue);
  for (int i = 0; i < numberOfStepGrowth - 1; i++) {
    connectVector(CV[i], CV[i + 1]);
  }
  
  // 绘制波形影响的路径
  stroke(255, 0, 0);  // 红色表示波形路径
  strokeWeight(strokeWeightValue * 2);  // 稍微粗一些以便区分
  
  PVector lastPoint = CV[0].copy();
  for (int i = 1; i < numberOfStepGrowth; i++) {
    // 计算波形偏移
    float waveOffset = sin(i * waveFrequency + wavePhase) * waveAmplitude;
    
    // 创建一个显示波形效果的点
    PVector direction = PVector.sub(CV[i], CV[i-1]).normalize();
    PVector normal = new PVector(-direction.y, direction.x, 0);  // 垂直于生长方向的向量
    PVector wavePoint = PVector.add(CV[i], PVector.mult(normal, waveOffset * 10));  // 放大波形效果以便观察
    
    // 绘制波形线段
    beginShape(LINES);
    vertex(lastPoint.x, lastPoint.y, lastPoint.z);
    vertex(wavePoint.x, wavePoint.y, wavePoint.z);
    endShape();
    
    lastPoint = wavePoint;
  }
}

void drawOpenRings() {
  float strokeWeightValue = 1 / zoom; // 保持缩放一致的线条宽度
  strokeWeight(strokeWeightValue);
  for (int i = 0; i < numberOfStepGrowth; i++) { // 修改此处
    beginShape();
    for (int j = 0; j < VERTEX_COUNT; j++) {
      vertex(rings[i][j].x, rings[i][j].y, rings[i][j].z);
    }
    vertex(rings[i][0].x, rings[i][0].y, rings[i][0].z);
    endShape();
  }
}

void drawSurface() {
  float strokeWeightValue = 0.5 / zoom;
  strokeWeight(strokeWeightValue);
  fill(200);
  noStroke();

  // 绘制外表面
  for (int i = 0; i < numberOfStepGrowth - 1; i++) {
    for (int j = 0; j < VERTEX_COUNT; j++) {
      int nextJ = (j + 1) % VERTEX_COUNT;
      beginShape();
      vertex(ringsOuter[i][j].x, ringsOuter[i][j].y, ringsOuter[i][j].z);
      vertex(ringsOuter[i + 1][j].x, ringsOuter[i + 1][j].y, ringsOuter[i + 1][j].z);
      vertex(ringsOuter[i + 1][nextJ].x, ringsOuter[i + 1][nextJ].y, ringsOuter[i + 1][nextJ].z);
      vertex(ringsOuter[i][nextJ].x, ringsOuter[i][nextJ].y, ringsOuter[i][nextJ].z);
      endShape(CLOSE);
    }
  }

  // 绘制内表面
  for (int i = 0; i < numberOfStepGrowth - 1; i++) {
    for (int j = 0; j < VERTEX_COUNT; j++) {
      int nextJ = (j + 1) % VERTEX_COUNT;
      beginShape();
      vertex(ringsInner[i][j].x, ringsInner[i][j].y, ringsInner[i][j].z);
      vertex(ringsInner[i][nextJ].x, ringsInner[i][nextJ].y, ringsInner[i][nextJ].z);
      vertex(ringsInner[i + 1][nextJ].x, ringsInner[i + 1][nextJ].y, ringsInner[i + 1][nextJ].z);
      vertex(ringsInner[i + 1][j].x, ringsInner[i + 1][j].y, ringsInner[i + 1][j].z);
      endShape(CLOSE);
    }
  }

  // 绘制侧面
  for (int i = 0; i < numberOfStepGrowth; i++) {
    for (int j = 0; j < VERTEX_COUNT; j++) {
      int nextJ = (j + 1) % VERTEX_COUNT;
      beginShape();
      vertex(ringsOuter[i][j].x, ringsOuter[i][j].y, ringsOuter[i][j].z);
      vertex(ringsOuter[i][nextJ].x, ringsOuter[i][nextJ].y, ringsOuter[i][nextJ].z);
      vertex(ringsInner[i][nextJ].x, ringsInner[i][nextJ].y, ringsInner[i][nextJ].z);
      vertex(ringsInner[i][j].x, ringsInner[i][j].y, ringsInner[i][j].z);
      endShape(CLOSE);
    }
  }

  // 绘制首尾端面
  // 起始端面
  for (int j = 0; j < VERTEX_COUNT; j++) {
    int nextJ = (j + 1) % VERTEX_COUNT;
    beginShape();
    vertex(ringsOuter[0][j].x, ringsOuter[0][j].y, ringsOuter[0][j].z);
    vertex(ringsOuter[0][nextJ].x, ringsOuter[0][nextJ].y, ringsOuter[0][nextJ].z);
    vertex(ringsInner[0][nextJ].x, ringsInner[0][nextJ].y, ringsInner[0][nextJ].z);
    vertex(ringsInner[0][j].x, ringsInner[0][j].y, ringsInner[0][j].z);
    endShape(CLOSE);
  }
  
  // 结束端面
  for (int j = 0; j < VERTEX_COUNT; j++) {
    int nextJ = (j + 1) % VERTEX_COUNT;
    beginShape();
    vertex(ringsOuter[numberOfStepGrowth-1][j].x, ringsOuter[numberOfStepGrowth-1][j].y, ringsOuter[numberOfStepGrowth-1][j].z);
    vertex(ringsOuter[numberOfStepGrowth-1][nextJ].x, ringsOuter[numberOfStepGrowth-1][nextJ].y, ringsOuter[numberOfStepGrowth-1][nextJ].z);
    vertex(ringsInner[numberOfStepGrowth-1][nextJ].x, ringsInner[numberOfStepGrowth-1][nextJ].y, ringsInner[numberOfStepGrowth-1][nextJ].z);
    vertex(ringsInner[numberOfStepGrowth-1][j].x, ringsInner[numberOfStepGrowth-1][j].y, ringsInner[numberOfStepGrowth-1][j].z);
    endShape(CLOSE);
  }
}

void connectVector(PVector a, PVector b) {
  beginShape(LINES);
  vertex(a.x, a.y, a.z);
  vertex(b.x, b.y, b.z);
  endShape();
}

void setupControlVertices() {
  float angleStep = TWO_PI / 12;
  float controlRadius = 50;
  float centerX = width - 100;
  float centerY = 100;
  
  for (int i = 0; i < controlVertices.length; i++) {
    float angle = i * angleStep;
    controlVertices[i] = new PVector(
      centerX + cos(angle) * controlRadius, 
      centerY + sin(angle) * controlRadius
    );
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
  PVector center = new PVector(width - 100, 100);
  for (int i = 0; i < controlVertices.length; i++) {
    PVector controlVertex = controlVertices[i];
    float distance = PVector.dist(controlVertex, center);
    shape[i].x = distance / 50; // 根据与中心的距离更新形状半径
    shape[i].y = atan2(controlVertex.y - center.y, controlVertex.x - center.x); // 根据控制顶点位置更新角度
  }
}

ParameterSet saveParametersToXML() {
  String filePath = sketchPath("../parameter/shell_parameters.xml");
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
        
        // 更新参数��
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

        // 更新刺状突起参数
        paramSet.addChild("SpikeScale").setContent(Float.toString(spikeScale));
        paramSet.addChild("SpikeFrequency").setContent(Float.toString(spikeFrequency));
        paramSet.addChild("SpikeWidth").setContent(Float.toString(spikeWidth));
        paramSet.addChild("SpikeVertex").setContent(Integer.toString(spikeVertex));
        
        // 更新生长模式参数
        paramSet.addChild("GrowthVariation").setContent(Float.toString(growthVariation));
        paramSet.addChild("GrowthFrequency").setContent(Float.toString(growthFrequency));
        paramSet.addChild("UseCustomGrowth").setContent(Boolean.toString(useCustomGrowth));
        paramSet.addChild("GrowthPattern").setContent(Integer.toString(growthPattern));
        
        // Add wave parameters
        paramSet.addChild("WaveAmplitude").setContent(Float.toString(waveAmplitude));
        paramSet.addChild("WaveFrequency").setContent(Float.toString(waveFrequency));
        paramSet.addChild("WavePhase").setContent(Float.toString(wavePhase));
        
        saveXML(xml, filePath);
        
        // 更新内存中的参数集对象
        ParameterSet currentPS = parameterSets.get(currentParameterSetIndex);
        currentPS.numberOfStepGrowth = numberOfStepGrowth;
        currentPS.bendAngle = bendAngle;
        currentPS.twistAngle = twistAngle;
        currentPS.initGVL = initGVL;
        currentPS.initSVL = initSVL;
        currentPS.sideShift = sideShift;
        currentPS.shellThickness = shellThickness;
        currentPS.controlVertices = new PVector[controlVertices.length];
        for (int i = 0; i < controlVertices.length; i++) {
          currentPS.controlVertices[i] = controlVertices[i].copy();
        }
        currentPS.spikeScale = spikeScale;
        currentPS.spikeFrequency = spikeFrequency;
        currentPS.spikeWidth = spikeWidth;
        currentPS.spikeVertex = spikeVertex;
        currentPS.growthVariation = growthVariation;
        currentPS.growthFrequency = growthFrequency;
        currentPS.useCustomGrowth = useCustomGrowth;
        currentPS.growthPattern = growthPattern;
        currentPS.waveAmplitude = waveAmplitude;
        currentPS.waveFrequency = waveFrequency;
        currentPS.wavePhase = wavePhase;
        
        return currentPS;
      }
    }
  } else {
    xml = new XML("ShellParameters");  // 如果文件不存在，则创建新的XML根
  }

  // 如果是新建参数集，使用原来的逻辑
  XML paramSet = xml.addChild("ParameterSet");

  // 添加所有参数
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

  // 添加刺状突起参数
  paramSet.addChild("SpikeScale").setContent(Float.toString(spikeScale));
  paramSet.addChild("SpikeFrequency").setContent(Float.toString(spikeFrequency));
  paramSet.addChild("SpikeWidth").setContent(Float.toString(spikeWidth));
  paramSet.addChild("SpikeVertex").setContent(Integer.toString(spikeVertex));
  
  // 添加生��模式参数
  paramSet.addChild("GrowthVariation").setContent(Float.toString(growthVariation));
  paramSet.addChild("GrowthFrequency").setContent(Float.toString(growthFrequency));
  paramSet.addChild("UseCustomGrowth").setContent(Boolean.toString(useCustomGrowth));
  paramSet.addChild("GrowthPattern").setContent(Integer.toString(growthPattern));
  
  // Add wave parameters
  paramSet.addChild("WaveAmplitude").setContent(Float.toString(waveAmplitude));
  paramSet.addChild("WaveFrequency").setContent(Float.toString(waveFrequency));
  paramSet.addChild("WavePhase").setContent(Float.toString(wavePhase));
  
  // 保存XML文件
  saveXML(xml, filePath);

  // 创建新的ParameterSet对象
  ParameterSet newPS = new ParameterSet();
  newPS.name = "Parameter Set " + (parameterSets.size() + 1);
  newPS.numberOfStepGrowth = numberOfStepGrowth;
  newPS.bendAngle = bendAngle;
  newPS.twistAngle = twistAngle;
  newPS.initGVL = initGVL;
  newPS.initSVL = initSVL;
  newPS.sideShift = sideShift;
  newPS.shellThickness = shellThickness;
  newPS.controlVertices = new PVector[controlVertices.length];
  for (int i = 0; i < controlVertices.length; i++) {
    newPS.controlVertices[i] = controlVertices[i].copy();
  }

  // 更新返回的参数集对象
  newPS.spikeScale = spikeScale;
  newPS.spikeFrequency = spikeFrequency;
  newPS.spikeWidth = spikeWidth;
  newPS.spikeVertex = spikeVertex;
  
  newPS.growthVariation = growthVariation;
  newPS.growthFrequency = growthFrequency;
  newPS.useCustomGrowth = useCustomGrowth;
  newPS.growthPattern = growthPattern;
  
  newPS.waveAmplitude = waveAmplitude;
  newPS.waveFrequency = waveFrequency;
  newPS.wavePhase = wavePhase;
  
  return newPS;
}

void loadParametersFromXML() {
  String filePath = sketchPath("../parameter/shell_parameters.xml");
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

      XML controlVerticesXML = params.getChild("ControlVertices");
      if (controlVerticesXML != null) {
        XML[] vertices = controlVerticesXML.getChildren("Vertex");
        ps.controlVertices = new PVector[vertices.length];
        for (int i = 0; i < vertices.length; i++) {
          float x = Float.parseFloat(vertices[i].getChild("X").getContent());
          float y = Float.parseFloat(vertices[i].getChild("Y").getContent());
          ps.controlVertices[i] = new PVector(x, y);
        }
      }

      // 加载刺状突起参数
      if (params.getChild("SpikeScale") != null) {
        ps.spikeScale = Float.parseFloat(params.getChild("SpikeScale").getContent());
      }
      if (params.getChild("SpikeFrequency") != null) {
        ps.spikeFrequency = Float.parseFloat(params.getChild("SpikeFrequency").getContent());
      }
      if (params.getChild("SpikeWidth") != null) {
        ps.spikeWidth = Float.parseFloat(params.getChild("SpikeWidth").getContent());
      }
      if (params.getChild("SpikeVertex") != null) {
        ps.spikeVertex = Integer.parseInt(params.getChild("SpikeVertex").getContent());
      }
      
      // 加载生长模式参数
      if (params.getChild("GrowthVariation") != null) {
        ps.growthVariation = Float.parseFloat(params.getChild("GrowthVariation").getContent());
      } else {
        ps.growthVariation = 0.0f; // 默认值
      }
      
      if (params.getChild("GrowthFrequency") != null) {
        ps.growthFrequency = Float.parseFloat(params.getChild("GrowthFrequency").getContent());
      } else {
        ps.growthFrequency = 0.1f; // 默认值
      }
      
      if (params.getChild("UseCustomGrowth") != null) {
        ps.useCustomGrowth = Boolean.parseBoolean(params.getChild("UseCustomGrowth").getContent());
      } else {
        ps.useCustomGrowth = true; // 默认值
      }
      
      if (params.getChild("GrowthPattern") != null) {
        ps.growthPattern = Integer.parseInt(params.getChild("GrowthPattern").getContent());
      } else {
        ps.growthPattern = 0; // 默认值
      }
      
      // Load wave parameters
      if (params.getChild("WaveAmplitude") != null) {
        ps.waveAmplitude = Float.parseFloat(params.getChild("WaveAmplitude").getContent());
      }
      if (params.getChild("WaveFrequency") != null) {
        ps.waveFrequency = Float.parseFloat(params.getChild("WaveFrequency").getContent());
      }
      if (params.getChild("WavePhase") != null) {
        ps.wavePhase = Float.parseFloat(params.getChild("WavePhase").getContent());
      }
      
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

void applyParameterSet(ParameterSet ps) {
  numberOfStepGrowth = ps.numberOfStepGrowth;
  bendAngle = ps.bendAngle;
  twistAngle = ps.twistAngle;
  initGVL = ps.initGVL;
  initSVL = ps.initSVL;
  sideShift = ps.sideShift;
  shellThickness = ps.shellThickness;

  for (int i = 0; i < controlVertices.length; i++) {
    controlVertices[i] = ps.controlVertices[i].copy();
  }

  // 应用刺状突起参数
  spikeScale = ps.spikeScale;
  spikeFrequency = ps.spikeFrequency;
  spikeWidth = ps.spikeWidth;
  spikeVertex = ps.spikeVertex;
  
  // 应用生长模式参数
  growthVariation = ps.growthVariation;
  growthFrequency = ps.growthFrequency;
  useCustomGrowth = ps.useCustomGrowth;
  growthPattern = ps.growthPattern;
  
  // 应用波浪参数
  waveAmplitude = ps.waveAmplitude;
  waveFrequency = ps.waveFrequency;
  wavePhase = ps.wavePhase;
  
  // 更新所有UI控件
  updateSliders();
  updateSpikesUI();
  updateGrowthPatternUI();
}

void export3DModel() {
  exportVertices = new ArrayList<PVector>();
  exportFaces = new ArrayList<int[]>();

  int[][][] vertexIndices = new int[numberOfStepGrowth][VERTEX_COUNT][2];
  int vertexCount = 0;

  // 添加顶点（保持不变）
  for (int i = 0; i < numberOfStepGrowth; i++) {
    for (int j = 0; j < VERTEX_COUNT; j++) {
      exportVertices.add(ringsOuter[i][j]);
      vertexIndices[i][j][0] = vertexCount++;
      exportVertices.add(ringsInner[i][j]);
      vertexIndices[i][j][1] = vertexCount++;
    }
  }

  // 外表面 - 保持不变，因为已经正确
  for (int i = 0; i < numberOfStepGrowth - 1; i++) {
    for (int j = 0; j < VERTEX_COUNT; j++) {
      int nextJ = (j + 1) % VERTEX_COUNT;

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
    for (int j = 0; j < VERTEX_COUNT; j++) {
      int nextJ = (j + 1) % VERTEX_COUNT;

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
    for (int j = 0; j < VERTEX_COUNT; j++) {
      int nextJ = (j + 1) % VERTEX_COUNT;

      int v1 = vertexIndices[i][j][0];
      int v2 = vertexIndices[i][nextJ][0];
      int v3 = vertexIndices[i][nextJ][1];
      int v4 = vertexIndices[i][j][1];

      exportFaces.add(new int[]{v1, v2, v3}); // 修改为正常顺序
      exportFaces.add(new int[]{v1, v3, v4}); // 修改为正��顺��
    }
  }

  // 修改起始端的顶点顺序
  for (int j = 0; j < VERTEX_COUNT; j++) {
    int nextJ = (j + 1) % VERTEX_COUNT;
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
  for (int j = 0; j < VERTEX_COUNT; j++) {
    int nextJ = (j + 1) % VERTEX_COUNT;
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

  println("3D模型已导出到 " + filePath);
}

void updateParametersFromSliders() {
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
  currentState.controlVertices = new PVector[controlVertices.length];
  for (int i = 0; i < controlVertices.length; i++) {
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

  // 保存刺状突起参数
  currentState.spikeScale = spikeScale;
  currentState.spikeFrequency = spikeFrequency;
  currentState.spikeWidth = spikeWidth;
  currentState.spikeVertex = spikeVertex;
  
  // 保存生长模式参数
  currentState.growthVariation = growthVariation;
  currentState.growthFrequency = growthFrequency;
  currentState.useCustomGrowth = useCustomGrowth;
  currentState.growthPattern = growthPattern;
  
  // 添加波浪参数
  currentState.waveAmplitude = waveAmplitude;
  currentState.waveFrequency = waveFrequency;
  currentState.wavePhase = wavePhase;
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

  for (int i = 0; i < controlVertices.length; i++) {
    controlVertices[i] = state.controlVertices[i].copy();
  }

  updateSliders();
  
  // 应用刺状突起参数
  spikeScale = state.spikeScale;
  spikeFrequency = state.spikeFrequency;
  spikeWidth = state.spikeWidth;
  spikeVertex = state.spikeVertex;
  
  // 应用生长模式参数
  growthVariation = state.growthVariation;
  growthFrequency = state.growthFrequency;
  useCustomGrowth = state.useCustomGrowth;
  growthPattern = state.growthPattern;
  
  // 添加波浪参数
  waveAmplitude = state.waveAmplitude;
  waveFrequency = state.waveFrequency;
  wavePhase = state.wavePhase;
  
  // 更新所有UI控件
  updateSliders();
  updateSpikesUI();
  updateGrowthPatternUI();
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
  
  // 新增字段用于删除��作
  String type;  // "DELETE" 或 null
  ParameterSet deletedParameterSet;
  int parameterSetIndex;
  
  // 添加刺状突起参数
  float spikeScale;
  float spikeFrequency;
  float spikeWidth;
  int spikeVertex;
  
  // 添加生长模式参数
  float growthVariation;
  float growthFrequency;
  boolean useCustomGrowth;
  int growthPattern;
  
  // 添加波浪参数
  float waveAmplitude;
  float waveFrequency;
  float wavePhase;
  
  ShellState copy() {
      ShellState newState = new ShellState();
      newState.numberOfStepGrowth = this.numberOfStepGrowth;
      newState.bendAngle = this.bendAngle;
      newState.twistAngle = this.twistAngle;
      newState.initGVL = this.initGVL;
      newState.initSVL = this.initSVL;
      newState.sideShift = this.sideShift;
      newState.shellThickness = this.shellThickness;
      
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
      
      // 复制刺状突起参数
      newState.spikeScale = this.spikeScale;
      newState.spikeFrequency = this.spikeFrequency;
      newState.spikeWidth = this.spikeWidth;
      newState.spikeVertex = this.spikeVertex;
      
      // 复制生长模式参数
      newState.growthVariation = this.growthVariation;
      newState.growthFrequency = this.growthFrequency;
      newState.useCustomGrowth = this.useCustomGrowth;
      newState.growthPattern = this.growthPattern;
      
      // 复制波浪参数
      newState.waveAmplitude = this.waveAmplitude;
      newState.waveFrequency = this.waveFrequency;
      newState.wavePhase = this.wavePhase;
      
      return newState;
  }
}

class ParameterSet {
    String name;
    int numberOfStepGrowth;
    float bendAngle;
    float twistAngle;
    float initGVL;
    float initSVL;
    float sideShift;
    float shellThickness;
    PVector[] controlVertices;
    
    // 刺状突起参数
    float spikeScale;
    float spikeFrequency;
    float spikeWidth;
    int spikeVertex;
    
    // 生长模式参数
    float growthVariation;
    float growthFrequency;
    boolean useCustomGrowth;
    int growthPattern;
    
    // Add wave control parameters
    float waveAmplitude;
    float waveFrequency;
    float wavePhase;
    
    // Update copy method to include wave parameters
    ParameterSet copy() {
        ParameterSet newPS = new ParameterSet();
        newPS.name = this.name;
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
        
        // 复制刺状突起参数
        newPS.spikeScale = this.spikeScale;
        newPS.spikeFrequency = this.spikeFrequency;
        newPS.spikeWidth = this.spikeWidth;
        newPS.spikeVertex = this.spikeVertex;
        
        // 复制生长模式参数
        newPS.growthVariation = this.growthVariation;
        newPS.growthFrequency = this.growthFrequency;
        newPS.useCustomGrowth = this.useCustomGrowth;
        newPS.growthPattern = this.growthPattern;
        
        // Copy wave parameters
        newPS.waveAmplitude = this.waveAmplitude;
        newPS.waveFrequency = this.waveFrequency;
        newPS.wavePhase = this.wavePhase;
        
        return newPS;
    }
}

// 基础的平滑过渡（当前使用的）
float smoothstep(float x) {
    x = constrain(x, 0, 1);
    return x * x * (3 - 2 * x);
}

// easeInOutCubic - 更强的缓入缓出效果
float easeInOutCubic(float x) {
    x = constrain(x, 0, 1);
    return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;
}

// easeInOutQuart - 更强的缓入缓出效果，中间过渡更平缓
float easeInOutQuart(float x) {
    x = constrain(x, 0, 1);
    return x < 0.5 ? 8 * x * x * x * x : 1 - pow(-2 * x + 2, 4) / 2;
}

// easeInOutElastic - 带有弹性效果的过渡
float easeInOutElastic(float x) {
    x = constrain(x, 0, 1);
    float c5 = (2 * PI) / 4.5;
    
    if (x == 0 || x == 1) return x;
    
    if (x < 0.5) {
        return -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2;
    }
    return (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1;
}

// 添加新的方法来加载RFID映射
void loadRFIDMappings() {
  String filePath = sketchPath("../parameter/rfid_mapping.xml");
  File file = new File(filePath);
  
  if (file.exists()) {
    try {
      XML xml = loadXML(filePath);
      XML[] mappings = xml.getChildren("mapping");
      
      println("Loading RFID mappings:");
      for (XML mapping : mappings) {
        String rfidTag = mapping.getString("tag");
        int parameterIndex = mapping.getInt("parameterIndex");
        rfidMappings.put(rfidTag, parameterIndex);
        println("RFID Tag: " + rfidTag + " -> Parameter Set: " + parameterIndex);
      }
      println("Loaded " + mappings.length + " RFID mappings");
      
    } catch (Exception e) {
      println("Error loading RFID mapping file:");
      println(e.getMessage());
    }
  } else {
    println("RFID mapping file not found at: " + filePath);
  }
}

// 修改过渡动画的启动方法
void startTransition(ParameterSet targetPS) {
    // 立即开始动画，不等待下一帧
    startState = new ShellState();
    startState.numberOfStepGrowth = numberOfStepGrowth;
    startState.bendAngle = bendAngle;
    startState.twistAngle = twistAngle;
    startState.initGVL = initGVL;
    startState.initSVL = initSVL;
    startState.sideShift = sideShift;
    startState.shellThickness = shellThickness;
    startState.controlVertices = new PVector[controlVertices.length];
    for (int i = 0; i < controlVertices.length; i++) {
        startState.controlVertices[i] = controlVertices[i].copy();
    }

    // 设置目标状态 - 但不立即用
    targetState = new ShellState();
    targetState.numberOfStepGrowth = targetPS.numberOfStepGrowth;
    targetState.bendAngle = targetPS.bendAngle;
    targetState.twistAngle = targetPS.twistAngle;
    targetState.initGVL = targetPS.initGVL;
    targetState.initSVL = targetPS.initSVL;
    targetState.sideShift = targetPS.sideShift;
    targetState.shellThickness = targetPS.shellThickness;
    targetState.controlVertices = targetPS.controlVertices;

    // 重置所有动画进度
    isTransitioning = true;
    isRegrowing = true;
    transitionProgress = 0;
    regrowProgress = 0;
    
    // 确保第一帧使用原始值
    numberOfStepGrowth = startState.numberOfStepGrowth;
    
    // ��新UI，但保持当前值
    updateSliders();

    // 在startState中保存当前状态
    startState.spikeScale = spikeScale;
    startState.spikeFrequency = spikeFrequency;
    startState.spikeWidth = spikeWidth;
    startState.spikeVertex = spikeVertex;
    startState.growthVariation = growthVariation;
    startState.growthFrequency = growthFrequency;
    startState.useCustomGrowth = useCustomGrowth;
    startState.growthPattern = growthPattern;
    
    // 设置目标状态
    targetState.spikeScale = targetPS.spikeScale;
    targetState.spikeFrequency = targetPS.spikeFrequency;
    targetState.spikeWidth = targetPS.spikeWidth;
    targetState.spikeVertex = targetPS.spikeVertex;
    targetState.growthVariation = targetPS.growthVariation;
    targetState.growthFrequency = targetPS.growthFrequency;
    targetState.useCustomGrowth = targetPS.useCustomGrowth;
    targetState.growthPattern = targetPS.growthPattern;
}

// 添加状态插值方法
void interpolateStates(ShellState start, ShellState target, float progress) {
    float smoothProgress = easeInOutQuart(progress);
    
    // 基础参数插值
    numberOfStepGrowth = int(lerp(start.numberOfStepGrowth, target.numberOfStepGrowth, smoothProgress));
    bendAngle = lerp(start.bendAngle, target.bendAngle, smoothProgress);
    twistAngle = lerp(start.twistAngle, target.twistAngle, smoothProgress);
    initGVL = lerp(start.initGVL, target.initGVL, smoothProgress);
    initSVL = lerp(start.initSVL, target.initSVL, smoothProgress);
    sideShift = lerp(start.sideShift, target.sideShift, smoothProgress);
    shellThickness = lerp(start.shellThickness, target.shellThickness, smoothProgress);
    
    // 添加控制顶点的插值
    for (int i = 0; i < controlVertices.length; i++) {
        float x = lerp(start.controlVertices[i].x, target.controlVertices[i].x, smoothProgress);
        float y = lerp(start.controlVertices[i].y, target.controlVertices[i].y, smoothProgress);
        controlVertices[i].set(x, y);
    }
    
    // 刺状突起参数插值
    spikeScale = lerp(start.spikeScale, target.spikeScale, smoothProgress);
    spikeFrequency = lerp(start.spikeFrequency, target.spikeFrequency, smoothProgress);
    spikeWidth = lerp(start.spikeWidth, target.spikeWidth, smoothProgress);
    spikeVertex = int(lerp(start.spikeVertex, target.spikeVertex, smoothProgress));
    
    // 生长模式参数插值
    growthVariation = lerp(start.growthVariation, target.growthVariation, smoothProgress);
    growthFrequency = lerp(start.growthFrequency, target.growthFrequency, smoothProgress);
    useCustomGrowth = smoothProgress < 0.5 ? start.useCustomGrowth : target.useCustomGrowth;
    growthPattern = smoothProgress < 0.5 ? start.growthPattern : target.growthPattern;
    
    // 更新所有UI
    updateSliders();
    updateSpikesUI();
    updateGrowthPatternUI();
}

// 添加重生动画启动方法
void startRegrowth() {
  startState = new ShellState();
  startState.numberOfStepGrowth = int(originalGrowthValue);
  startState.bendAngle = bendAngle;
  startState.twistAngle = twistAngle;
  startState.initGVL = initGVL;
  startState.initSVL = initSVL;
  startState.sideShift = sideShift;
  startState.shellThickness = shellThickness;
  startState.controlVertices = new PVector[controlVertices.length];
  for (int i = 0; i < controlVertices.length; i++) {
    startState.controlVertices[i] = controlVertices[i].copy();
  }
  
  targetState = new ShellState();
  targetState.numberOfStepGrowth = int(originalGrowthValue);
  targetState.bendAngle = bendAngle;
  targetState.twistAngle = twistAngle;
  targetState.initGVL = initGVL;
  targetState.initSVL = initSVL;
  targetState.sideShift = sideShift;
  targetState.shellThickness = shellThickness;
  targetState.controlVertices = new PVector[controlVertices.length];
  for (int i = 0; i < controlVertices.length; i++) {
    targetState.controlVertices[i] = controlVertices[i].copy();
  }
  
  isRegrowing = true;
  regrowProgress = 0;
  
  // 保存当前状态
  startState.spikeScale = spikeScale;
  startState.spikeFrequency = spikeFrequency;
  startState.spikeWidth = spikeWidth;
  startState.spikeVertex = spikeVertex;
  startState.growthVariation = growthVariation;
  startState.growthFrequency = growthFrequency;
  startState.useCustomGrowth = useCustomGrowth;
  startState.growthPattern = growthPattern;
  
  // 设置目标状态（与当前状态相同，因为是重生动画）
  targetState.spikeScale = spikeScale;
  targetState.spikeFrequency = spikeFrequency;
  targetState.spikeWidth = spikeWidth;
  targetState.spikeVertex = spikeVertex;
  targetState.growthVariation = growthVariation;
  targetState.growthFrequency = growthFrequency;
  targetState.useCustomGrowth = useCustomGrowth;
  targetState.growthPattern = growthPattern;
}

// 添加随机音效选择方法
int getRandomSoundIndex() {
    if (scanSounds.length <= 1) return 0;
    
    int randomIndex;
    do {
        randomIndex = int(random(scanSounds.length));
    } while (randomIndex == lastPlayedIndex);
    
    lastPlayedIndex = randomIndex;  // 更新上次播放的索引
    return randomIndex;
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
        
        // 更新控制顶点
        if (currentPS.controlVertices == null) {
            currentPS.controlVertices = new PVector[controlVertices.length];
        }
        for (int i = 0; i < controlVertices.length; i++) {
            currentPS.controlVertices[i] = controlVertices[i].copy();
        }
        
        // 更新刺状突起参数
        currentPS.spikeScale = spikeScale;
        currentPS.spikeFrequency = spikeFrequency;
        currentPS.spikeWidth = spikeWidth;
        currentPS.spikeVertex = spikeVertex;
        
        // 更新生长模式参数
        currentPS.growthVariation = growthVariation;
        currentPS.growthFrequency = growthFrequency;
        currentPS.useCustomGrowth = useCustomGrowth;
        currentPS.growthPattern = growthPattern;
        
        // Update wave parameters
        currentPS.waveAmplitude = waveAmplitude;
        currentPS.waveFrequency = waveFrequency;
        currentPS.wavePhase = wavePhase;
        
        // 保存到XML文件
        saveParametersToXML();
        
        println("Updated Parameter Set " + (currentParameterSetIndex + 1));
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
    String filePath = sketchPath("../parameter/shell_parameters.xml");
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
    String filePath = sketchPath("../parameter/shell_parameters.xml");
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

    saveXML(xml, filePath);
}

// 添加新方法来更新UI控件
void updateSpikesUI() {
    cp5.getController("Spike Scale").setValue(spikeScale);
    cp5.getController("Spike Frequency").setValue(spikeFrequency);
    cp5.getController("Spike Width").setValue(spikeWidth);
    cp5.getController("Spike Position").setValue(spikeVertex);
}

void updateGrowthPatternUI() {
    cp5.getController("Growth Variation").setValue(growthVariation);
    cp5.getController("Growth Frequency").setValue(growthFrequency);
}

void startPlayAnimation() {
    if (!isPlaying) {
        isPlaying = true;
        playProgress = 0;
        
        // Set target growth value based on current parameter set
        if (currentParameterSetIndex >= 0 && currentParameterSetIndex < parameterSets.size()) {
            targetGrowthValue = parameterSets.get(currentParameterSetIndex).numberOfStepGrowth;
        } else {
            targetGrowthValue = 50; // Default value if no parameter set is selected
        }
        
        originalGrowthValue = sliderGrowthStep.getValue();
        
        // Save state for undo
        if (!isUndoingOrRedoing) {
            saveState();
        }
    }
}

// Add new method to update wave control UI
void updateWaveControlUI() {
    cp5.getController("Wave Amplitude").setValue(waveAmplitude);
    cp5.getController("Wave Frequency").setValue(waveFrequency);
    cp5.getController("Wave Phase").setValue(wavePhase);
}

// 添加新的绘制方法
void drawWireSurface() {
  float strokeWeightValue = 0.5 / zoom; // 保持缩放一致的线条宽度
  strokeWeight(strokeWeightValue);
  for (int i = 0; i < numberOfStepGrowth - 1; i++) {
    for (int j = 0; j < VERTEX_COUNT - 1; j++) {
      beginShape();
      vertex(rings[i][j].x, rings[i][j].y, rings[i][j].z);
      vertex(rings[i][j + 1].x, rings[i][j + 1].y, rings[i][j + 1].z);
      vertex(rings[i + 1][j + 1].x, rings[i + 1][j + 1].y, rings[i + 1][j + 1].z);
      vertex(rings[i][j].x, rings[i][j].y, rings[i][j].z);
      endShape(CLOSE);

      beginShape();
      vertex(rings[i][j].x, rings[i][j].y, rings[i][j].z);
      vertex(rings[i + 1][j].x, rings[i + 1][j].y, rings[i + 1][j].z);
      vertex(rings[i + 1][j + 1].x, rings[i + 1][j + 1].y, rings[i + 1][j + 1].z);
      vertex(rings[i][j].x, rings[i][j].y, rings[i][j].z);
      endShape(CLOSE);
    }

    // 处理首尾相连的部分
    beginShape();
    vertex(rings[i][VERTEX_COUNT-1].x, rings[i][VERTEX_COUNT-1].y, rings[i][VERTEX_COUNT-1].z);
    vertex(rings[i][0].x, rings[i][0].y, rings[i][0].z);
    vertex(rings[i + 1][0].x, rings[i + 1][0].y, rings[i + 1][0].z);
    vertex(rings[i][VERTEX_COUNT-1].x, rings[i][VERTEX_COUNT-1].y, rings[i][VERTEX_COUNT-1].z);
    endShape();

    beginShape();
    vertex(rings[i][VERTEX_COUNT-1].x, rings[i][VERTEX_COUNT-1].y, rings[i][VERTEX_COUNT-1].z);
    vertex(rings[i + 1][VERTEX_COUNT-1].x, rings[i + 1][VERTEX_COUNT-1].y, rings[i + 1][VERTEX_COUNT-1].z);
    vertex(rings[i + 1][0].x, rings[i + 1][0].y, rings[i + 1][0].z);
    vertex(rings[i][VERTEX_COUNT-1].x, rings[i][VERTEX_COUNT-1].y, rings[i][VERTEX_COUNT-1].z);
    endShape();
  }
}
