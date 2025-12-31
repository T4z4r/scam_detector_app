package com.example.scam_detector_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.smsreader.SmsReaderPlugin
import io.flutter.plugins.calllogreader.CallLogReaderPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register SMS Reader Plugin for Flutter v2 embedding
        flutterEngine.plugins.add(SmsReaderPlugin(applicationContext))
        
        // Register Call Log Reader Plugin
        flutterEngine.plugins.add(CallLogReaderPlugin(applicationContext))
    }
}
