import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PingResult {
  final bool success;
  final int latency;
  final String method;
  final String? error;
  final int timestamp;

  const PingResult({
    required this.success,
    required this.latency,
    required this.method,
    this.error,
    required this.timestamp,
  });

  factory PingResult.fromMap(Map<String, dynamic> map) {
    return PingResult(
      success: map['success'] ?? false,
      latency: (map['latency'] ?? -1) as int,
      method: map['method'] ?? 'unknown',
      error: map['error'],
      timestamp: (map['timestamp'] ?? 0) as int,
    );
  }

  factory PingResult.error(String errorMessage) {
    return PingResult(
      success: false,
      latency: -1,
      method: 'error',
      error: errorMessage,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'PingResult(success: $success, latency: ${latency}ms, method: $method)';
    } else {
      return 'PingResult(success: $success, error: $error, method: $method)';
    }
  }
}

class NativePingService {
  static const MethodChannel _channel = MethodChannel('com.cloud.pira/ping');

  // Cache for ping results
  static final Map<String, PingResult> _pingCache = {};
  static final Map<String, bool> _pingInProgress = {};

  // Stream controllers for continuous ping
  static final Map<String, StreamController<PingResult>>
  _continuousPingControllers = {};

  static bool _isInitialized = false;

  /// Initialize the ping service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up method call handler for continuous ping results
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
      debugPrint('NativePingService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NativePingService: $e');
    }
  }

  /// Handle method calls from native side (for continuous ping results)
  static Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onContinuousPingResult') {
      try {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          call.arguments,
        );
        final String pingId = data['pingId'];
        final Map<String, dynamic> resultMap = Map<String, dynamic>.from(
          data['result'],
        );
        final PingResult result = PingResult.fromMap(resultMap);

        // Send result to stream if controller exists
        final controller = _continuousPingControllers[pingId];
        if (controller != null && !controller.isClosed) {
          controller.add(result);
        }
      } catch (e) {
        debugPrint('Error handling continuous ping result: $e');
      }
    }
  }

  /// Start continuous ping monitoring
  static Stream<PingResult> startContinuousPing({
    required String host,
    int port = 80,
    Duration interval = const Duration(seconds: 5),
  }) {
    final String pingId =
        '${host}_${port}_${DateTime.now().millisecondsSinceEpoch}';

    // Create stream controller
    final StreamController<PingResult> controller =
        StreamController<PingResult>.broadcast();
    _continuousPingControllers[pingId] = controller;

    // Start continuous ping on native side
    _startNativeContinuousPing(pingId, host, port, interval);

    // Clean up when stream is cancelled
    controller.onCancel = () {
      stopContinuousPing(pingId);
    };

    return controller.stream;
  }

  /// Start native continuous ping
  static Future<void> _startNativeContinuousPing(
    String pingId,
    String host,
    int port,
    Duration interval,
  ) async {
    try {
      await initialize();

      final Map<String, dynamic> arguments = {
        'pingId': pingId,
        'host': host,
        'port': port,
        'intervalMs': interval.inMilliseconds,
      };

      await _channel.invokeMethod('startContinuousPing', arguments);
    } catch (e) {
      debugPrint('Error starting continuous ping: $e');

      // If native ping fails, add error to stream
      final controller = _continuousPingControllers[pingId];
      if (controller != null && !controller.isClosed) {
        controller.add(PingResult.error('Failed to start continuous ping: $e'));
      }
    }
  }

  /// Stop continuous ping
  static Future<void> stopContinuousPing(String pingId) async {
    try {
      await _channel.invokeMethod('stopContinuousPing', {'pingId': pingId});

      // Close and remove stream controller
      final controller = _continuousPingControllers[pingId];
      if (controller != null) {
        await controller.close();
        _continuousPingControllers.remove(pingId);
      }
    } catch (e) {
      debugPrint('Error stopping continuous ping: $e');
    }
  }

  /// Stop all continuous pings
  static Future<void> stopAllContinuousPings() async {
    final List<String> pingIds = List.from(_continuousPingControllers.keys);

    for (final pingId in pingIds) {
      await stopContinuousPing(pingId);
    }
  }

  /// Get network type
  static Future<String> getNetworkType() async {
    try {
      await initialize();
      final String? networkType = await _channel.invokeMethod('getNetworkType');
      return networkType ?? 'Unknown';
    } catch (e) {
      debugPrint('Error getting network type: $e');
      return 'Unknown';
    }
  }

  /// Clear ping cache
  static void clearCache({String? host, int? port}) {
    if (host != null && port != null) {
      _pingCache.remove('$host:$port');
    } else {
      _pingCache.clear();
    }
  }

  /// Get cached ping result
  static PingResult? getCachedPing(String host, int port) {
    return _pingCache['$host:$port'];
  }

  /// Check if ping is in progress
  static bool isPingInProgress(String host, int port) {
    return _pingInProgress['$host:$port'] == true;
  }

  /// Get ping cache statistics
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now().millisecondsSinceEpoch;
    int validEntries = 0;
    int expiredEntries = 0;

    for (final result in _pingCache.values) {
      final ageMs = now - result.timestamp;
      if (ageMs < 30000) {
        validEntries++;
      } else {
        expiredEntries++;
      }
    }

    return {
      'totalEntries': _pingCache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'inProgressCount': _pingInProgress.values.where((v) => v).length,
    };
  }

  /// Cleanup resources
  static Future<void> cleanup() async {
    try {
      await stopAllContinuousPings();
      await _channel.invokeMethod('cleanup');
      _pingCache.clear();
      _pingInProgress.clear();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }
}
