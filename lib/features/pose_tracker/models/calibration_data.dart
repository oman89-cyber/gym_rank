class CalibrationData {
  final double baselineAngle;
  final double limbLength;
  final double shoulderWidth;
  final double hipWidth;
  final double verticalZ; // average Z of spine in neutral pose

  const CalibrationData({
    this.baselineAngle = 180.0,
    this.limbLength = 0.0,
    this.shoulderWidth = 0.0,
    this.hipWidth = 0.0,
    this.verticalZ = 0.0,
  });
}
