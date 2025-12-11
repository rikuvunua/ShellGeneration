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
  currentState.openingFlatten = openingFlatten;
  currentState.openingRotationDeg = openingRotationDeg;
  currentState.twistGradient = twistGradient;
  currentState.twistWaveAmplitude = twistWaveAmplitude;
  currentState.twistWaveFrequency = twistWaveFrequency;
  currentState.twistWavePhase = twistWavePhase;
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
            // 更新XML
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
    // 从重做栈获取状态并应用
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
  openingFlatten = state.openingFlatten;
  openingRotationDeg = state.openingRotationDeg;
  twistGradient = state.twistGradient;
  twistWaveAmplitude = state.twistWaveAmplitude;
  twistWaveFrequency = state.twistWaveFrequency;
  twistWavePhase = state.twistWavePhase;

  if (state.vertexCount != vertexCount) {
    setVertexCount(state.vertexCount, false);
  }

  if (state.controlVertices != null) {
    for (int i = 0; i < controlVertices.length && i < state.controlVertices.length; i++) {
      controlVertices[i].set(state.controlVertices[i]);
    }
  }
  updateShapeFromControlVertices();
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
  float openingFlatten;
  float openingRotationDeg;
  float twistGradient;
  float twistWaveAmplitude;
  float twistWaveFrequency;
  float twistWavePhase;
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
      newState.openingFlatten = this.openingFlatten;
      newState.openingRotationDeg = this.openingRotationDeg;
      newState.twistGradient = this.twistGradient;
      newState.twistWaveAmplitude = this.twistWaveAmplitude;
      newState.twistWaveFrequency = this.twistWaveFrequency;
      newState.twistWavePhase = this.twistWavePhase;
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
