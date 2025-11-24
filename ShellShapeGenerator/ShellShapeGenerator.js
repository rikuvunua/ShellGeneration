//æ“ä½œå¯èƒ½ãªå¤‰æ•°ã®å®£è¨€ã¨ä»£å…¥======================
let bendAngle=0.3;//æ›²ã’è§’åº¦
let twistAngle=0.05;//ã²ã­ã‚Šè§’åº¦
let initGVL=1.5;//ä¸­å¿ƒãƒ™ã‚¯ãƒˆãƒ«ã®é•·ã•ã®åˆæœŸå€¤
let initSVL=3;//æ¨ªãƒ™ã‚¯ãƒˆãƒ«ã®é•·ã•ã®åˆæœŸå€¤
let sideShift=0;

let growthRate=1.03;//æˆé•·çŽ‡
let numberOfStepGrowth=100;


var shape=new Array(12);
shape[0]=1;
shape[1]=1;
shape[2]=1;
shape[3]=1;
shape[4]=1;
shape[5]=1;
shape[6]=1;
shape[7]=1;
shape[8]=1;
shape[9]=1;
shape[10]=1;
shape[11]=1;



//é ‚ç‚¹ã®ä½ç½®ã‚’ç¤ºã™ãƒ™ã‚¯ãƒˆãƒ«ã®å®£è¨€ã¨åˆæœŸå€¤ã®ä»£å…¥===========================
var rings=new Array(100);
for (i=0; i<12; i++){
  rings[i]=new Array(12);
}
for (i=0; i<100; i++){
  rings[i]=[];
  for (j=0; j<12; j++){
    rings[i][j]=new p5.Vector(0,0,0);
}}

//æˆé•·ãƒ™ã‚¯ãƒˆãƒ«ã¨æ¨ªãƒ™ã‚¯ãƒˆãƒ«ã®é•·ã•ã®é…åˆ—å®£è¨€ã¨å€¤ã®ä»£å…¥=============
var GVLength=new Array(100);
var SVLength=new Array(100);
for (i=0; i<100; i++){
  GVLength[i]=initGVL*Math.pow(growthRate,i);
  SVLength[i]=initSVL*Math.pow(growthRate,i);
}

//æˆé•·ãƒ™ã‚¯ãƒˆãƒ«ã¨ã€æ¨ªãƒ™ã‚¯ãƒˆãƒ«ã€ä¸­å¿ƒãƒ™ã‚¯ãƒˆãƒ«ã®å®£è¨€ã¨åˆæœŸå€¤ã®ä»£å…¥=======
var normGV=new Array(100);
var normSV=new Array(100);
var GV=new Array(100);
var SV=new Array(100);
var CV=new Array(100);
for (i=0; i<100; i++){
    normGV[i]=new p5.Vector(0,0,1);
    GV[i]=new p5.Vector(0,0,initGVL);
    CV[i]=new p5.Vector(0,0,initGVL);
    normSV[i]=new p5.Vector(0,1,0);
    SV[i]=new p5.Vector(0,initSVL,0);
}

//åŸºæº–ãƒ™ã‚¯ãƒˆãƒ«ã®è¨ˆç®—==========================
for (i=1; i<100; i++){
  normGV[i]=rotation(normGV[i-1],normSV[i-1],bendAngle);
  normGV[i].normalize();
  normSV[i]=rotation(normSV[i-1],normGV[i],twistAngle);
  normSV[i].normalize();
  GV[i]=p5.Vector.mult(normGV[i],GVLength[i]);
  SV[i]=p5.Vector.mult(normSV[i],SVLength[i]);
  CV[i]=p5.Vector.add(CV[i-1],GV[i]);
}

//é ‚ç‚¹ãƒ™ã‚¯ãƒˆãƒ«ã®è¨ˆç®—==========================
for (i=0; i<100; i++){
  for (j=0; j<12; j++){
    let vv1=rotation(SV[i],normGV[i],j*3.141592/6);//SVã®å›žè»¢
    rings[i][j]=p5.Vector.add(CV[i],vv1);
}}

//=========GUIã®è¦ç´ ã‚’å®£è¨€




  //=====================


function setup() {

  textTitle=createP('Shell Shape Generator');
  textTitle.position(260,-20);
  textTitle.style('font-size','48px');
  textTitle.style('font-weight','bold');
  let cp;
  cp=createCanvas(940, 600, WEBGL);
  cp.position(20,100);

  sliderSetting();
  radioButtonSetting();

}

function draw(){
  orbitControl();
  background(100);
  //drawXYZaxis();
  //drawCenter();
  //drawSide();
  //drawOpenRings();

  if (radio.value()==='1'){
    drawCenter();
    drawOpenRings();
  }else {
    drawCenter();
    drawSurface();
  }

  numberOfStepGrowth=sliderGrowthStep.value();
  bendAngle=0.005*sliderBendAngle.value();
  twistAngle=0.001*sliderTwistAngle.value();
  initGVL=0.025*sliderConeHight.value();
  initSVL=0.1*sliderConeWidth.value();
  sideShift=0.01*sliderSideShift.value();

  resetVectors();


}

//aVectorã‚’ã€bVectorï¼ˆè¦æ ¼åŒ–æ¸ˆã¿ï¼‰ã®å‘¨ã‚Šã«rAngleå›žè»¢ã•ã›ã‚‹é–¢æ•°
function rotation(aVector,bVector,rAngle){
  let px=aVector.x;
  let py=aVector.y;
  let pz=aVector.z;
  let norVx=bVector.x;
  let norVy=bVector.y;
  let norVz=bVector.z;
  let angle=rAngle;
  var sin=Math.sin(angle);
  var cos=Math.cos(angle);
  var newPx=(cos+norVx*norVx*(1-cos))*px+(norVx*norVy*(1-cos)-norVz*sin)*py+(norVz*norVx*(1-cos)+norVy*sin)*pz;
  var newPy=(norVx*norVy*(1-cos)+norVz*sin)*px+(cos+norVy*norVy*(1-cos))*py+(norVy*norVz*(1-cos)-norVx*sin)*pz;
  var newPz=(norVz*norVx*(1-cos)-norVy*sin)*px+(norVy*norVz*(1-cos)+norVx*sin)*py+(cos+norVz*norVz*(1-cos))*pz;
  let resultingVector=new p5.Vector(newPx,newPy,newPz);
  return resultingVector;
}

//XYZè»¸ã‚’æã
function drawXYZaxis(){
  strokeWeight(1);
  line(-500,0,0,500,0,0);
  line(0,-500,0,0,500,0);
  line(0,0,-500,0,0,500);
}


function drawCenter(){
strokeWeight(1);
for (i=0; i<numberOfStepGrowth-1; i++){
  connectVector(CV[i],CV[i+1]);
}
}

function drawRadial(){
  strokeWeight(2);

    for (j=0; j<12; j++){
      connectVector(CV[99],rings[99][j]);
    }
  }


function drawSide(){
strokeWeight(2);
for (i=0; i<99; i++){
  for (j=0; j<12; j++){
    connectVector(rings[i][j],rings[i+1][j]);
  }
}
}

function drawOpenRings(){
  strokeWeight(1);
  for (i=0; i<numberOfStepGrowth-1; i++){
  beginShape();
  for (j=0; j<12; j++){
    vertex(rings[i][j].x,rings[i][j].y,rings[i][j].z);
  }
  vertex(rings[i][0].x,rings[i][0].y,rings[i][0].z);
  endShape();
}
}






//2ã¤ã®ãƒ™ã‚¯ãƒˆãƒ«ã®å…ˆç«¯ã‚’ç¹‹ã’ã‚‹ç·šã‚’æã
function connectVector(aVector,bVector){
  let px=aVector.x;
  let py=aVector.y;
  let pz=aVector.z;
  let qx=bVector.x;
  let qy=bVector.y;
  let qz=bVector.z;
  beginShape(LINES);
    vertex(px,py,pz);
    vertex(qx,qy,qz);
  endShape();
}

//æˆé•·ãƒ™ã‚¯ãƒˆãƒ«ã¨æ¨ªãƒ™ã‚¯ãƒˆãƒ«ã®å†è¨­å®š
function resetLength(){
for (i=0; i<100; i++){
  Length[i]=initGVL*Math.pow(growthRate,i);
  SVLength[i]=initSVL*Math.pow(growthRate,i);
}}

//GVã‹ã‚‰CVã‚’ç®—å‡º
function resetCV(){
  var v1=new p5.Vector
  CV[0].set(GV[0]);
  for (i=1; i<100; i++){
    CV[i]
  }
}

function drawSurface(){
  strokeWeight(0.5);
  for (i=0; i<numberOfStepGrowth-1; i++){
    for (j=0; j<11; j++){
      beginShape();
        vertex(rings[i][j].x,rings[i][j].y,rings[i][j].z);
        vertex(rings[i][j+1].x,rings[i][j+1].y,rings[i][j+1].z);
        vertex(rings[i+1][j+1].x,rings[i+1][j+1].y,rings[i+1][j+1].z);
        vertex(rings[i][j].x,rings[i][j].y,rings[i][j].z);
      endShape();
      beginShape();
        vertex(rings[i][j].x,rings[i][j].y,rings[i][j].z);
        vertex(rings[i+1][j].x,rings[i+1][j].y,rings[i+1][j].z);
        vertex(rings[i+1][j+1].x,rings[i+1][j+1].y,rings[i+1][j+1].z);
        vertex(rings[i][j].x,rings[i][j].y,rings[i][j].z);
      endShape();
      }
      beginShape();
        vertex(rings[i][11].x,rings[i][11].y,rings[i][11].z);
        vertex(rings[i][0].x,rings[i][0].y,rings[i][0].z);
        vertex(rings[i+1][0].x,rings[i+1][0].y,rings[i+1][0].z);
        vertex(rings[i][11].x,rings[i][11].y,rings[i][11].z);
      endShape();
      beginShape();
        vertex(rings[i][11].x,rings[i][11].y,rings[i][11].z);
        vertex(rings[i+1][11].x,rings[i+1][11].y,rings[i+1][11].z);
        vertex(rings[i+1][0].x,rings[i+1][0].y,rings[i+1][0].z);
        vertex(rings[i][11].x,rings[i][11].y,rings[i][11].z);
      endShape();
  }
}

//====ã‚¹ãƒ©ã‚¤ãƒ€ãƒ¼ã®è¨­å®š=====================
function sliderSetting(){
  //=========sliderã®è¨­å®š
  let sliderLength='670px';
  let kankaku=50;
  let sliderLeftEnd=270;
  let sliderYposition=740;
  let titleYposition=694;
  let labelLeftEnd=30;

  sliderGrowthStep = createSlider(0, 100, 100);
  sliderGrowthStep.position(sliderLeftEnd, sliderYposition);
  sliderGrowthStep.style('width', sliderLength);
  textGrowthStep=createP('Growth');
  textGrowthStep.position(labelLeftEnd,titleYposition);
  textGrowthStep.style('font-size','32px');
  textTitle.style('font-weight','bold');

  sliderBendAngle = createSlider(-100, 100, 60);
  sliderBendAngle.position(sliderLeftEnd, sliderYposition+kankaku);
  sliderBendAngle.style('width', sliderLength);
  textBendAngle=createP('Bending Angle');
  textBendAngle.position(labelLeftEnd,titleYposition+kankaku);
  textBendAngle.style('font-size','32px');
  textTitle.style('font-weight','bold');

  sliderTwistAngle = createSlider(-200, 200, 50);
  sliderTwistAngle.position(sliderLeftEnd, sliderYposition+kankaku*2);
  sliderTwistAngle.style('width', sliderLength);
  textTwistAngle=createP('Twisting Angle');
  textTwistAngle.position(labelLeftEnd,titleYposition+kankaku*2);
  textTwistAngle.style('font-size','32px');
    textTitle.style('font-weight','bold');

  sliderConeHight= createSlider(0, 100, 60);
  sliderConeHight.position(sliderLeftEnd, sliderYposition+kankaku*3);
  sliderConeHight.style('width', sliderLength);
  textConeHight=createP('ConeHight');
  textConeHight.position(labelLeftEnd,titleYposition+kankaku*3);
  textConeHight.style('font-size','32px');
    textTitle.style('font-weight','bold');

  sliderConeWidth= createSlider(0, 100, 30);
  sliderConeWidth.position(sliderLeftEnd, sliderYposition+kankaku*4);
  sliderConeWidth.style('width', sliderLength);
  textConeWidth=createP('ConeWidth');
  textConeWidth.position(labelLeftEnd,titleYposition+kankaku*4);
  textConeWidth.style('font-size','32px');
  textTitle.style('font-weight','bold');

  sliderSideShift= createSlider(-100, 100, 0);
  sliderSideShift.position(sliderLeftEnd, sliderYposition+kankaku*5);
  sliderSideShift.style('width', sliderLength);
  textSideShift=createP('Side Shift');
  textSideShift.position(labelLeftEnd,titleYposition+kankaku*5);
  textSideShift.style('font-size','32px');
  textTitle.style('font-weight','normal');
}





function resetVectors(){
  //åŸºæº–ãƒ™ã‚¯ãƒˆãƒ«ã®è¨ˆç®—==========================
  for (i=0; i<100; i++){
    GVLength[i]=initGVL*Math.pow(growthRate,i);
    SVLength[i]=initSVL*Math.pow(growthRate,i);
  }

  for (i=1; i<100; i++){
    normGV[i]=rotation(normGV[i-1],normSV[i-1],bendAngle);
    normGV[i].normalize();
    normSV[i]=rotation(normSV[i-1],normGV[i],twistAngle);
    normSV[i].normalize();
    GV[i]=p5.Vector.mult(normGV[i],GVLength[i]);
    SV[i]=p5.Vector.mult(normSV[i],SVLength[i]);
    CV[i]=p5.Vector.add(CV[i-1],GV[i]);
  }
  //é ‚ç‚¹ãƒ™ã‚¯ãƒˆãƒ«ã®è¨ˆç®—==========================
  for (i=0; i<100; i++){
      let vertical=rotation(SV[i],normGV[i],3.141592/2);
      let vertical2=p5.Vector.mult(vertical,sideShift);
    for (j=0; j<12; j++){
      let vv1=rotation(SV[i],normGV[i],j*3.141592/6);//SVã®å›žè»¢
      //vv1.mult(shape[j]);
      let vv2=p5.Vector.add(vertical2,vv1);
      rings[i][j]=p5.Vector.add(CV[i],vv2);
  }}
}

function radioButtonSetting(){
  radio = createRadio();
  radio.position(30,1040);
  radio.option('Show Opening Rings (If your PC is slow, try this setting!)',1);
  radio.option('Show Shell Surface',2);
  radio.style('checked');
  radio.value('2');
  radio.style('width', '860');
  radio.style('font-size', '32px');
  textAlign(CENTER);
}
