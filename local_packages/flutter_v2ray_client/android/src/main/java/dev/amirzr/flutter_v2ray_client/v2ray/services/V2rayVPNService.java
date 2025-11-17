package dev.amirzr.flutter_v2ray_client.v2ray.services;

import android.app.Service;
import android.content.Intent;
import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import android.net.VpnService;
import android.os.Build;
import android.os.ParcelFileDescriptor;
import android.util.Log;

import dev.amirzr.flutter_v2ray_client.v2ray.core.V2rayCoreManager;
import dev.amirzr.flutter_v2ray_client.v2ray.interfaces.V2rayServicesListener;
import dev.amirzr.flutter_v2ray_client.v2ray.utils.AppConfigs;
import dev.amirzr.flutter_v2ray_client.v2ray.utils.V2rayConfig;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileDescriptor;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.concurrent.TimeUnit;

public class V2rayVPNService extends VpnService implements V2rayServicesListener {

    private ParcelFileDescriptor mInterface;
    private Process process;
    private V2rayConfig v2rayConfig;
    private boolean isRunning = true;

    @Override
    public void onCreate() {
        super.onCreate();
        // Initialize the V2Ray core manager
        V2rayCoreManager.getInstance().setUpListener(this);
        
        // Reset state when service is created
        isRunning = false;
        process = null;
        mInterface = null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        AppConfigs.V2RAY_SERVICE_COMMANDS startCommand = (AppConfigs.V2RAY_SERVICE_COMMANDS) intent.getSerializableExtra("COMMAND");
        if (startCommand == null) {
            // Handle null command gracefully
            return START_NOT_STICKY; // Changed from START_STICKY to reduce unnecessary restarts
        }
        
        switch (startCommand) {
            case START_SERVICE:
                v2rayConfig = (V2rayConfig) intent.getSerializableExtra("V2RAY_CONFIG");
                if (v2rayConfig == null) {
                    this.onDestroy();
                    return START_NOT_STICKY;
                }
                if (V2rayCoreManager.getInstance().isV2rayCoreRunning()) {
                    V2rayCoreManager.getInstance().stopCore();
                }
                if (V2rayCoreManager.getInstance().startCore(v2rayConfig)) {
                    Log.i(V2rayProxyOnlyService.class.getSimpleName(), "onStartCommand success => v2ray core started."); // Changed from Log.e to Log.i
                } else {
                    this.onDestroy();
                    return START_NOT_STICKY;
                }
                break;
                
            case STOP_SERVICE:
                V2rayCoreManager.getInstance().stopCore();
                AppConfigs.V2RAY_CONFIG = null;
                stopAllProcess();
                return START_NOT_STICKY; // Service should not restart after explicit stop
                
            case MEASURE_DELAY:
                new Thread(() -> {
                    try {
                        Intent sendB = new Intent("CONNECTED_V2RAY_SERVER_DELAY");
                        sendB.putExtra("DELAY", String.valueOf(V2rayCoreManager.getInstance().getConnectedV2rayServerDelay()));
                        sendBroadcast(sendB);
                    } catch (Exception e) {
                        Log.w("V2RAY_SERVICE", "Error measuring delay: " + e.getMessage());
                    }
                }, "MEASURE_CONNECTED_V2RAY_SERVER_DELAY").start();
                break;
                
            default:
                this.onDestroy();
                return START_NOT_STICKY;
        }
        
        return START_NOT_STICKY; // Changed from START_STICKY to reduce battery drain
    }

    private void stopAllProcess() {
        // Set flag first to prevent any restart attempts
        isRunning = false;
        
        // Stop foreground service properly
        stopForeground(true);
        
        // Destroy tun2socks process if running
        if (process != null) {
            try {
                // Try graceful shutdown first
                process.destroy();
                // Wait a bit for graceful shutdown
                if (!process.waitFor(1, TimeUnit.SECONDS)) {
                    // Force destroy if not shutting down gracefully
                    process.destroyForcibly();
                }
            } catch (Exception e) {
                Log.w("VPN_SERVICE", "Error destroying tun2socks process: " + e.getMessage());
                // Force destroy as last resort
                try {
                    process.destroyForcibly();
                } catch (Exception ignored) {
                }
            } finally {
                process = null;
            }
        }
        
        // Stop V2Ray core
        V2rayCoreManager.getInstance().stopCore();
        
        // Close VPN interface
        if (mInterface != null) {
            try {
                mInterface.close();
            } catch (Exception e) {
                Log.w("VPN_SERVICE", "Error closing VPN interface: " + e.getMessage());
            } finally {
                mInterface = null;
            }
        }
        
        // Stop the service itself
        try {
            stopSelf();
        } catch (Exception e) {
            Log.e("VPN_SERVICE", "Error stopping self: " + e.getMessage());
        }
    }

    private void setup() {
        Intent prepare_intent = prepare(this);
        if (prepare_intent != null) {
            return;
        }
        Builder builder = new Builder();
        builder.setSession(v2rayConfig.REMARK);
        builder.setMtu(1500);
        builder.addAddress("26.26.26.1", 30);

        if (v2rayConfig.BYPASS_SUBNETS == null || v2rayConfig.BYPASS_SUBNETS.isEmpty()) {
            builder.addRoute("0.0.0.0", 0);
        } else {
            for (String subnet : v2rayConfig.BYPASS_SUBNETS) {
                String[] parts = subnet.split("/");
                if (parts.length == 2) {
                    String address = parts[0];
                    int prefixLength = Integer.parseInt(parts[1]);
                    builder.addRoute(address, prefixLength);
                }
            }
        }
        if (v2rayConfig.BLOCKED_APPS != null) {
            for (int i = 0; i < v2rayConfig.BLOCKED_APPS.size(); i++) {
                try {
                    builder.addDisallowedApplication(v2rayConfig.BLOCKED_APPS.get(i));
                } catch (Exception e) {
                    // Log the error but continue
                    Log.w("VPN_SERVICE", "Failed to add blocked app: " + e.getMessage());
                }
            }
        }
        
        // Optimize DNS configuration
        try {
            JSONObject json = new JSONObject(v2rayConfig.V2RAY_FULL_JSON_CONFIG);
            if (json.has("dns")) {
                JSONObject dnsObject = json.getJSONObject("dns");
                if (dnsObject.has("servers")) {
                    JSONArray serversArray = dnsObject.getJSONArray("servers");
                    // Limit to first 2 DNS servers to reduce battery consumption
                    int dnsServersAdded = 0;
                    for (int i = 0; i < serversArray.length() && dnsServersAdded < 2; i++) {
                        try {
                            Object entry = serversArray.get(i);
                            if (entry instanceof String) {
                                builder.addDnsServer((String) entry);
                                dnsServersAdded++;
                            } else if (entry instanceof JSONObject) {
                                JSONObject obj = (JSONObject) entry;
                                if (obj.has("address")) {
                                    builder.addDnsServer(obj.getString("address"));
                                    dnsServersAdded++;
                                }
                            }
                        } catch (Exception ignored) {
                        }
                    }
                }
            }
        } catch (Exception e) {
            // If parsing fails, add sane fallback DNS
            try {
                builder.addDnsServer("1.1.1.1");
            } catch (Exception ignored) {
            }
            try {
                builder.addDnsServer("8.8.8.8");
            } catch (Exception ignored) {
            }
        }
        
        try {
            if (mInterface != null) {
                mInterface.close();
            }
        } catch (Exception e) {
            // Log but continue
            Log.w("VPN_SERVICE", "Failed to close previous interface: " + e.getMessage());
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false);
        }
        
        // Add battery optimization for VPN
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            builder.setUnderlyingNetworks(null); // Use system default network selection
        }

        try {
            mInterface = builder.establish();
            isRunning = true;
            runTun2socks();
        } catch (Exception e) {
            Log.e("VPN_SERVICE", "Failed to establish VPN interface", e);
            stopAllProcess();
        }

    }

    private void runTun2socks() {
        ArrayList<String> cmd = new ArrayList<>(Arrays.asList(new File(getApplicationInfo().nativeLibraryDir, "libtun2socks.so").getAbsolutePath(),
                "--netif-ipaddr", "26.26.26.2",
                "--netif-netmask", "255.255.255.252",
                "--socks-server-addr", "127.0.0.1:" + v2rayConfig.LOCAL_SOCKS5_PORT,
                "--tunmtu", "1500",
                "--sock-path", "sock_path",
                "--enable-udprelay",
                "--loglevel", "none")); // Changed from "error" to "none" to reduce logging overhead
        try {
            ProcessBuilder processBuilder = new ProcessBuilder(cmd);
            processBuilder.redirectErrorStream(true);
            process = processBuilder.directory(getApplicationContext().getFilesDir()).start();
            
            // Use a more efficient approach for monitoring the process
            new Thread(() -> {
                try {
                    int exitCode = process.waitFor();
                    Log.d("VPN_SERVICE", "Tun2socks process exited with code: " + exitCode);
                    if (isRunning && exitCode != 0) {
                        // Only restart if there was an error and service should still be running
                        // Add a small delay to prevent rapid restart loops
                        try {
                            Thread.sleep(1000);
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            return;
                        }
                        runTun2socks();
                    }
                } catch (InterruptedException e) {
                    Log.d("VPN_SERVICE", "Tun2socks thread interrupted");
                    Thread.currentThread().interrupt();
                } catch (Exception e) {
                    Log.w("VPN_SERVICE", "Error in tun2socks thread: " + e.getMessage());
                }
            }, "Tun2socks_Thread").start();
            
            sendFileDescriptor();
        } catch (Exception e) {
            Log.e("VPN_SERVICE", "FAILED to start tun2socks=>", e);
            this.onDestroy();
        }
    }

    private void sendFileDescriptor() {
        String localSocksFile = new File(getApplicationContext().getFilesDir(), "sock_path").getAbsolutePath();
        FileDescriptor tunFd = mInterface.getFileDescriptor();
        new Thread(() -> {
            int tries = 0;
            while (true) {
                try {
                    Thread.sleep(50L * tries);
                    LocalSocket clientLocalSocket = new LocalSocket();
                    clientLocalSocket.connect(new LocalSocketAddress(localSocksFile, LocalSocketAddress.Namespace.FILESYSTEM));
                    if (!clientLocalSocket.isConnected()) {
                        Log.e("SOCK_FILE", "Unable to connect to localSocksFile [" + localSocksFile + "]");
                    } else {
                        Log.e("SOCK_FILE", "connected to sock file [" + localSocksFile + "]");
                    }
                    OutputStream clientOutStream = clientLocalSocket.getOutputStream();
                    clientLocalSocket.setFileDescriptorsForSend(new FileDescriptor[]{tunFd});
                    clientOutStream.write(32);
                    clientLocalSocket.setFileDescriptorsForSend(null);
                    clientLocalSocket.shutdownOutput();
                    clientLocalSocket.close();
                    break;
                } catch (Exception e) {
                    Log.e(V2rayVPNService.class.getSimpleName(), "sendFd failed =>", e);
                    if (tries > 5) {
                        break;
                    }
                    tries += 1;
                }
            }
        }, "sendFd_Thread").start();
    }

    @Override
    public void onDestroy() {
        // Ensure all processes are stopped when service is destroyed
        if (isRunning) {
            stopAllProcess();
        }
        super.onDestroy();
    }

    @Override
    public void onRevoke() {
        stopAllProcess();
    }

    @Override
    public boolean onProtect(int socket) {
        return protect(socket);
    }

    @Override
    public Service getService() {
        return this;
    }

    @Override
    public void startService() {
        setup();
    }

    @Override
    public void stopService() {
        stopAllProcess();
    }
}
