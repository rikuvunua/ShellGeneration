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

  writeSTLFile();
}

void writeSTLFile() {
  String dirPath = sketchPath("models/stl/");
  File dir = new File(dirPath);
  if (!dir.exists()) {
    dir.mkdirs();
  }

  // 获取已有的STL文件，匹配"shell_model_*.stl"模式
  String[] fileNames = dir.list();
  int maxNumber = 0;
  if (fileNames != null) {
    for (String name : fileNames) {
      if (name.startsWith("shell_model_") && name.endsWith(".stl")) {
        String numberStr = name.substring("shell_model_".length(), name.length() - 4);
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
  }
  int nextNumber = maxNumber + 1;
  String numberStr = String.format("%02d", nextNumber);

  String filePath = dirPath + "shell_model_" + numberStr + ".stl";

  try {
    BufferedOutputStream output = new BufferedOutputStream(new FileOutputStream(filePath));

    byte[] header = new byte[80];
    byte[] label = "ShellGeneration STL".getBytes();
    System.arraycopy(label, 0, header, 0, min(label.length, header.length));
    output.write(header);

    output.write(intToLittleEndian(exportFaces.size()));

    for (int[] face : exportFaces) {
      writeTriangle(output, face);
    }

    output.flush();
    output.close();
    println("3D模型已导出到 " + filePath);
  } catch (IOException e) {
    println("导出STL失败: " + e.getMessage());
    e.printStackTrace();
  }
}

void writeTriangle(BufferedOutputStream output, int[] face) throws IOException {
  // 旋转到 Y-up 视图并镜像 X 轴，让导出保持右旋；镜像会反转三角形朝向，因此写出时交换 v2/v3 保持外法线
  PVector v1 = transformForExport(exportVertices.get(face[0]));
  PVector v2 = transformForExport(exportVertices.get(face[1]));
  PVector v3 = transformForExport(exportVertices.get(face[2]));

  PVector normal = computeFaceNormal(v1, v3, v2); // 使用交换后的顺序得到正确的外法线

  ByteBuffer buffer = ByteBuffer.allocate(50).order(ByteOrder.LITTLE_ENDIAN);
  buffer.putFloat(normal.x);
  buffer.putFloat(normal.y);
  buffer.putFloat(normal.z);

  buffer.putFloat(v1.x);
  buffer.putFloat(v1.y);
  buffer.putFloat(v1.z);

  buffer.putFloat(v3.x);
  buffer.putFloat(v3.y);
  buffer.putFloat(v3.z);

  buffer.putFloat(v2.x);
  buffer.putFloat(v2.y);
  buffer.putFloat(v2.z);

  buffer.putShort((short)0);

  output.write(buffer.array());
}

byte[] intToLittleEndian(int value) {
  ByteBuffer buffer = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN);
  buffer.putInt(value);
  return buffer.array();
}

PVector computeFaceNormal(PVector v1, PVector v2, PVector v3) {
  PVector edge1 = PVector.sub(v2, v1, null);
  PVector edge2 = PVector.sub(v3, v1, null);
  PVector normal = PVector.cross(edge1, edge2, null);
  float magSq = normal.magSq();
  if (magSq > 0) {
    normal.mult(1.0f / sqrt(magSq));
  } else {
    normal.set(0, 0, 0);
  }
  return normal;
}

PVector transformForExport(PVector v) {
  // 旋转 180° around X (y、z 取反) 并镜像 X，以匹配常见 STL 预览的朝上与右旋方向
  return new PVector(-v.x, -v.y, -v.z);
}
