// 全局状态与常量
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
float openingFlatten = 0.0f;   // 0 表示圆形，1 表示扁平化最大
float openingRotationDeg = 0.0f; // 旋转角度（度）

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
