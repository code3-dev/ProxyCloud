import 'dart:math';
import 'package:proxycloud/models/v2ray_config.dart';
import 'package:proxycloud/services/v2ray_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint

class AutoSelectResult {
  final V2RayConfig? selectedConfig;
  final int? bestPing;
  final String? errorMessage;

  AutoSelectResult({this.selectedConfig, this.bestPing, this.errorMessage});
}

// Cancellation token class for auto-select operations
class AutoSelectCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class AutoSelectUtil {
  static const String _pingBatchSizeKey = 'ping_batch_size';

  /// Get ping batch size from shared preferences (increased default for faster testing)
  static Future<int> getPingBatchSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int batchSize =
          prefs.getInt(_pingBatchSizeKey) ?? 10; // Increased default to 10
      // Ensure the value is between 1 and 20 for faster testing
      if (batchSize < 1) return 1;
      if (batchSize > 20) return 20; // Increased max to 20
      return batchSize;
    } catch (e) {
      return 10; // Increased default value
    }
  }

  /// Run auto-select algorithm to find the best server with optimized settings
  static Future<AutoSelectResult> runAutoSelect(
    List<V2RayConfig> configs,
    V2RayService v2rayService, {
    void Function(String)? onStatusUpdate,
    AutoSelectCancellationToken? cancellationToken,
  }) async {
    try {
      // Get batch size (increased for faster testing)
      final int batchSize = await getPingBatchSize();
      debugPrint('Using auto-select batch size: $batchSize');

      // Notify about starting
      onStatusUpdate?.call('Testing ${configs.length} servers in batches of $batchSize...');

      // Variables to track the best server found so far
      V2RayConfig? selectedConfig;
      int? bestPing = 10000; // Start with a high value

      // Process servers in larger batches for faster testing
      int testedOffset = 0;
      while (testedOffset < configs.length) {
        // Check for cancellation
        if (cancellationToken?.isCancelled == true) {
          return AutoSelectResult(errorMessage: 'Auto-select cancelled');
        }

        // Determine how many servers to test in this batch
        final int serversToTest = min(batchSize, configs.length - testedOffset);
        final int actualServersToTest = max(1, serversToTest); // Ensure at least 1
        
        // Get the configs for this batch
        final List<V2RayConfig> batchConfigs = configs.sublist(
          testedOffset,
          min(testedOffset + actualServersToTest, configs.length),
        );

        // Notify about current batch
        onStatusUpdate?.call('Testing batch ${testedOffset ~/ batchSize + 1}: ${batchConfigs.length} servers...');

        // Ping all configs in the batch in parallel with optimized settings
        final futures = <Future<MapEntry<V2RayConfig, int?>>>[];
        for (final config in batchConfigs) {
          // Check for cancellation before starting each ping
          if (cancellationToken?.isCancelled == true) {
            return AutoSelectResult(errorMessage: 'Auto-select cancelled');
          }
          
          futures.add(
            v2rayService
                .getServerDelay(config, cancellationToken: cancellationToken)
                .then((delay) => MapEntry(config, delay)),
          );
        }

        // Wait for all configs in the batch to complete with shorter timeout
        final List<MapEntry<V2RayConfig, int?>> results = await Future.wait(
          futures,
        ).timeout(
          const Duration(seconds: 6), // Reduced timeout for faster response
          onTimeout: () {
            // Handle timeout case
            debugPrint('Auto-select batch timeout');
            return []; // Return empty list on timeout
          },
        );

        // Process results and find the best server in this batch
        for (final result in results) {
          // Check for cancellation
          if (cancellationToken?.isCancelled == true) {
            return AutoSelectResult(errorMessage: 'Auto-select cancelled');
          }

          final config = result.key;
          final delay = result.value;

          // Update status with current result
          if (delay != null && delay >= 0) {
            onStatusUpdate?.call('✓ ${config.remark}: ${delay}ms');
            
            // Check if this is the best server so far
            if (delay < (bestPing ?? 10000)) {
              selectedConfig = config;
              bestPing = delay;
              
              // If we found a very fast server (< 100ms), we can stop early for maximum speed
              if (delay < 100) {
                onStatusUpdate?.call('Found very fast server (${delay}ms), stopping early...');
                break;
              }
            }
          } else {
            onStatusUpdate?.call('✗ ${config.remark}: Failed');
          }
        }

        // Early exit if we found a good server
        if (selectedConfig != null && (bestPing ?? 10000) < 200) {
          onStatusUpdate?.call('Found good server (${bestPing}ms), stopping batch testing...');
          break;
        }

        // Move to the next batch
        testedOffset += actualServersToTest;
      }

      if (selectedConfig != null && bestPing != null) {
        return AutoSelectResult(
          selectedConfig: selectedConfig,
          bestPing: bestPing,
        );
      } else {
        return AutoSelectResult(errorMessage: 'No suitable server found');
      }
    } catch (e) {
      return AutoSelectResult(errorMessage: 'Error during auto-select: $e');
    }
  }
}
