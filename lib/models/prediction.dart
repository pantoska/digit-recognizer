class Prediction {
  final double confidence;
  final int label;

  Prediction({this.confidence, this.label});

  factory Prediction.fromJson(Map<dynamic, dynamic> json) {
    return Prediction(
      confidence: json['confidence'],
      label: json['label'],
    );
  }
}
