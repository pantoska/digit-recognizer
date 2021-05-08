import 'dart:ui';

import 'package:digit_recognizer/services/image_processing.dart';
import 'package:flutter/material.dart';

abstract class Recognizer {
  ImageProcessing imageProcessing;

  Recognizer(this.imageProcessing);

  Future<void> loadModel();
  Future recognize(List<Offset> points);
}
