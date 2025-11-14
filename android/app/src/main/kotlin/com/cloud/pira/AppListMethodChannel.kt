package com.cloud.pira

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import androidx.core.graphics.drawable.toBitmap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

class AppListMethodChannel(private val context: Context) : MethodCallHandler {
    companion object {
        const val CHANNEL = "com.cloud.pira/app_list"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(AppListMethodChannel(context))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInstalledApps" -> {
                // Run the operation in a background thread to avoid blocking the UI
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val packageManager = context.packageManager
                        val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
                        
                        val appList = mutableListOf<Map<String, Any>>()
                        
                        for (appInfo in installedApps) {
                            // Skip system apps if they don't have a launcher
                            if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                                val launchIntent = packageManager.getLaunchIntentForPackage(appInfo.packageName)
                                if (launchIntent == null) {
                                    continue
                                }
                            }
                            
                            val appName = packageManager.getApplicationLabel(appInfo).toString()
                            val packageName = appInfo.packageName
                            
                            // Get app icon as base64 string
                            var iconBase64 = ""
                            try {
                                val appIcon = packageManager.getApplicationIcon(appInfo.packageName)
                                iconBase64 = drawableToBase64(appIcon)
                            } catch (e: Exception) {
                                // If we can't get the icon, we'll just leave it empty
                                iconBase64 = ""
                            }
                            
                            appList.add(mapOf(
                                "name" to appName,
                                "packageName" to packageName,
                                "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                                "icon" to iconBase64
                            ))
                        }
                        
                        // Sort by app name
                        val sortedAppList = appList.sortedBy { (it["name"] as? String)?.lowercase() ?: "" }
                        
                        // Return result on the main thread
                        withContext(Dispatchers.Main) {
                            result.success(sortedAppList)
                        }
                    } catch (e: Exception) {
                        // Return error on the main thread
                        withContext(Dispatchers.Main) {
                            result.error("APP_LIST_ERROR", "Failed to get installed apps", e.message)
                        }
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun drawableToBase64(drawable: Drawable): String {
        // Convert drawable to bitmap
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            drawable.toBitmap(96, 96, Bitmap.Config.ARGB_8888)
        }
        
        // Compress bitmap to byte array
        val byteArrayOutputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
        val byteArray = byteArrayOutputStream.toByteArray()
        
        // Convert byte array to base64 string
        return Base64.encodeToString(byteArray, Base64.NO_WRAP)
    }
}