package com.example.myapp

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import io.flutter.embedding.android.FlutterActivity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL =  "samples.flutter.dev/battery"
    val PICK_PDF_FILE = 2
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler{
            call, result ->
            if(call.method == "getBatteryLevel"){
                val batteryLevel = getBatteryLevel()
                if(batteryLevel != -1){
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery Level not available", null)
                }
            } else if (call.method == "openFilePicker"){
                val uri = Uri.parse(call.argument("uri"))
                openFilePicker(uri)
            }
            else {
                result.notImplemented()
            }
        }
    }
    private fun getBatteryLevel(): Int{
        val batteryLevel: Int
        if(VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP ){
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }
        return batteryLevel
    }
    private fun openFilePicker(initialUri: Uri){
        //console.log(initialUri)
        print("hello")
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply{
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
        }
        startActivityForResult(intent, PICK_PDF_FILE)
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, resultData: Intent?) {
        super.onActivityResult(requestCode, resultCode, resultData)
        print("result is here")
    }
}
