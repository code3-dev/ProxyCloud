import 'dart:math';
import 'package:proxycloud/models/v2ray_config.dart';
import 'package:proxycloud/services/v2ray_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Get ping batch size from shared preferences
  static Future<int> getPingBatchSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int batchSize =
          prefs.getInt(_pingBatchSizeKey) ?? 5; // Default to 5
      // Ensure the value is between 1 and 10
      if (batchSize < 1) return 1;
      if (batchSize > 10) return 10;
      return batchSize;
    } catch (e) {
      return 5; // Default value
    }
  }

  /// Run auto-select algorithm to find the best server
  static Future<AutoSelectResult> runAutoSelect(
    List<V2RayConfig> configs,
    V2RayService v2rayService,
    Function(String message)? onStatusUpdate, {
    AutoSelectCancellationToken? cancellationToken,
  }) async {
    if (configs.isEmpty) {
      return AutoSelectResult(
        errorMessage: 'No server configurations available',
      );
    }

    try {
      // Check for cancellation before starting
      if (cancellationToken?.isCancelled == true) {
        return AutoSelectResult(errorMessage: 'Auto-select cancelled');
      }

      // Get the batch size from settings
      final int batchSizeSetting = await getPingBatchSize();
      // Calculate the number of servers to test (2x the batch size)
      final int serversToTest = batchSizeSetting * 2;

      // Track which servers we've already tested
      int testedOffset = 0;
      V2RayConfig? selectedConfig;
      int? bestPing;

      // Continue testing batches until we find a valid server or exhaust all servers
      while (testedOffset < configs.length) {
        // Check for cancellation
        if (cancellationToken?.isCancelled == true) {
          return AutoSelectResult(errorMessage: 'Auto-select cancelled');
        }

        // Determine how many servers to actually test in this iteration
        final int actualServersToTest = min(
          serversToTest,
          configs.length - testedOffset,
        );

        // If no servers left to test, break
        if (actualServersToTest <= 0) break;

        // Take the next batch of servers for testing
        final configsToTest = configs
            .skip(testedOffset)
            .take(actualServersToTest)
            .toList();

        // Show status message for current batch
        if (onStatusUpdate != null) {
          onStatusUpdate('Testing batch of $actualServersToTest servers...');
        }

        // Create a map to store ping results
        final Map<V2RayConfig, int?> pingResults = {};

        // Process configs in smaller batches for better responsiveness
        final int processingBatchSize = min(
          batchSizeSetting,
          3,
        ); // Max 3 for responsiveness
        int testedCount = 0;

        while (testedCount < configsToTest.length) {
          // Check for cancellation
          if (cancellationToken?.isCancelled == true) {
            return AutoSelectResult(errorMessage: 'Auto-select cancelled');
          }

          final currentBatchSize = min(
            processingBatchSize,
            configsToTest.length - testedCount,
          );
          final currentBatch = configsToTest
              .skip(testedCount)
              .take(currentBatchSize)
              .toList();

          try {
            // Ping all configs in the current batch in parallel
            final pingFutures = <Future<int?>>[];
            for (final config in currentBatch) {
              // Check for cancellation before pinging each server
              if (cancellationToken?.isCancelled == true) {
                return AutoSelectResult(errorMessage: 'Auto-select cancelled');
              }
              pingFutures.add(
                _pingServer(
                  config,
                  v2rayService,
                  cancellationToken: cancellationToken,
                ),
              );
            }

            // Wait for all ping tasks to complete
            final results = await Future.wait(pingFutures);

            // Combine results
            for (int i = 0; i < currentBatch.length; i++) {
              pingResults[currentBatch[i]] = results[i];
            }

            // Update tested count
            testedCount += currentBatchSize;

            // Update status with progress
            if (onStatusUpdate != null) {
              onStatusUpdate(
                'Testing batch of $actualServersToTest servers... ($testedCount/$actualServersToTest)',
              );
            }
          } catch (e) {
            // Continue with next batch if there's an error
            break;
          }
        }

        // Find the server with the best ping from the tested servers
        int? currentBestPing;
        V2RayConfig? currentSelectedConfig;

        for (final entry in pingResults.entries) {
          final ping = entry.value;
          if (ping != null && ping > 0 && ping < 8000) {
            // Valid ping range
            if (currentBestPing == null || ping < currentBestPing) {
              currentBestPing = ping;
              currentSelectedConfig = entry.key;
            }
          }
        }

        // If we found a valid server in this batch, check if it's better than previous best
        if (currentSelectedConfig != null && currentBestPing != null) {
          if (bestPing == null || currentBestPing < bestPing) {
            bestPing = currentBestPing;
            selectedConfig = currentSelectedConfig;
          }
        }

        // Move to the next batch
        testedOffset += actualServersToTest;

        // If we found a valid server, we can stop testing
        if (selectedConfig != null && bestPing != null) {
          break;
        }
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

  /// Ping a single server
  static Future<int?> _pingServer(
    V2RayConfig config,
    V2RayService v2rayService, {
    AutoSelectCancellationToken? cancellationToken,
  }) async {
    try {
      final delay = await v2rayService.getServerDelay(
        config,
        cancellationToken: cancellationToken,
      );
      return delay;
    } catch (e) {
      return -1; // Return -1 on error
    }
  }
}
