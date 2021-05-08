import 'dart:typed_data';
import 'dart:ui';
import 'package:digit_recognizer/services/image_processing.dart';
import 'package:digit_recognizer/services/recognizer.dart';
import 'package:digit_recognizer/utils/constants.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:tflite/tflite.dart';

class TfliteRecognizer extends Recognizer {
  TfliteRecognizer(ImageProcessing imageProcessing) : super(imageProcessing);

  @override
  Future<void> loadModel() {
    print('Process image with Tflite');

    Tflite.close();
    Stopwatch stopwatch = new Stopwatch()..start();

    var loadedModel = Tflite.loadModel(
      model: "assets/mnist-new.tflite",
      labels: "assets/mnist.txt",
    );
    print('Download time = ${stopwatch.elapsed.inMicroseconds} microseconds');

    return loadedModel;
  }

  @override
  Future recognize(List<Offset> points) async {
    final picture = imageProcessing.pointsToPicture(points);
    Uint8List bytes = await imageProcessing.imageToByteListUint8(
        picture, Constants.mnistImageSize);
    Stopwatch stopwatch = new Stopwatch()..start();
    var result = Tflite.runModelOnBinary(binary: bytes);
    print('Inference time = ${stopwatch.elapsed.inMicroseconds} microseconds');
    return result;
  }

  dispose() {
    Tflite.close();
  }
}
