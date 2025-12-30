package io.flutter.plugins.smsreader

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONArray
import org.json.JSONObject

class SmsReaderPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  companion object {
    @Suppress("UNCHECKED_CAST")
    fun registerWith(registrar: PluginRegistry.Registrar) {
      val channel = MethodChannel(registrar.messenger(), "com.example.scam_detector_app/sms_reader")
      channel.setMethodCallHandler(SmsReaderPlugin(registrar.context()))
    }
  }

  constructor(context: Context) {
    this.context = context
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.scam_detector_app/sms_reader")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "readSms" -> {
        val limit = call.argument<Int>("limit") ?: 50
        readSms(limit, result)
      }
      "isSmsSupported" -> {
        result.success(true)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun readSms(limit: Int, result: Result) {
    try {
      val smsList = mutableListOf<Map<String, Any>>()
      val contentResolver = context.contentResolver
      
      // Query SMS content provider
      val uri = Uri.parse("content://sms/inbox")
      val projection = arrayOf("_id", "address", "body", "date")
      val sortOrder = "date DESC LIMIT $limit"
      
      val cursor: Cursor? = contentResolver.query(uri, projection, null, null, sortOrder)
      
      cursor?.use { c ->
        val senderIndex = c.getColumnIndex("address")
        val bodyIndex = c.getColumnIndex("body")
        val dateIndex = c.getColumnIndex("date")
        
        while (c.moveToNext()) {
          val sms = mutableMapOf<String, Any>()
          sms["sender"] = c.getString(senderIndex) ?: "Unknown"
          sms["body"] = c.getString(bodyIndex) ?: ""
          sms["timestamp"] = c.getLong(dateIndex)
          smsList.add(sms)
        }
      }
      
      result.success(smsList)
    } catch (e: Exception) {
      Log.e("SmsReaderPlugin", "Error reading SMS: ${e.message}")
      result.error("SMS_READ_ERROR", "Failed to read SMS: ${e.message}", null)
    }
  }
}