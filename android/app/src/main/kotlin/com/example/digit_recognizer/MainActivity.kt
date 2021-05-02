package com.example.digit_recognizer

import android.util.Log
import android.widget.Toast
import com.google.android.gms.tasks.Task
import com.google.firebase.ml.common.modeldownload.FirebaseModelDownloadConditions
import com.google.firebase.ml.common.modeldownload.FirebaseModelManager
import com.google.firebase.ml.custom.FirebaseCustomRemoteModel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.Interpreter
import java.io.File
import java.nio.ByteBuffer

class MainActivity: FlutterActivity() {

    private val CHANNEL = "samples.flutter.dev/battery"
    private  val OUTPUT_CLASSES_COUNT = 10

    private var interpreter: Interpreter? = null
    var isInitialized = false

    private var modelInputSize: Int = 0 // will be inferred from TF Lite model

    private fun initializeInterpreter(result: Task<File>) {
        var options = Interpreter.Options()
        var interpreter = Interpreter( result.result, options)
        options.setUseNNAPI(true)

        this.interpreter = interpreter
        isInitialized = true
    }


    private fun classify(bitmap: ByteBuffer): DoubleArray {
        if (!isInitialized) {
            throw IllegalStateException("TF Lite Interpreter is not initialized yet.")
        }

        var startTime: Long
        var elapsedTime: Long

        startTime = System.nanoTime()
        elapsedTime = (System.nanoTime() - startTime) / 1000000
        Log.d("info", "Preprocessing time = " + elapsedTime + "ms")

        startTime = System.nanoTime()
        val result = Array(1) { FloatArray(OUTPUT_CLASSES_COUNT) }
        interpreter?.run(bitmap, result)
        elapsedTime = (System.nanoTime() - startTime) / 1000000
        Log.d("info", "Inference time = " + elapsedTime + "ms")

        val new = result[0].map { i -> i.toDouble() }.toDoubleArray()
        return new
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call, result ->
      if (call.method == "getBatteryLevel") {
          val remoteModel = FirebaseCustomRemoteModel.Builder("mnist").build()

          val conditions = FirebaseModelDownloadConditions.Builder()
                  .requireWifi()
                  .build()
          FirebaseModelManager.getInstance().download(remoteModel, conditions)
                  .addOnCompleteListener {
                      if (it.isSuccessful) {
                          FirebaseModelManager.getInstance().getLatestModelFile(remoteModel)
                                  .addOnCompleteListener {
                                      if (it.isSuccessful && it.result != null) {
                                          Toast.makeText(this@MainActivity,
                                                  "Model downloaded", Toast.LENGTH_SHORT).show()
                                          initializeInterpreter(it)

                                          result.success(modelInputSize)
                                          //Get the model file by calling "it.result"
                                      } else {
                                          Toast.makeText(this@MainActivity,
                                                  "Unable to get model file", Toast.LENGTH_SHORT).show()
                                          result.error("UNAVAILABLE", "Battery level not available.", null)
                                      }
                                  }
                      } else {
                          Toast.makeText(this@MainActivity,
                                  "Unable to download model", Toast.LENGTH_SHORT).show()
                          result.notImplemented()
                      }
                  }
            }
      else if (call.method == "dupa") {
          val picture = call.argument<ByteArray>("picture")

          io.flutter.Log.d("beka", picture.toString())

          val buffer = ByteBuffer.wrap(picture)
          val valuereturn = classify(buffer)
          result.success(valuereturn)
      }
    }
  }
}
