import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proxycloud/models/v2ray_config.dart';
import 'package:proxycloud/models/subscription.dart';
import 'package:proxycloud/providers/v2ray_provider.dart';
import 'package:proxycloud/services/v2ray_service.dart';
import 'package:proxycloud/theme/app_theme.dart';
import 'package:proxycloud/utils/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants for shared preferences keys
const String _pingBatchSizeKey = 'ping_batch_size';

class ServerSelectionScreen extends StatefulWidget {
  final List<V2RayConfig> configs;
  final V2RayConfig? selectedConfig;
  final bool isConnecting;
  final Future<void> Function(V2RayConfig) onConfigSelected;

  const ServerSelectionScreen({
    Key? key,
    required this.configs,
    required this.selectedConfig,
    required this.isConnecting,
    required this.onConfigSelected,
  }) : super(key: key);

  @override
  State<ServerSelectionScreen> createState() => _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends State<ServerSelectionScreen> {
  String _selectedFilter = 'All';
  final Map<String, int?> _pings = {};
  final Map<String, bool> _loadingPings = {};
  final V2RayService _v2rayService = V2RayService();
  final StreamController<String> _autoConnectStatusStream =
      StreamController<String>.broadcast();

  /// Get ping batch size from shared preferences
  Future<int> _getPingBatchSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int batchSize = prefs.getInt(_pingBatchSizeKey) ?? 5; // Default to 5
      // Ensure the value is between 1 and 10
      if (batchSize < 1) return 1;
      if (batchSize > 10) return 10;
      return batchSize;
    } catch (e) {
      debugPrint('Error getting ping batch size: $e');
      return 5; // Default value
    }
  }

  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionClipboardEmpty),
            ),
          ),
        );
        return;
      }

      final provider = Provider.of<V2RayProvider>(context, listen: false);
      final config = await provider.importConfigFromText(clipboardData.text!);

      if (config != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionImportSuccess),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionImportFailed),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.serverSelectionImportFailed),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importMultipleFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionClipboardEmpty),
            ),
          ),
        );
        return;
      }

      final provider = Provider.of<V2RayProvider>(context, listen: false);
      final configs = await provider.importConfigsFromText(clipboardData.text!);

      if (configs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${configs.length} ${context.tr(TranslationKeys.serverSelectionImportSuccess)}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionImportFailed),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.serverSelectionImportFailed),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteLocalConfig(V2RayConfig config) async {
    try {
      await Provider.of<V2RayProvider>(
        context,
        listen: false,
      ).removeConfig(config);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.serverSelectionDeleteSuccess),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.serverSelectionDeleteFailed,
              parameters: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  final Map<String, bool> _cancelPingTasks = {};
  Timer? _batchTimeoutTimer;
  bool _sortByPing = false; // New variable for ping sorting
  bool _sortAscending = true; // New variable for sort direction
  bool _isPingingAllServers = false; // Variable for ping all loading state

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'All';
  }

  @override
  void dispose() {
    _autoConnectStatusStream.close();
    _batchTimeoutTimer?.cancel();
    _cancelAllPingTasks();
    super.dispose();
  }

  Map<String, List<V2RayConfig>> _groupConfigsByHost(
    List<V2RayConfig> configs,
  ) {
    final Map<String, List<V2RayConfig>> groupedConfigs = {};
    for (var config in configs) {
      // Use config.id as the key to ensure each config is treated individually
      final key = config.id;
      if (!groupedConfigs.containsKey(key)) {
        groupedConfigs[key] = [];
      }
      groupedConfigs[key]!.add(config);
    }
    return groupedConfigs;
  }

  Future<void> _loadPingForConfig(
    V2RayConfig config,
    List<V2RayConfig> relatedConfigs,
  ) async {
    // Check if task was cancelled before starting
    if (_cancelPingTasks[config.id] == true || !mounted) return;

    try {
      // Safely update loading state
      if (mounted) {
        setState(() {
          for (var relatedConfig in relatedConfigs) {
            _loadingPings[relatedConfig.id] = true;
          }
        });
      }

      // Add timeout to prevent hanging with proper error handling
      int? ping;
      try {
        ping = await _v2rayService
            .getServerDelay(config)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                debugPrint('Ping timeout for server ${config.remark}');
                return -1; // Return -1 on timeout
              },
            );
      } catch (e) {
        debugPrint('Error pinging server ${config.remark}: $e');
        ping = -1; // Return -1 on error
      }

      // Check if widget is still mounted and task wasn't cancelled
      if (mounted && _cancelPingTasks[config.id] != true) {
        setState(() {
          for (var relatedConfig in relatedConfigs) {
            _pings[relatedConfig.id] = ping;
            _loadingPings[relatedConfig.id] = false;
          }
        });
      }
    } catch (e) {
      debugPrint(
        'Unexpected error in _loadPingForConfig for ${config.remark}: $e',
      );
      // Safely handle error state
      if (mounted && _cancelPingTasks[config.id] != true) {
        setState(() {
          for (var relatedConfig in relatedConfigs) {
            _pings[relatedConfig.id] = -1; // Set -1 for failed pings
            _loadingPings[relatedConfig.id] = false;
          }
        });
      }
    }
  }

  Future<int?> _pingServer(V2RayConfig config) async {
    try {
      // Check if task was cancelled or widget unmounted
      if (_cancelPingTasks[config.id] == true || !mounted) {
        return -1;
      }

      return await _v2rayService
          .getServerDelay(config)
          .timeout(
            const Duration(seconds: 8), // Reduced timeout for better UX
            onTimeout: () {
              debugPrint('Ping timeout for server ${config.remark}');
              return -1; // Return -1 on timeout
            },
          );
    } catch (e) {
      debugPrint('Error pinging server ${config.remark}: $e');
      return -1; // Return -1 on error
    }
  }

  // Method to ping all servers in the current filter tab in batches of 5
  Future<void> _pingAllServersInBatches() async {
    if (_isPingingAllServers) return;

    try {
      setState(() {
        _isPingingAllServers = true;
        // Clear existing pings when starting new test
        _pings.clear();
        _loadingPings.clear();
      });

      // Get the batch size from settings
      final int batchSize = await _getPingBatchSize();
      debugPrint('Using ping batch size: $batchSize');

      final provider = Provider.of<V2RayProvider>(context, listen: false);
      final subscriptions = provider.subscriptions;
      
      // Get configs based on current filter
      List<V2RayConfig> configsToPing = [];
      if (_selectedFilter == 'All') {
        configsToPing = provider.configs;
      } else if (_selectedFilter == 'Local') {
        // Get local configs (not in any subscription)
        final allSubscriptionConfigIds = subscriptions
            .expand((sub) => sub.configIds)
            .toSet();
        configsToPing = provider.configs
            .where((config) => !allSubscriptionConfigIds.contains(config.id))
            .toList();
      } else {
        // Get configs for specific subscription
        final subscription = subscriptions.firstWhere(
          (sub) => sub.name == _selectedFilter,
          orElse: () => Subscription(
            id: '',
            name: '',
            url: '',
            lastUpdated: DateTime.now(),
            configIds: [],
          ),
        );
        configsToPing = provider.configs
            .where((config) => subscription.configIds.contains(config.id))
            .toList();
      }

      // Process configs in batches
      for (int i = 0; i < configsToPing.length; i += batchSize) {
        if (!mounted) break;

        final endIndex = (i + batchSize < configsToPing.length)
            ? i + batchSize
            : configsToPing.length;
        final batch = configsToPing.sublist(i, endIndex);

        // Ping all configs in the batch in parallel
        final futures = <Future<void>>[];
        for (final config in batch) {
          if (!mounted) break;
          futures.add(_loadPingForConfig(config, [config]));
        }

        // Wait for all configs in the batch to complete
        await Future.wait(futures);

        // Small delay between batches to avoid overwhelming the system
        if (mounted && i + batchSize < configsToPing.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      debugPrint('Error in ping all operation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing all servers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPingingAllServers = false;
        });
      }
    }
  }

  Future<void> _runAutoConnectAlgorithm(
    List<V2RayConfig> configs,
    BuildContext context,
  ) async {
    // Clear any existing ping tasks
    _cancelPingTasks.clear();
    V2RayConfig? selectedConfig;
    final remainingConfigs = List<V2RayConfig>.from(configs);

    // Check if widget is still mounted before starting
    if (!mounted) return;

    try {
      // Get the batch size from settings
      final int batchSizeSetting = await _getPingBatchSize();
      // Use a smaller batch size for auto-connect (max 3) to be more responsive
      final int batchSize = min(batchSizeSetting, 3);

      while (remainingConfigs.isNotEmpty && selectedConfig == null && mounted) {
        final currentBatchSize = min(batchSize, remainingConfigs.length);
        final currentBatch = remainingConfigs.take(currentBatchSize).toList();
        remainingConfigs.removeRange(0, currentBatchSize);

        // Check mounted state before updating stream
        if (!mounted) break;

        try {
          _autoConnectStatusStream.add(
            context.tr(
              TranslationKeys.serverSelectionTestingBatch,
              parameters: {'count': currentBatch.length.toString()},
            ),
          );
        } catch (e) {
          debugPrint('Error updating status stream: $e');
        }

        final completer = Completer<V2RayConfig?>();

        // Create a timeout with proper cleanup
        _batchTimeoutTimer?.cancel();
        _batchTimeoutTimer = Timer(const Duration(seconds: 8), () {
          if (!completer.isCompleted && mounted) {
            debugPrint('Batch timeout reached, moving to next batch');
            try {
              _autoConnectStatusStream.add(
                context.tr(TranslationKeys.serverSelectionBatchTimeout),
              );
            } catch (e) {
              debugPrint('Error updating status stream on timeout: $e');
            }
            completer.complete(null);
          }
        });

        try {
          // Start ping tasks for current batch
          final pingFutures = currentBatch.map(
            (config) => _processPingTask(config, completer),
          );
          await Future.wait(pingFutures, eagerError: false);

          // Wait for completer to complete or timeout
          selectedConfig = await completer.future.timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint('Completer timeout reached');
              return null;
            },
          );

          _batchTimeoutTimer?.cancel();
        } catch (e) {
          if (e.toString().contains('timeout')) {
            debugPrint('Timeout in batch processing: $e');
          } else {
            debugPrint('Error in batch processing: $e');
          }
          _batchTimeoutTimer?.cancel();
          continue;
        }
      }

      // Clean up timer
      _batchTimeoutTimer?.cancel();
      _batchTimeoutTimer = null;

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      if (selectedConfig != null) {
        try {
          if (mounted) {
            _autoConnectStatusStream.add(
              context.tr(
                TranslationKeys.serverSelectionFastestConnection,
                parameters: {
                  'server': selectedConfig.remark,
                  'ping': _pings[selectedConfig.id].toString(),
                },
              ),
            );
          }

          // Attempt to connect to the selected server
          await widget.onConfigSelected(selectedConfig);

          // Safe navigation with proper checks
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close auto-connect dialog
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close server selection screen
            }
          }
        } catch (e) {
          debugPrint('Error connecting to selected server: $e');
          if (mounted) {
            try {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(); // Close auto-connect dialog
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(
                      TranslationKeys.serverSelectionConnectFailed,
                      parameters: {
                        'server': selectedConfig.remark,
                        'error': e.toString(),
                      },
                    ),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            } catch (navError) {
              debugPrint('Error with navigation/snackbar: $navError');
            }
          }
        }
      } else {
        // No suitable server found
        if (mounted) {
          try {
            _autoConnectStatusStream.add(
              context.tr(TranslationKeys.serverSelectionNoSuitableServer),
            );

            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close auto-connect dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(TranslationKeys.serverSelectionNoSuitableServer),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error showing no server found message: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in auto-connect algorithm: $e');
      if (mounted) {
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close auto-connect dialog
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${context.tr(TranslationKeys.serverSelectionErrorUpdating)}: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } catch (navError) {
          debugPrint('Error with navigation/snackbar in auto-connect: $navError');
        }
      }
    }
  }

  Future<void> _processPingTask(
    V2RayConfig config,
    Completer<V2RayConfig?> completer,
  ) async {
    // Early return if widget unmounted or completer already completed
    if (!mounted ||
        completer.isCompleted ||
        _cancelPingTasks[config.id] == true) {
      return;
    }

    try {
      // Safely update status stream
      if (mounted && !completer.isCompleted) {
        try {
          _autoConnectStatusStream.add(
            context.tr(
              TranslationKeys.serverSelectionTestingServer,
              parameters: {'server': config.remark},
            ),
          );
        } catch (e) {
          debugPrint('Error updating status stream: $e');
        }
      }

      // Ping the server with timeout
      int? ping;
      try {
        ping = await _pingServer(config).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('Ping task timeout for server ${config.remark}');
            return -1; // Return -1 on timeout
          },
        );
      } catch (e) {
        if (e.toString().contains('timeout')) {
          debugPrint('Timeout in ping task for ${config.remark}: $e');
        } else {
          debugPrint('Error pinging server in task ${config.remark}: $e');
        }
        ping = -1; // Return -1 on error
      }

      // Check if we should continue (widget still mounted and completer not completed)
      if (!mounted ||
          completer.isCompleted ||
          _cancelPingTasks[config.id] == true) {
        return;
      }

      // Safely update state
      try {
        if (mounted) {
          setState(() {
            _pings[config.id] = ping;
            _loadingPings[config.id] = false;
          });
        }
      } catch (e) {
        debugPrint('Error updating ping state for ${config.remark}: $e');
      }

      // Check if we found a valid server
      if (ping != null && ping > 0 && ping < 8000) {
        // Valid ping range
        if (mounted && !completer.isCompleted) {
          try {
            _autoConnectStatusStream.add(
              context.tr(
                TranslationKeys.serverSelectionLowestPing,
                parameters: {'server': config.remark, 'ping': ping.toString()},
              ),
            );
            _cancelAllPingTasks();
            completer.complete(config);
          } catch (e) {
            debugPrint(
              'Error completing successful ping for ${config.remark}: $e',
            );
          }
        }
      } else {
        // Server failed or had invalid ping
        if (mounted && !completer.isCompleted) {
          try {
            _autoConnectStatusStream.add(
              context.tr(
                TranslationKeys.serverSelectionTimeout,
                parameters: {'server': config.remark},
              ),
            );
          } catch (e) {
            debugPrint('Error updating failed status for ${config.remark}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Unexpected error in _processPingTask for ${config.remark}: $e',
      );

      // Safely update loading state on error
      try {
        if (mounted && !completer.isCompleted) {
          setState(() {
            _pings[config.id] = -1; // Set -1 for failed pings
            _loadingPings[config.id] = false;
          });
        }
      } catch (stateError) {
        debugPrint(
          'Error updating error state for ${config.remark}: $stateError',
        );
      }
    }
  }

  Future<void> _pingAllConfigs() async {
    setState(() {
      _isPingingAllServers = true;
    });

    try {
      // Clear existing pings when starting new test
      setState(() {
        _pings.clear();
      });

      // Get the batch size from settings
      final int batchSize = await _getPingBatchSize();
      debugPrint('Using ping batch size: $batchSize');

      // Filter configs to only include non-connected configs
      final configsToPing = widget.configs
          .where((config) => config.id != widget.selectedConfig?.id)
          .toList();

      // Process configs in batches
      for (int i = 0; i < configsToPing.length; i += batchSize) {
        if (!mounted) break;

        final endIndex = (i + batchSize < configsToPing.length)
            ? i + batchSize
            : configsToPing.length;
        final batch = configsToPing.sublist(i, endIndex);

        // Ping all configs in the batch in parallel
        final futures = <Future<void>>[];
        for (final config in batch) {
          if (!mounted) break;
          futures.add(_loadPingForConfig(config, [config]));
        }

        // Wait for all configs in the batch to complete
        await Future.wait(futures);

        // Small delay between batches to avoid overwhelming the system
        if (mounted && i + batchSize < configsToPing.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      debugPrint('Error in ping all operation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing all servers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPingingAllServers = false;
        });
      }
    }
  }

  void _cancelAllPingTasks() {
    _cancelPingTasks.updateAll((key, value) => true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<V2RayProvider>(context, listen: true);
    final subscriptions = provider.subscriptions;
    final configs = provider.configs;

    final filterOptions = [
      'All',
      'Local',
      ...subscriptions.map((sub) => sub.name),
    ];

    // Add sort and ping buttons in the app bar actions
    final List<Widget> appBarActions = [
      // Ping All button
      IconButton(
        icon: _isPingingAllServers
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryGreen,
                  ),
                ),
              )
            : const Icon(Icons.flash_on),
        tooltip: 'Ping All Servers in Current Tab (5 at a time)',
        onPressed: _isPingingAllServers
            ? null
            : () async {
                await _pingAllServersInBatches();
              },
      ),
      // Sort button
      IconButton(
        icon: Icon(
          _sortByPing ? Icons.sort : Icons.sort_outlined,
          color: _sortByPing ? AppTheme.primaryGreen : null,
        ),
        tooltip: context.tr(TranslationKeys.serverSelectionSortByPing),
        onPressed: () {
          setState(() {
            if (_sortByPing) {
              _sortAscending = !_sortAscending;
            } else {
              _sortByPing = true;
              _sortAscending = true;
            }
          });
        },
      ),
    ];

    List<V2RayConfig> filteredConfigs = [];
    if (_selectedFilter == 'All') {
      filteredConfigs = List.from(configs);
    } else if (_selectedFilter == 'Local') {
      // Filter configs that don't belong to any subscription
      final allSubscriptionConfigIds = subscriptions
          .expand((sub) => sub.configIds)
          .toSet();
      filteredConfigs = configs
          .where((config) => !allSubscriptionConfigIds.contains(config.id))
          .toList();
    } else {
      final subscription = subscriptions.firstWhere(
        (sub) => sub.name == _selectedFilter,
        orElse: () => Subscription(
          id: '',
          name: '',
          url: '',
          lastUpdated: DateTime.now(),
          configIds: [],
        ),
      );
      filteredConfigs = configs
          .where((config) => subscription.configIds.contains(config.id))
          .toList();
    }

    // Sort configs by ping if enabled
    if (_sortByPing) {
      filteredConfigs.sort((a, b) {
        final pingA = _pings[a.id];
        final pingB = _pings[b.id];

        // Check if ping values are valid (not null, -1, or 0)
        final isValidPingA = pingA != null && pingA > 0;
        final isValidPingB = pingB != null && pingB > 0;

        // Handle invalid pings - put them at the bottom
        if (!isValidPingA && !isValidPingB) {
          // Both invalid, but prioritize -1 (timeout) over null (no test)
          if (pingA == -1 && pingB == -1) return 0;
          if (pingA == -1 && pingB == null) return -1;
          if (pingA == null && pingB == -1) return 1;
          return 0;
        }
        if (!isValidPingA) return 1; // Invalid pings go to bottom
        if (!isValidPingB) return -1; // Valid pings stay on top

        // Sort by ping value (only valid pings reach here)
        return _sortAscending ? pingA.compareTo(pingB) : pingB.compareTo(pingA);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      floatingActionButton: _selectedFilter == 'Local'
          ? FloatingActionButton(
              onPressed: _importMultipleFromClipboard,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.paste),
            )
          : null,
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.serverSelectionTitle)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          ...appBarActions,
          if (_selectedFilter != 'Local')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          TranslationKeys.serverSelectionUpdatingServers,
                        ),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );

                  if (_selectedFilter == 'All') {
                    await provider.updateAllSubscriptions();
                  } else if (_selectedFilter != 'Default') {
                    final subscription = subscriptions.firstWhere(
                      (sub) => sub.name == _selectedFilter,
                      orElse: () => Subscription(
                        id: '',
                        name: '',
                        url: '',
                        lastUpdated: DateTime.now(),
                        configIds: [],
                      ),
                    );
                    if (subscription.id.isNotEmpty) {
                      await provider.updateSubscription(subscription);
                    }
                  }

                  setState(() {});
                  // Ping all servers in current tab after refresh
                  await _pingAllServersInBatches();

                  if (provider.errorMessage.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    provider.clearError();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr(
                            TranslationKeys.serverSelectionServersUpdated,
                          ),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          TranslationKeys.serverSelectionErrorUpdating,
                          parameters: {'error': e.toString()},
                        ),
                      ),
                    ),
                  );
                }
              },
              tooltip: context.tr(TranslationKeys.serverSelectionUpdateServers),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final filter = filterOptions[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 16 : 8,
                    right: index == filterOptions.length - 1 ? 16 : 0,
                  ),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                    backgroundColor: AppTheme.cardDark,
                    selectedColor: AppTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filteredConfigs.isEmpty
                ? Center(
                    child: Text(
                      context.tr(
                        TranslationKeys.serverSelectionNoServers,
                        parameters: {'filter': _selectedFilter},
                      ),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredConfigs.length + 1,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppTheme.cardDark,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: widget.isConnecting
                                ? null
                                : () async {
                                    final provider = Provider.of<V2RayProvider>(
                                      context,
                                      listen: false,
                                    );
                                    if (provider.activeConfig != null) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              AppTheme.secondaryDark,
                                          title: Text(
                                            context.tr(
                                              TranslationKeys
                                                  .serverSelectionConnectionActive,
                                            ),
                                          ),
                                          content: Text(
                                            context.tr(
                                              TranslationKeys
                                                  .serverSelectionDisconnectFirst,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text(
                                                context.tr('common.ok'),
                                                style: const TextStyle(
                                                  color: AppTheme.primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              AppTheme.secondaryDark,
                                          title: Text(
                                            context.tr(
                                              TranslationKeys
                                                  .serverSelectionAutoSelect,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppTheme.primaryGreen),
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                context.tr(
                                                  TranslationKeys
                                                      .serverSelectionTestingServers,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              StreamBuilder<String>(
                                                stream: _autoConnectStatusStream
                                                    .stream,
                                                builder: (context, snapshot) {
                                                  return Text(
                                                    snapshot.data ??
                                                        context.tr(
                                                          TranslationKeys
                                                              .serverSelectionTestingServers,
                                                        ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                      await _runAutoConnectAlgorithm(
                                        filteredConfigs,
                                        context,
                                      );
                                    }
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr(
                                            TranslationKeys
                                                .serverSelectionAutoSelect,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          context.tr(
                                            TranslationKeys
                                                .serverSelectionAutoSelectDescription,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.bolt,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final config = filteredConfigs[index - 1];
                      final isSelected =
                          provider.selectedConfig?.id == config.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.cardDark,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: widget.isConnecting
                              ? null
                              : () async {
                                  final provider = Provider.of<V2RayProvider>(
                                    context,
                                    listen: false,
                                  );
                                  if (provider.activeConfig != null) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: AppTheme.secondaryDark,
                                        title: Text(
                                          context.tr(
                                            TranslationKeys
                                                .serverSelectionConnectionActive,
                                          ),
                                        ),
                                        content: Text(
                                          context.tr(
                                            TranslationKeys
                                                .serverSelectionDisconnectFirst,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              context.tr('common.ok'),
                                              style: const TextStyle(
                                                color: AppTheme.primaryGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    try {
                                      await widget.onConfigSelected(config);
                                      if (mounted &&
                                          Navigator.of(context).canPop()) {
                                        Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      debugPrint(
                                        'Error selecting server ${config.remark}: $e',
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context.tr(
                                                TranslationKeys
                                                    .serverSelectionConnectFailed,
                                                parameters: {
                                                  'server': config.remark,
                                                  'error': e.toString(),
                                                },
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : AppTheme.textGrey,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              config.remark,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (_selectedFilter == 'Local')
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _deleteLocalConfig(config),
                                            ),
                                          _loadingPings[config.id] == true
                                              ? const SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          AppTheme.primaryGreen,
                                                        ),
                                                  ),
                                                )
                                              : _pings[config.id] != null &&
                                                    _pings[config.id]! > 0
                                              ? Text(
                                                  '${_pings[config.id]}ms',
                                                  style: TextStyle(
                                                    color:
                                                        AppTheme.primaryGreen,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : _pings[config.id] == -1
                                              ? const Text(
                                                  '-1',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${config.address}:${config.port}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getConfigTypeColor(
                                                config.configType,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              config.configType
                                                  .toString()
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: _getConfigTypeColor(
                                                  config.configType,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getSubscriptionName(config),
                                              style: const TextStyle(
                                                color: Colors.blueGrey,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getConfigTypeColor(String configType) {
    switch (configType.toLowerCase()) {
      case 'vmess':
        return Colors.blue;
      case 'vless':
        return Colors.purple;
      case 'shadowsocks':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getSubscriptionName(V2RayConfig config) {
    final subscriptions = Provider.of<V2RayProvider>(
      context,
      listen: false,
    ).subscriptions;
    return subscriptions
        .firstWhere(
          (sub) => sub.configIds.contains(config.id),
          orElse: () => Subscription(
            id: '',
            name: 'Default Subscription',
            url: '',
            lastUpdated: DateTime.now(),
            configIds: [],
          ),
        )
        .name;
  }
}

void showServerSelectionScreen({
  required BuildContext context,
  required List<V2RayConfig> configs,
  required V2RayConfig? selectedConfig,
  required bool isConnecting,
  required Future<void> Function(V2RayConfig) onConfigSelected,
}) {
  final provider = Provider.of<V2RayProvider>(context, listen: false);
  if (provider.activeConfig != null) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: Text(
          context.tr(TranslationKeys.serverSelectionConnectionActive),
        ),
        content: Text(
          context.tr(TranslationKeys.serverSelectionDisconnectFirst),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('common.ok'),
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServerSelectionScreen(
        configs: configs,
        selectedConfig: selectedConfig,
        isConnecting: isConnecting,
        onConfigSelected: onConfigSelected,
      ),
    ),
  );
}