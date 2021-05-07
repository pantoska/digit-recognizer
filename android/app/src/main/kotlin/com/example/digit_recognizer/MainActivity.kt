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

const val CHANNEL = "digit_recognizer/image"
const  val OUTPUT_CLASSES_COUNT = 10

class MainActivity: FlutterActivity() {

    private var interpreter: Interpreter? = null
    private var isInitialized = false


    private fun initializeInterpreter(result: Task<File>) {
        val options = Interpreter.Options()
        val interpreter = Interpreter( result.result, options)
        options.setUseNNAPI(true)

        this.interpreter = interpreter
        isInitialized = true
    }


    private fun classify(bitmap: ByteBuffer): DoubleArray {
        if (!isInitialized) {
            throw IllegalStateException("TF Lite Interpreter is not initialized yet.")
        }

        val startTime = System.nanoTime()
        val result = Array(1) { FloatArray(OUTPUT_CLASSES_COUNT) }
        interpreter?.run(bitmap, result)
        val elapsedTime = (System.nanoTime() - startTime) / 1000000
        Log.d("info", "Inference time = " + elapsedTime + "ms")

        return result[0].map { i -> i.toDouble() }.toDoubleArray()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call, result ->
      if (call.method == "loadModelFromFirebase") {
          val remoteModel = FirebaseCustomRemoteModel.Builder("mnist").build()

          val conditions = FirebaseModelDownloadConditions.Builder()
                  .requireWifi()
                  .build()
          FirebaseModelManager.getInstance().download(remoteModel, conditions)
                  .addOnCompleteListener { task ->
                      if (task.isSuccessful) {
                          FirebaseModelManager.getInstance().getLatestModelFile(remoteModel)
                                  .addOnCompleteListener {
                                      if (it.isSuccessful && it.result != null) {
                                          Toast.makeText(this@MainActivity,
                                                  "Model downloaded", Toast.LENGTH_SHORT).show()
                                          initializeInterpreter(it)
                                          result.success(true)
                                      } else {
                                          Toast.makeText(this@MainActivity,
                                                  "Unable to get model file", Toast.LENGTH_SHORT).show()
                                          result.error("UNAVAILABLE", "Unable to get model file", null)
                                      }
                                  }
                      } else {
                          Toast.makeText(this@MainActivity,
                                  "Unable to download model", Toast.LENGTH_SHORT).show()
                          result.notImplemented()
                      }
                  }
            }
      else if (call.method == "classifyImage") {
          val picture = call.argument<ByteArray>("image")
          val buffer = ByteBuffer.wrap(picture!!)
          val accuracy = classify(buffer)
          result.success(accuracy)
      }
    }
  }
}
