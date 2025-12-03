void initSerial() {
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
}

void processSerial() {
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
}
