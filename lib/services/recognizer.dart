import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import 'package:tflite/tflite.dart';
import 'dart:async';

final _canvasCullRect = Rect.fromPoints(
  Offset(0, 0),
  Offset(Constants.imageSize, Constants.imageSize),
);

final _whitePaint = Paint()
  ..strokeCap = StrokeCap.round
  ..color = Colors.white
  ..strokeWidth = Constants.strokeWidth;

final _bgPaint = Paint()..color = Colors.black;

class Recognizer {
  static final platform = const MethodChannel('samples.flutter.dev/battery');

  loadModelFromFirebase() async {
    try {
      final result = await platform.invokeMethod('getBatteryLevel');
      return result;
    } catch (exception) {
      print('Failed on loading your model from Firebase: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }

  Future<String> loadModel() async {
    Tflite.close();
    await loadModelFromFirebase();

    // print("!!!!!!!!!!!!!!result MOdel" + modelFile.toString());

    try {
      var model;
      model = await Tflite.loadModel(
        model: "assets/mnist-new.tflite",
        labels: "assets/mnist.txt",
      );
      return model;
    } catch (exception) {
      print(
          'Failed on loading your model to the TFLite interpreter: $exception');
      print('The program will not be resumed');
      rethrow;
    }
  }

  dispose() {
    Tflite.close();
  }

  Future<Uint8List> previewImage(List<Offset> points) async {
    final picture = _pointsToPicture(points);

    final image = await picture.toImage(
        Constants.mnistImageSize, Constants.mnistImageSize);
    var pngBytes = await image.toByteData(format: ImageByteFormat.png);

    return pngBytes.buffer.asUint8List();
  }

  Future recognize(List<Offset> points) async {
    final picture = _pointsToPicture(points);

    Uint8List bytes = await _predict(picture, Constants.mnistImageSize);

    var prediction = await _predictTflite(bytes);

    print("!!!!!!!!!!!" + prediction.toString());

    return prediction;
  }

  Future _predictTflite(Uint8List bytes) {
    return Tflite.runModelOnBinary(binary: bytes);
  }

  _predict(Picture pic, int size) async {
    final img = await pic.toImage(size, size);
    final imgBytes = await img.toByteData();
    final resultBytes = Float32List(size * size);
    final buffer = Float32List.view(resultBytes.buffer);

    int index = 0;

    for (int i = 0; i < imgBytes.lengthInBytes; i += 4) {
      final r = imgBytes.getUint8(i);
      final g = imgBytes.getUint8(i + 1);
      final b = imgBytes.getUint8(i + 2);
      buffer[index++] = (r + g + b) / 3.0 / 255.0;
    }

    print(resultBytes.buffer.asUint8List());

    final List<double> result = await platform
        .invokeMethod('dupa', {'picture': resultBytes.buffer.asUint8List()});

    var newList = [];

    for (int i = 0; i < result.length; i++) {
      if (result[i] > 0.1) {
        var object = {
          'confidence': result[i].toDouble(),
          'index': i.toInt(),
          'label': i.toString()
        };
        newList.add(object);
      }
    }

    print("!!!!!!!!!patkio" + newList.toString());

    return resultBytes.buffer.asUint8List();
    // return object;
  }

  Picture _pointsToPicture(List<Offset> points) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, _canvasCullRect)
      ..scale(Constants.mnistImageSize / Constants.canvasSize);

    canvas.drawRect(
        Rect.fromLTWH(0, 0, Constants.imageSize, Constants.imageSize),
        _bgPaint);

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], _whitePaint);
      }
    }

    return recorder.endRecording();
  }
}
