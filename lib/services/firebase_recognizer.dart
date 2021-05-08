import 'dart:ui';
import 'package:digit_recognizer/services/image_processing.dart';
import 'package:digit_recognizer/services/recognizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import 'dart:async';

class FirebaseRecognizer extends Recognizer {
  static final platform = const MethodChannel('digit_recognizer/image');

  FirebaseRecognizer(ImageProcessing imageProcessing) : super(imageProcessing);

  @override
  Future<void> loadModel() async {
    try {
      await platform.invokeMethod('loadModelFromFirebase');
    } catch (exception) {
      print('Failed on loading your model from Firebase: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }

  @override
  Future recognize(List<Offset> points) async {
    final picture = imageProcessing.pointsToPicture(points);
    var accuracy = await _predict(picture, Constants.mnistImageSize);

    return accuracy;
  }

  _predict(Picture pic, int size) async {
    var resultsList = [];
    var imageBuffer = await imageProcessing.imageToByteListUint8(pic, size);

    final List<double> result =
        await platform.invokeMethod('classifyImage', {'image': imageBuffer});

    for (int i = 0; i < result.length; i++) {
      if (result[i] > 0.1) {
        var object = {'confidence': result[i].toDouble(), 'index': i.toInt()};
        resultsList.add(object);
      }
    }
    return resultsList;
  }
}
