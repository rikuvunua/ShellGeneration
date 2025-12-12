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
        paramSet.addChild("GrowthRate").setContent(Float.toString(growthRate));
        paramSet.addChild("SideShift").setContent(Float.toString(sideShift));
        paramSet.addChild("ShellThickness").setContent(Float.toString(shellThickness));
        paramSet.addChild("OpeningFlatten").setContent(Float.toString(openingFlatten));
        paramSet.addChild("OpeningRotationDeg").setContent(Float.toString(openingRotationDeg));
        paramSet.addChild("TwistGradient").setContent(Float.toString(twistGradient));
        paramSet.addChild("TwistWaveAmplitude").setContent(Float.toString(twistWaveAmplitude));
        paramSet.addChild("TwistWaveFrequency").setContent(Float.toString(twistWaveFrequency));
        paramSet.addChild("TwistWavePhase").setContent(Float.toString(twistWavePhase));
        
        saveXML(xml, filePath);
        
        // 更新内存中的参数集对象
        ParameterSet currentPS = parameterSets.get(currentParameterSetIndex);
        currentPS.vertexCount = vertexCount;
        currentPS.numberOfStepGrowth = numberOfStepGrowth;
        currentPS.bendAngle = bendAngle;
        currentPS.twistAngle = twistAngle;
        currentPS.initGVL = initGVL;
        currentPS.initSVL = initSVL;
        currentPS.growthRate = growthRate;
        currentPS.sideShift = sideShift;
        currentPS.shellThickness = shellThickness;
        currentPS.openingFlatten = openingFlatten;
        currentPS.openingRotationDeg = openingRotationDeg;
        currentPS.twistGradient = twistGradient;
        currentPS.twistWaveAmplitude = twistWaveAmplitude;
        currentPS.twistWaveFrequency = twistWaveFrequency;
        currentPS.twistWavePhase = twistWavePhase;
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
  paramSet.addChild("GrowthRate").setContent(Float.toString(growthRate));
  paramSet.addChild("SideShift").setContent(Float.toString(sideShift));
  paramSet.addChild("ShellThickness").setContent(Float.toString(shellThickness));
  paramSet.addChild("OpeningFlatten").setContent(Float.toString(openingFlatten));
  paramSet.addChild("OpeningRotationDeg").setContent(Float.toString(openingRotationDeg));
  paramSet.addChild("TwistGradient").setContent(Float.toString(twistGradient));
  paramSet.addChild("TwistWaveAmplitude").setContent(Float.toString(twistWaveAmplitude));
  paramSet.addChild("TwistWaveFrequency").setContent(Float.toString(twistWaveFrequency));
  paramSet.addChild("TwistWavePhase").setContent(Float.toString(twistWavePhase));
  
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
  newPS.growthRate = growthRate;
  newPS.sideShift = sideShift;
  newPS.shellThickness = shellThickness;
  newPS.openingFlatten = openingFlatten;
  newPS.openingRotationDeg = openingRotationDeg;
  newPS.twistGradient = twistGradient;
  newPS.twistWaveAmplitude = twistWaveAmplitude;
  newPS.twistWaveFrequency = twistWaveFrequency;
  newPS.twistWavePhase = twistWavePhase;
  // 控制顶点不再保存到 XML，保持内存使用默认形状
  newPS.controlVertices = createDefaultControlVertices(vertexCount);
  
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
      ps.twistGradient = twistGradient;
      ps.twistWaveAmplitude = twistWaveAmplitude;
      ps.twistWaveFrequency = twistWaveFrequency;
      ps.twistWavePhase = twistWavePhase;

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

      if (params.getChild("GrowthRate") != null) {
        ps.growthRate = Float.parseFloat(params.getChild("GrowthRate").getContent());
      } else {
        ps.growthRate = growthRate;
      }

      if (params.getChild("SideShift") != null) {
        ps.sideShift = Float.parseFloat(params.getChild("SideShift").getContent());
      }

      if (params.getChild("ShellThickness") != null) {
        ps.shellThickness = Float.parseFloat(params.getChild("ShellThickness").getContent());
      }

      if (params.getChild("OpeningFlatten") != null) {
        ps.openingFlatten = Float.parseFloat(params.getChild("OpeningFlatten").getContent());
      }

      if (params.getChild("OpeningRotationDeg") != null) {
        ps.openingRotationDeg = Float.parseFloat(params.getChild("OpeningRotationDeg").getContent());
      }

      if (params.getChild("TwistGradient") != null) {
        ps.twistGradient = Float.parseFloat(params.getChild("TwistGradient").getContent());
      }
      if (params.getChild("TwistWaveAmplitude") != null) {
        ps.twistWaveAmplitude = Float.parseFloat(params.getChild("TwistWaveAmplitude").getContent());
      }
      if (params.getChild("TwistWaveFrequency") != null) {
        ps.twistWaveFrequency = Float.parseFloat(params.getChild("TwistWaveFrequency").getContent());
      }
      if (params.getChild("TwistWavePhase") != null) {
        ps.twistWavePhase = Float.parseFloat(params.getChild("TwistWavePhase").getContent());
      }

      int loadedVertexCount = vertexCount;
      if (params.getChild("VertexCount") != null) {
        loadedVertexCount = constrain(Integer.parseInt(params.getChild("VertexCount").getContent()), MIN_VERTEX_COUNT, MAX_VERTEX_COUNT);
      }

      // 不再从 XML 读取控制顶点，使用默认或现有数量
      loadedVertexCount = max(loadedVertexCount, MIN_VERTEX_COUNT);
      ps.controlVertices = createDefaultControlVertices(loadedVertexCount);

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
  growthRate = ps.growthRate;
  sideShift = ps.sideShift;
  shellThickness = ps.shellThickness;
  openingFlatten = ps.openingFlatten;
  openingRotationDeg = ps.openingRotationDeg;
  twistGradient = ps.twistGradient;
  twistWaveAmplitude = ps.twistWaveAmplitude;
  twistWaveFrequency = ps.twistWaveFrequency;
  twistWavePhase = ps.twistWavePhase;

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
        currentPS.growthRate = growthRate;
        currentPS.sideShift = sideShift;
        currentPS.shellThickness = shellThickness;
        currentPS.openingFlatten = openingFlatten;
        currentPS.openingRotationDeg = openingRotationDeg;
        currentPS.vertexCount = vertexCount;
        currentPS.twistGradient = twistGradient;
        currentPS.twistWaveAmplitude = twistWaveAmplitude;
        currentPS.twistWaveFrequency = twistWaveFrequency;
        currentPS.twistWavePhase = twistWavePhase;
        
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
    paramSet.addChild("GrowthRate").setContent(Float.toString(ps.growthRate));
    paramSet.addChild("SideShift").setContent(Float.toString(ps.sideShift));
    paramSet.addChild("ShellThickness").setContent(Float.toString(ps.shellThickness));
    paramSet.addChild("OpeningFlatten").setContent(Float.toString(ps.openingFlatten));
    paramSet.addChild("OpeningRotationDeg").setContent(Float.toString(ps.openingRotationDeg));
    paramSet.addChild("TwistGradient").setContent(Float.toString(ps.twistGradient));
    paramSet.addChild("TwistWaveAmplitude").setContent(Float.toString(ps.twistWaveAmplitude));
    paramSet.addChild("TwistWaveFrequency").setContent(Float.toString(ps.twistWaveFrequency));
    paramSet.addChild("TwistWavePhase").setContent(Float.toString(ps.twistWavePhase));

    saveXML(xml, filePath);
}

class ParameterSet {
    String name;
    int vertexCount;
    int numberOfStepGrowth;
    float bendAngle;
    float twistAngle;
    float initGVL;
    float initSVL;
    float growthRate;
    float sideShift;
    float shellThickness;
    float openingFlatten;
    float openingRotationDeg;
    float twistGradient;
    float twistWaveAmplitude;
    float twistWaveFrequency;
    float twistWavePhase;
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
        newPS.growthRate = this.growthRate;
        newPS.sideShift = this.sideShift;
        newPS.shellThickness = this.shellThickness;
        newPS.openingFlatten = this.openingFlatten;
        newPS.openingRotationDeg = this.openingRotationDeg;
        newPS.twistGradient = this.twistGradient;
        newPS.twistWaveAmplitude = this.twistWaveAmplitude;
        newPS.twistWaveFrequency = this.twistWaveFrequency;
        newPS.twistWavePhase = this.twistWavePhase;
        
        if (this.controlVertices != null) {
            newPS.controlVertices = new PVector[this.controlVertices.length];
            for (int i = 0; i < this.controlVertices.length; i++) {
                newPS.controlVertices[i] = this.controlVertices[i].copy();
            }
        }
        
    return newPS;
  }
}

void resetParameters() {
    // 重置所有参数为指定的默认值
    setVertexCount(MIN_VERTEX_COUNT, false);
    numberOfStepGrowth = 50;
    bendAngle = 0.3;  // 60/200 因为界面值要除以200
    twistAngle = 0.05;  // 50/1000 因为界面值要除以1000
    growthRate = 1.03;
    initGVL = 1.5;  // 60/40 因为界面值要除以40
    initSVL = 3.0;  // 30/10 因为界面值要除以10
    sideShift = 0;
    shellThickness = 1;
    openingFlatten = 0;
    openingRotationDeg = 0;
    twistGradient = 0.0f;
    twistWaveAmplitude = 0.0f;
    twistWaveFrequency = 0.0f;
    twistWavePhase = 0.0f;
    
    // 重置当前参数集索引
    currentParameterSetIndex = -1;
    
    // 更新滑块显示
    if (sliderVertexCount != null) {
        sliderVertexCount.setValue(vertexCount);
    }
    sliderGrowthStep.setValue(50);  // Growth Steps
    if (sliderGrowthRate != null) {
        sliderGrowthRate.setValue(growthRate);
    }
    sliderBendAngle.setValue(60);   // Bending Angle
    sliderTwistAngle.setValue(50);  // Twisting Angle
    if (sliderConeHight != null) sliderConeHight.setValue(60);   // Cone Height
    if (sliderConeWidth != null) sliderConeWidth.setValue(30);   // Cone Width
    sliderSideShift.setValue(0);    // Side Shift
    sliderThickness.setValue(1);    // Thickness
    sliderOpeningFlatten.setValue(0);
    sliderOpeningRotation.setValue(0);
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
    
    // 设置下拉菜单显示"New Parameter"
    cp5.getController("Parameter Sets").setCaptionLabel("New Parameter");
    
    // 更新截面形状
    updateShapeFromControlVertices();
    // 重置向量
    resetVectors();
}
