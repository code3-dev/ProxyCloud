package dev.amirzr.flutter_v2ray_client;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.net.VpnService;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import dev.amirzr.flutter_v2ray_client.v2ray.V2rayController;
import dev.amirzr.flutter_v2ray_client.v2ray.V2rayReceiver;
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener;

/**
 * FlutterV2rayClientPlugin
 */
public class FlutterV2rayPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel vpnControlMethod;
    private EventChannel vpnStatusEvent;
    private EventChannel.EventSink vpnStatusSink;
    private Activity activity;
    private Context appContext;
    private V2rayReceiver v2rayBroadCastReceiver;
    private Result pendingResult;
    private final ExecutorService executor = Executors.newCachedThreadPool();

    private static final int REQUEST_CODE_VPN_PERMISSION = 1001;
    private static final int REQUEST_CODE_POST_NOTIFICATIONS = 1002;
    
    private void requestBatteryOptimization(Activity activity) {
        // Only request once per app session to prevent unlimited requests
        if (activity != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Check if we've already requested battery optimization for this session
            android.content.SharedPreferences prefs = activity.getSharedPreferences("battery_optimization", Context.MODE_PRIVATE);
            boolean hasRequested = prefs.getBoolean("requested", false);
            
            if (!hasRequested) {
                // Request battery optimization exemption if not already granted
                android.os.PowerManager powerManager = (android.os.PowerManager) activity.getSystemService(Context.POWER_SERVICE);
                if (!powerManager.isIgnoringBatteryOptimizations(activity.getPackageName())) {
                    try {
                        Intent batteryIntent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                        batteryIntent.setData(Uri.parse("package:" + activity.getPackageName()));
                        activity.startActivity(batteryIntent);
                    } catch (ActivityNotFoundException e) {
                        // Fallback to general battery optimization settings
                        try {
                            Intent fallbackIntent = new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS);
                            activity.startActivity(fallbackIntent);
                        } catch (ActivityNotFoundException ignored) {
                            // If we can't open settings, continue without it
                        }
                    }
                }
                // Mark that we've requested battery optimization for this session
                prefs.edit().putBoolean("requested", true).apply();
            }
        }
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        vpnControlMethod = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_v2ray_client");
        vpnControlMethod.setMethodCallHandler(this);
        vpnStatusEvent = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_v2ray_client/status");
        vpnStatusEvent.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                vpnStatusSink = events;
                V2rayReceiver.vpnStatusSink = events;
                // Register the receiver if activity is available
                if (activity != null) {
                    if (v2rayBroadCastReceiver == null) {
                        v2rayBroadCastReceiver = new V2rayReceiver();
                    }
                    IntentFilter filter = new IntentFilter("V2RAY_CONNECTION_INFO");
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        activity.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED);
                    } else {
                        activity.registerReceiver(v2rayBroadCastReceiver, filter);
                    }
                }
            }

            @Override
            public void onCancel(Object arguments) {
                vpnStatusSink = null;
                V2rayReceiver.vpnStatusSink = null;
                // Unregister the receiver if it was registered
                if (v2rayBroadCastReceiver != null && activity != null) {
                    try {
                        activity.unregisterReceiver(v2rayBroadCastReceiver);
                    } catch (IllegalArgumentException e) {
                        // Receiver was not registered, ignore
                    }
                    v2rayBroadCastReceiver = null;
                }
            }
        });
        appContext = flutterPluginBinding.getApplicationContext();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        executor.submit(() -> {
            switch (call.method) {
                case "initializeV2Ray":
                    try {
                        V2rayController.init(appContext,
                                call.argument("notificationIconResourceName") != null
                                ? appContext.getResources().getIdentifier(
                                        call.argument("notificationIconResourceName"),
                                        call.argument("notificationIconResourceType"),
                                        appContext.getPackageName()) : 0,
                                call.argument("notificationIconResourceName") != null
                                ? call.argument("notificationIconResourceName") : "");
                        result.success(null);
                    } catch (Exception e) {
                        result.error("INITIALIZATION_ERROR", e.getMessage(), null);
                    }
                    break;
                case "startV2Ray":
                    try {
                        Boolean proxyOnly = call.argument("proxy_only");
                        V2rayController.changeConnectionMode(
                                proxyOnly != null && proxyOnly
                                        ? AppConfigs.V2RAY_CONNECTION_MODES.PROXY_ONLY
                                        : AppConfigs.V2RAY_CONNECTION_MODES.VPN_TUN);

                        V2rayController.StartV2ray(
                                activity != null ? activity : appContext,
                                call.argument("remark"),
                                call.argument("config"),
                                call.argument("blocked_apps"),
                                call.argument("bypass_subnets"));

                        AppConfigs.NOTIFICATION_DISCONNECT_BUTTON_NAME = call.argument("notificationDisconnectButtonName");

                        result.success(null);
                    } catch (Exception e) {
                        result.error("START_ERROR", e.getMessage(), null);
                    }
                    break;
                case "stopV2Ray":
                    try {
                        V2rayController.StopV2ray(activity != null ? activity : appContext);
                        result.success(null);
                    } catch (Exception e) {
                        result.error("STOP_ERROR", e.getMessage(), null);
                    }
                    break;
                case "getServerDelay":
                    try {
                        result.success(V2rayController.getV2rayServerDelay(call.argument("config"), call.argument("url")));
                    } catch (Exception e) {
                        result.success(-1);
                    }
                    break;
                case "getConnectedServerDelay":
                    executor.submit(() -> {
                        try {
                            String url = call.argument("url");
                            result.success(V2rayController.getConnectedV2rayServerDelayDirect(url));
                        } catch (Exception e) {
                            result.success(-1);
                        }
                    });
                    break;
                case "getCoreVersion":
                    result.success(V2rayController.getCoreVersion());
                    break;
                case "requestPermission":
                    if (activity == null) {
                        result.error("NO_ACTIVITY", "Activity is not available for permission request", null);
                        return;
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ActivityCompat.checkSelfPermission(activity,
                                Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(activity,
                                    new String[]{Manifest.permission.POST_NOTIFICATIONS},
                                    REQUEST_CODE_POST_NOTIFICATIONS);
                        }
                    }
                    
                    // Request battery optimization exemption for better performance on Android 12+
                    requestBatteryOptimization(activity);
                    
                    final Intent request = VpnService.prepare(activity);
                    if (request != null) {
                        pendingResult = result;
                        activity.startActivityForResult(request, REQUEST_CODE_VPN_PERMISSION);
                    } else {
                        result.success(true);
                    }
                    break;
                case "getConnectionState":
                    try {
                        AppConfigs.V2RAY_STATES state = V2rayController.getConnectionState();
                        result.success(state.name());
                    } catch (Exception e) {
                        result.success("V2RAY_DISCONNECTED");
                    }
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (v2rayBroadCastReceiver != null) {
            Context contextToUse = activity != null ? activity : appContext;
            try {
                contextToUse.unregisterReceiver(v2rayBroadCastReceiver);
            } catch (IllegalArgumentException e) {
                // Receiver was not registered, ignore
            }
            v2rayBroadCastReceiver = null;
        }
        vpnControlMethod.setMethodCallHandler(null);
        vpnStatusEvent.setStreamHandler(null);
        executor.shutdown();
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);
        // Register the receiver if vpnStatusSink is already set
        if (vpnStatusSink != null) {
            V2rayReceiver.vpnStatusSink = vpnStatusSink;
            if (v2rayBroadCastReceiver == null) {
                v2rayBroadCastReceiver = new V2rayReceiver();
            }
            IntentFilter filter = new IntentFilter("V2RAY_CONNECTION_INFO");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED);
            } else {
                activity.registerReceiver(v2rayBroadCastReceiver, filter);
            }
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // No additional cleanup required
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        binding.addActivityResultListener(this);

        // Re-register the receiver if vpnStatusSink is already set
        if (vpnStatusSink != null) {
            V2rayReceiver.vpnStatusSink = vpnStatusSink;
            if (v2rayBroadCastReceiver == null) {
                v2rayBroadCastReceiver = new V2rayReceiver();
            }
            IntentFilter filter = new IntentFilter("V2RAY_CONNECTION_INFO");
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.registerReceiver(v2rayBroadCastReceiver, filter, Context.RECEIVER_EXPORTED);
            } else {
                activity.registerReceiver(v2rayBroadCastReceiver, filter);
            }
        }
    }

    @Override
    public void onDetachedFromActivity() {
        // No additional cleanup required
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if (requestCode == REQUEST_CODE_VPN_PERMISSION) {
            if (resultCode == Activity.RESULT_OK) {
                pendingResult.success(true);
            } else {
                pendingResult.success(false);
            }
            pendingResult = null;
        }
        return true;
    }
}
