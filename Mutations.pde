float getBendAngleWithMutations(int stepIndex) {
  return bendAngle;
}

// 扭转渐变叠波：在扭转角上叠加线性渐变 + 正弦波
float getTwistAngleWithMutations(int stepIndex) {
  if (!twistModEnabled) {
    return twistAngle;
  }
  float angle = twistAngle;
  angle += twistGradient * stepIndex;
  angle += sin(stepIndex * twistWaveFrequency + twistWavePhase) * twistWaveAmplitude;
  return angle;
}
