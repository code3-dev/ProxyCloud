# Native Ping Service Usage Examples 📡

This document provides comprehensive examples of how to use the new custom native Kotlin ping implementation in your Flutter V2Ray app.

## 🎯 Overview

The native ping service provides advanced network connectivity testing with multiple methods and real-time monitoring capabilities.

### Key Benefits

- **Multi-Method Testing**: ICMP, TCP, and System ping
- **Real-Time Monitoring**: Continuous ping streams
- **Batch Operations**: Test multiple servers simultaneously
- **Performance Optimization**: Cached results and parallel processing

## 🌐 Service Capabilities

### 📡 Ping Methods

- **ICMP Ping**: Real network layer ping using InetAddress.isReachable()
- **TCP Ping**: Connection time measurement using socket connections  
- **System Ping**: Fallback using system's native ping command

### 🧠 Intelligent Features

- **Auto Selection**: Automatically chooses the best available method
- **Real-time Monitoring**: Continuous ping streams for active connections
- **Batch Operations**: Ping multiple servers simultaneously
- **Smart Caching**: Avoid redundant network calls
- **Error Handling**: Graceful fallback mechanisms

## 🚀 Basic Usage

### 🎯 1. Single Host Ping

Test connectivity to a single host with detailed results:

```dart
import 'package:proxycloud/services/ping_service.dart';

// Basic ping
final result = await NativePingService.pingHost(
  host: 'google.com',
  port: 80,
  timeoutMs: 5000,
  useIcmp: true,
  useTcp: true,
);

if (result.success) {
  print('Ping successful: ${result.latency}ms (${result.method})');
} else {
  print('Ping failed: ${result.error}');
}
```

### Response Details

- **success**: Boolean indicating if ping succeeded
- **latency**: Response time in milliseconds
- **method**: Ping method used (icmp/tcp/system)
- **error**: Error message if ping failed
- **timestamp**: When the ping was performed

### 🔌 2. Using V2RayService Integration

Seamlessly integrate ping functionality with V2Ray services:

```dart
import 'package:proxycloud/services/v2ray_service.dart';

final v2rayService = V2RayService();

// Get enhanced ping details for a server config
final pingDetails = await v2rayService.getServerPingDetails(config);
print('Server ${config.remark}: ${pingDetails.latency}ms via ${pingDetails.method}');

// Get traditional ping (integer result for compatibility)
final latency = await v2rayService.getServerDelay(config);
print('Server latency: ${latency}ms');
```

### Integration Benefits

- **Config-aware**: Works with V2Ray server configurations
- **Backward Compatible**: Supports legacy delay methods
- **Enhanced Details**: Provides method and timestamp information
- **Error Resilient**: Handles network issues gracefully

### 📦 3. Batch Server Testing

Test multiple servers efficiently with parallel processing:

```dart
// Test multiple servers at once
final configs = [config1, config2, config3];
final results = await v2rayService.batchPingServers(configs);

for (final config in configs) {
  final latency = results[config.id];
  if (latency != null) {
    print('${config.remark}: ${latency}ms');
  } else {
    print('${config.remark}: Failed');
  }
}

// Find the fastest server
final fastestServer = await v2rayService.getFastestServer(configs);
if (fastestServer != null) {
  print('Fastest server: ${fastestServer.remark}');
}
```

### Batch Advantages

- **Performance**: Parallel execution reduces total time
- **Resource Efficiency**: Optimized network usage
- **Scalability**: Handle large server lists
- **Consistency**: Uniform testing conditions

### 📊 4. Real-time Ping Monitoring

Continuously monitor connection quality with streaming results:

```dart
// Monitor ping for currently connected server
final Stream<PingResult>? pingStream = v2rayService.startConnectedServerPingMonitoring(
  interval: Duration(seconds: 5),
);

if (pingStream != null) {
  pingStream.listen((result) {
    if (result.success) {
      print('Connection quality: ${result.latency}ms (${result.method})');
    } else {
      print('Connection issue: ${result.error}');
    }
  });
}
```

### Monitoring Features

- **Continuous Updates**: Regular interval testing
- **Stream-based**: Reactive programming model
- **Low Overhead**: Minimal impact on connection
- **Real-time Feedback**: Instant quality indicators

### 🌐 5. Connectivity Testing

Verify overall network connectivity and diagnose issues:

```dart
// Test connectivity to common services
final connectivityResults = await v2rayService.testConnectivity();
connectivityResults.forEach((host, result) {
  print('$host: ${result.success ? '${result.latency}ms' : 'Failed'}');
});

// Get current network type
final networkType = await v2rayService.getNetworkType();
print('Network: $networkType');
```

### Connectivity Insights

- **Service Status**: Check popular services
- **Network Type**: WiFi/Cellular/Ethernet detection
- **Diagnostic Tool**: Troubleshoot connection issues
- **Performance Baseline**: Compare against known services

## ⚙️ Advanced Usage

### 🛠️ Custom Ping Configuration

Fine-tune ping behavior for specific requirements:

```dart
// Ping with specific settings
final result = await NativePingService.pingHost(
  host: 'example.com',
  port: 443,
  timeoutMs: 10000,
  useIcmp: true,   // Enable ICMP ping
  useTcp: false,   // Disable TCP ping
  useCache: false, // Don't use cached results
);
```

### Configuration Options

- **timeoutMs**: Adjust timeout for slow connections
- **useIcmp**: Toggle ICMP method
- **useTcp**: Toggle TCP method
- **useCache**: Control result caching
- **port**: Specify custom port
- **host**: Target hostname or IP

### 📋 Multiple Host Batch Ping

Test several hosts with a single call:

```dart
final hosts = [
  (host: 'google.com', port: 80),
  (host: 'cloudflare.com', port: 443),
  (host: '1.1.1.1', port: 53),
];

final results = await NativePingService.pingMultipleHosts(
  hosts: hosts,
  timeoutMs: 5000,
  useIcmp: true,
  useTcp: true,
);

results.forEach((key, result) {
  print('$key: ${result.success ? '${result.latency}ms' : 'Failed'}');
});
```

### Batch Benefits

- **Efficiency**: Single call for multiple tests
- **Parallelism**: Concurrent execution
- **Consistency**: Uniform timeout and settings
- **Organization**: Structured host lists

### 🔄 Continuous Ping Monitoring

Create persistent ping monitoring with full control:

```dart
// Start continuous ping
final pingStream = NativePingService.startContinuousPing(
  host: 'google.com',
  port: 80,
  interval: Duration(seconds: 3),
);

late StreamSubscription subscription;
subscription = pingStream.listen(
  (result) {
    print('Ping: ${result.success ? '${result.latency}ms' : 'Failed'}');
  },
  onError: (error) {
    print('Ping stream error: $error');
  },
  onDone: () {
    print('Ping stream ended');
  },
);

// Stop after 30 seconds
Timer(Duration(seconds: 30), () {
  subscription.cancel();
});
```

### Continuous Features

- **Custom Intervals**: Set monitoring frequency
- **Error Handling**: Robust error management
- **Resource Cleanup**: Proper subscription management
- **Flexible Duration**: Run for specified time periods

## 🎨 UI Integration Examples

### 📱 Simple Ping Display Widget

Create a responsive ping indicator for your UI:

```dart
class PingDisplay extends StatefulWidget {
  final V2RayConfig config;
  
  const PingDisplay({Key? key, required this.config}) : super(key: key);
  
  @override
  _PingDisplayState createState() => _PingDisplayState();
}

class _PingDisplayState extends State<PingDisplay> {
  PingResult? _pingResult;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _performPing();
  }
  
  Future<void> _performPing() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await V2RayService().getServerPingDetails(widget.config);
      setState(() => _pingResult = result);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (_pingResult?.success == true) {
      return Row(
        children: [
          Icon(Icons.signal_cellular_4_bar, 
               color: _getSignalColor(_pingResult!.latency)),
          Text('${_pingResult!.latency}ms'),
          Text('(${_pingResult!.method})', style: TextStyle(fontSize: 12)),
        ],
      );
    }
    
    return Row(
      children: [
        Icon(Icons.signal_cellular_off, color: Colors.red),
        Text('Failed'),
      ],
    );
  }
  
  Color _getSignalColor(int latency) {
    if (latency < 100) return Colors.green;
    if (latency < 300) return Colors.orange;
    return Colors.red;
  }
}
```

### UI Features

- **Visual Feedback**: Color-coded signal strength
- **Loading States**: Progress indicators
- **Error Handling**: Clear failure messages
- **Method Display**: Show which ping method was used

### 📋 Server List with Ping

Integrate ping display into server selection lists:

```dart
class ServerListItem extends StatelessWidget {
  final V2RayConfig config;
  final VoidCallback onTap;
  
  const ServerListItem({
    Key? key, 
    required this.config, 
    required this.onTap
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(config.remark),
      subtitle: Text('${config.address}:${config.port}'),
      trailing: PingDisplay(config: config),
      onTap: onTap,
    );
  }
}
```

### List Integration

- **Seamless Display**: Ping results in list items
- **Touch Handling**: Responsive user interaction
- **Information Density**: Multiple data points
- **Consistent Styling**: Unified UI components

## ⚡ Performance Considerations

### 🗃️ Caching Strategy

Optimize network usage with intelligent caching:

```dart
// This will use cached result if available and not older than 30 seconds
final result1 = await NativePingService.pingHost(host: 'google.com');

// This will force a fresh ping
final result2 = await NativePingService.pingHost(
  host: 'google.com',
  useCache: false,
);

// Clear cache manually
NativePingService.clearCache(host: 'google.com', port: 80);
```

### Caching Benefits

- **Reduced Latency**: Instant results for recent pings
- **Network Efficiency**: Fewer redundant calls
- **Battery Savings**: Less radio usage
- **User Experience**: Faster response times

### 📦 Batch Operations

Maximize performance with parallel processing:

```dart
// ❌ Slow - sequential pings
for (final config in configs) {
  final latency = await v2rayService.getServerDelay(config);
  print('${config.remark}: ${latency}ms');
}

// ✅ Fast - parallel pings
final results = await v2rayService.batchPingServers(configs);
for (final config in configs) {
  final latency = results[config.id];
  print('${config.remark}: ${latency}ms');
}
```

### Performance Gains

- **Time Reduction**: Dramatically faster execution
- **Resource Utilization**: Efficient CPU and network usage
- **Scalability**: Handle larger server lists
- **User Satisfaction**: Quick feedback

### 🧹 Resource Management

Maintain optimal performance with proper cleanup:

```dart
@override
void dispose() {
  // Stop all continuous pings
  NativePingService.stopAllContinuousPings();
  
  // Clean up the service
  NativePingService.cleanup();
  
  super.dispose();
}
```

### Resource Benefits

- **Memory Efficiency**: Prevent memory leaks
- **Battery Conservation**: Stop background operations
- **System Stability**: Release network resources
- **App Performance**: Maintain smooth operation

## ⚠️ Error Handling

Robustly handle network issues and failures:

```dart
try {
  final result = await NativePingService.pingHost(host: 'example.com');
  
  if (result.success) {
    print('Success: ${result.latency}ms via ${result.method}');
  } else {
    print('Failed: ${result.error}');
    
    // Handle specific error types
    if (result.error?.contains('timeout') == true) {
      print('Server is too slow or unreachable');
    } else if (result.error?.contains('refused') == true) {
      print('Server is refusing connections');
    }
  }
} catch (e) {
  print('Ping operation failed: $e');
}
```

### Error Categories

- **Timeouts**: Connection or response delays
- **Network Errors**: Connectivity issues
- **Server Errors**: Host unreachable or refusing connections
- **System Errors**: OS-level failures

## 🔄 Migration from V2Ray Library Ping

Upgrade to enhanced ping functionality with backward compatibility:

```dart
// Old way (V2Ray library)
final delay = await V2ray.getServerDelay(config: config);

// New way (maintains compatibility)
final delay = await v2rayService.getServerDelay(config);

// New way (enhanced details)
final result = await v2rayService.getServerPingDetails(config);
print('Latency: ${result.latency}ms, Method: ${result.method}');
```

### Migration Benefits

- **Zero Breakage**: Existing code continues working
- **Enhanced Features**: Access to new capabilities
- **Better Performance**: Optimized implementation
- **Future-Proof**: Active development and support

## 🧪 Testing

Validate ping functionality with the built-in test screen:

```dart
// Add to your app's navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const PingTestScreen()),
);
```

### Test Screen Features

- **Single Ping Testing**: Test individual hosts
- **Connectivity Testing**: Verify network status
- **Continuous Monitoring**: Real-time ping streams
- **Network Information**: Current connection type
- **Live Results Display**: Immediate feedback

### Testing Benefits

- **Development**: Quick validation during coding
- **Debugging**: Troubleshoot network issues
- **User Support**: Diagnose connection problems
- **Performance Tuning**: Optimize ping settings