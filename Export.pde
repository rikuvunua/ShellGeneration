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
      exportFaces.add(new int[]{v1, v3, v4}); // 修改为正常顺序
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
  String dirPath = sketchPath("models/obj/");
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
