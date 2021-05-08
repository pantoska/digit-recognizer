class Prediction {
  final double confidence;
  final int index;

  Prediction({this.confidence, this.index});

  factory Prediction.fromJson(Map<dynamic, dynamic> json) {
    return Prediction(
      confidence: json['confidence'],
      index: json['index'],
    );
  }
}
