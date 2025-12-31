package io.flutter.plugins.calllogreader

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.CallLog
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import org.json.JSONObject

class CallLogReaderPlugin(private val context: Context? = null) : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var appContext: Context? = context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(
      flutterPluginBinding.binaryMessenger,
      "com.example.scam_detector_app/call_log_reader"
    )
    channel.setMethodCallHandler(this)
    appContext = flutterPluginBinding.applicationContext
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "readCallLogs" -> {
        val limit = call.argument<Int>("limit") ?: 50
        readCallLogs(limit, result)
      }
      "isCallLogSupported" -> {
        result.success(true)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun readCallLogs(limit: Int, result: Result) {
    try {
      val callLogs = JSONArray()
      
      val contentResolver: ContentResolver = appContext?.contentResolver ?: return result.error(
        "CONTEXT_ERROR", 
        "Application context is not available", 
        null
      )
      
      // Query call log
      val projection = arrayOf(
        CallLog.Calls.NUMBER,
        CallLog.Calls.CACHED_NAME,
        CallLog.Calls.DATE,
        CallLog.Calls.DURATION,
        CallLog.Calls.TYPE
      )
      
      val sortOrder = "${CallLog.Calls.DATE} DESC"
      
      val cursor: Cursor? = contentResolver.query(
        CallLog.Calls.CONTENT_URI,
        projection,
        null,
        null,
        sortOrder
      )
      
      cursor?.use { 
        val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
        val nameIndex = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
        val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
        val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)
        val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)
        
        var count = 0
        while (it.moveToNext() && count < limit) {
          val phoneNumber = if (numberIndex >= 0) it.getString(numberIndex) ?: "" else ""
          val callerName = if (nameIndex >= 0) it.getString(nameIndex) ?: "" else ""
          val callDate = if (dateIndex >= 0) it.getLong(dateIndex) else 0L
          val duration = if (durationIndex >= 0) it.getInt(durationIndex) else 0
          val callType = if (typeIndex >= 0) it.getInt(typeIndex) else CallLog.Calls.INCOMING_TYPE
          
          val callLogObject = JSONObject().apply {
            put("phoneNumber", phoneNumber)
            put("callerName", callerName)
            put("callDate", callDate)
            put("duration", duration)
            put("callType", getCallTypeString(callType))
            put("isScamSuspected", isScamSuspected(phoneNumber))
          }
          
          callLogs.put(callLogObject)
          count++
        }
      }
      
      result.success(callLogs.toString())
      
    } catch (e: SecurityException) {
      result.error(
        "PERMISSION_DENIED", 
        "Call log permission not granted. Please enable call log permissions in app settings.", 
        e.message
      )
    } catch (e: Exception) {
      result.error("READ_ERROR", "Failed to read call logs: ${e.message}", e.toString())
    }
  }
  
  private fun getCallTypeString(callType: Int): String {
    return when (callType) {
      CallLog.Calls.INCOMING_TYPE -> "incoming"
      CallLog.Calls.OUTGOING_TYPE -> "outgoing"
      CallLog.Calls.MISSED_TYPE -> "missed"
      else -> "incoming" // Default
    }
  }
  
  private fun isScamSuspected(phoneNumber: String): Boolean {
    val normalizedNumber = phoneNumber.lowercase().trim()
    
    // Check against known scam patterns
    val scamPatterns = listOf(
      "0700000000",
      "0711111111", 
      "0755555555",
      "0800000000",
      "unknown",
      "private",
      "restricted",
      "telemarketing",
      "suspicious"
    )
    
    if (scamPatterns.contains(normalizedNumber)) {
      return true
    }
    
    // Check for suspicious patterns
    if (normalizedNumber.contains("private") || 
        normalizedNumber.contains("restricted") ||
        normalizedNumber == "unknown") {
      return true
    }
    
    // Check for repeated digits (suspicious pattern)
    val digitsOnly = normalizedNumber.replace(Regex("[^0-9]"), "")
    if (digitsOnly.length >= 10) {
      val uniqueDigits = digitsOnly.toSet()
      if (uniqueDigits.size <= 2) {
        return true
      }
    }
    
    return false
  }
}