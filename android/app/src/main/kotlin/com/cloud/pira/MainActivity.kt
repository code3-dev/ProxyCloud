package com.cloud.pira

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.cloud.pira.DownloadMethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cloud.pira/vpn_control"
    private var vpnControlChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Preload app list in background when app starts
        preloadAppList()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppListMethodChannel.registerWith(flutterEngine, context)
        PingMethodChannel.registerWith(flutterEngine, context)
        SettingsMethodChannel.registerWith(flutterEngine, context)
        DownloadMethodChannel.registerWith(flutterEngine, context)
        
        // Create VPN control channel
        vpnControlChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    override fun onResume() {
        super.onResume()
        handleIntent(intent)
        
        // Optimize battery usage when app is in foreground
        // Only request battery optimization once per app session
        requestBatteryOptimization()
    }
    
    private fun requestBatteryOptimization() {
        // Check if we've already requested battery optimization for this session
        val prefs = getSharedPreferences("battery_optimization", Context.MODE_PRIVATE)
        val hasRequested = prefs.getBoolean("requested", false)
        
        if (!hasRequested && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Request battery optimization exemption if not already granted
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                    
                    // Mark that we've requested battery optimization for this session
                    prefs.edit().putBoolean("requested", true).apply()
                } catch (e: ActivityNotFoundException) {
                    // Fallback to general battery optimization settings
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                        
                        // Mark that we've requested battery optimization for this session
                        prefs.edit().putBoolean("requested", true).apply()
                    } catch (ignored: ActivityNotFoundException) {
                        // If we can't open settings, continue without it
                    }
                }
            } else {
                // Already exempted from battery optimization, mark as requested
                prefs.edit().putBoolean("requested", true).apply()
            }
        }
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "FROM_DISCONNECT_BTN") {
            // Send message to Flutter to disconnect VPN
            vpnControlChannel?.invokeMethod("disconnectFromNotification", null)
        }
    }
    
    private fun preloadAppList() {
        // Preload app list in background to cache it for faster access later
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // This will trigger the app list loading and caching
                val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, AppListMethodChannel.CHANNEL)
                channel.invokeMethod("getInstalledApps", null)
            } catch (e: Exception) {
                // Ignore errors during preload
            }
        }
    }
}