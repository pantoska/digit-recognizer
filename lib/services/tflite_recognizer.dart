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
    Tflite.close();

    return Tflite.loadModel(
      model: "assets/mnist-new.tflite",
      labels: "assets/mnist.txt",
    );
  }

  @override
  Future recognize(List<Offset> points) async {
    final picture = imageProcessing.pointsToPicture(points);
    Uint8List bytes = await imageProcessing.imageToByteListUint8(
        picture, Constants.mnistImageSize);
    return Tflite.runModelOnBinary(binary: bytes);
  }

  dispose() {
    Tflite.close();
  }
}
