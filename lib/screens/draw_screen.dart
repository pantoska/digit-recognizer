import 'package:digit_recognizer/services/firebase_recognizer.dart';
import 'package:digit_recognizer/services/image_processing.dart';
import 'package:digit_recognizer/services/tflite_recognizer.dart';
import 'package:flutter/material.dart';
import '../models/prediction.dart';
import '../screens/drawing_painter.dart';
import '../screens/prediction_widget.dart';
import '../utils/constants.dart';

class DrawScreen extends StatefulWidget {
  @override
  _DrawScreenState createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final _points = <Offset>[];
  final toolChoice = const String.fromEnvironment("TOOL");
  ImageProcessing imageProcessing = ImageProcessing();
  List<Prediction> _prediction;
  bool initialize = false;
  var _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = toolChoice == "firebase"
        ? FirebaseRecognizer(imageProcessing)
        : TfliteRecognizer(imageProcessing);
    _initModel();
  }

  void _initModel() async {
    await _recognizer.loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digit Recognizer'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 10,
          ),
          _drawCanvasWidget(),
          SizedBox(
            height: 20,
          ),
          PredictionWidget(
            predictions: _prediction,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.clear),
        onPressed: () {
          setState(() {
            _points.clear();
            _prediction.clear();
          });
        },
      ),
    );
  }

  Widget _drawCanvasWidget() {
    return Container(
      width: Constants.canvasSize + Constants.borderSize * 2,
      height: Constants.canvasSize + Constants.borderSize * 2,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: Constants.borderSize,
        ),
      ),
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          Offset _localPosition = details.localPosition;
          if (_localPosition.dx >= 0 &&
              _localPosition.dx <= Constants.canvasSize &&
              _localPosition.dy >= 0 &&
              _localPosition.dy <= Constants.canvasSize) {
            setState(() {
              _points.add(_localPosition);
            });
          }
        },
        onPanEnd: (DragEndDetails details) {
          _points.add(null);
          _recognize();
        },
        child: CustomPaint(
          painter: DrawingPainter(_points),
        ),
      ),
    );
  }

  void _recognize() async {
    List<dynamic> prediction = await _recognizer.recognize(_points);
    setState(() {
      _prediction =
          prediction.map((json) => Prediction.fromJson(json)).toList();
    });
  }
}
