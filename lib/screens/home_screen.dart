import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import '../widgets/connection_button.dart';
import '../widgets/server_selector.dart';
import '../widgets/background_gradient.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import '../services/v2ray_service.dart';
import '../services/wallpaper_service.dart';
import '../utils/auto_select_util.dart';
import 'subscription_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isAutoSelecting = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = '';

    // Listen for connection state changes
    final v2rayProvider = Provider.of<V2RayProvider>(context, listen: false);
    v2rayProvider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    // Ping functionality removed
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // Share V2Ray link to clipboard
  void _shareV2RayLink(BuildContext context) async {
    try {
      final provider = Provider.of<V2RayProvider>(context, listen: false);
      final activeConfig = provider.activeConfig;

      if (activeConfig != null && activeConfig.fullConfig.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: activeConfig.fullConfig));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.connectedGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('home.v2ray_link_copied'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.cardDark,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('home.no_v2ray_config'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.tr('home.error_copying')}: ${e.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  // Check config method to test connectivity to Google
  Future<void> _checkConfig(V2RayProvider provider) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(context.tr('home.checking_config')),
          ],
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final startTime = DateTime.now();
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Network timeout: Check your internet connection',
              );
            },
          );
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Close the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        // Show success message with ping time
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${context.tr('home.config_ok')} (${duration.inMilliseconds}ms)',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.connectedGreen,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${context.tr('home.config_not_working')} (${response.statusCode})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${context.tr('home.config_not_working')}: ${e.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _autoSelectAndConnect(V2RayProvider provider) async {
    if (_isAutoSelecting) return;

    setState(() {
      _isAutoSelecting = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.secondaryDark,
          title: Text(context.tr('server_selection.auto_select')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
              const SizedBox(height: 16),
              Text(context.tr('server_selection.testing_servers')),
              const SizedBox(height: 8),
              StreamBuilder<String>(
                stream: Stream.periodic(const Duration(milliseconds: 500), (count) {
                  final messages = [
                    'Testing servers for fastest connection...',
                    'Analyzing server response times...',
                    'Finding optimal server...',
                    'Almost done...',
                  ];
                  return messages[count % messages.length];
                }),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Testing servers for fastest connection...',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
              ),
            ],
          ),
        ),
      );

      // Get all configs
      final configs = provider.configs;
      if (configs.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('server_selector.no_servers')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Run auto-select algorithm
      final result = await AutoSelectUtil.runAutoSelect(
        configs,
        provider.v2rayService,
        onStatusUpdate: (message) {
          // We could update UI here if needed, but for now we'll just debug print
          debugPrint('Auto-select status: $message');
        },
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
      }

      if (result.selectedConfig != null && result.bestPing != null) {
        // Connect to the best server
        await provider.selectConfig(result.selectedConfig!);
        await provider.connectToServer(
          result.selectedConfig!,
          provider.isProxyMode,
        );
        final success = provider.errorMessage.isEmpty; // Check if connection was successful

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${context.tr('server_selection.lowest_ping', parameters: {
                    'server': result.selectedConfig!.remark,
                    'ping': result.bestPing.toString(),
                  })} - Connected!',
                ),
                backgroundColor: AppTheme.connectedGreen,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('server_selection.connect_failed', parameters: {
                    'server': result.selectedConfig!.remark,
                    'error': 'Connection failed',
                  }),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.errorMessage ??
                    context.tr('server_selection.no_suitable_server'),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('server_selection.error_updating')}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoSelecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: BackgroundGradient(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(context.tr(TranslationKeys.homeTitle)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.auto_mode),
                    onPressed: () async {
                      final provider = Provider.of<V2RayProvider>(
                        context,
                        listen: false,
                      );
                      await _autoSelectAndConnect(provider);
                    },
                    tooltip: context.tr('server_selection.auto_select'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final provider = Provider.of<V2RayProvider>(
                        context,
                        listen: false,
                      );

                      // Show loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('home.updating_subscriptions'),
                          ),
                        ),
                      );

                      // Update all subscriptions instead of just fetching servers
                      await provider.updateAllSubscriptions();
                      provider.fetchNotificationStatus();

                      // Show success message
                      if (provider.errorMessage.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('home.subscriptions_updated'),
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(provider.errorMessage)),
                        );
                        provider.clearError();
                      }
                    },
                    tooltip: context.tr(TranslationKeys.homeRefresh),
                  ),
                  IconButton(
                    icon: const Icon(Icons.subscriptions),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SubscriptionManagementScreen(),
                        ),
                      );
                    },
                    tooltip: context.tr(TranslationKeys.homeSubscriptions),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                    tooltip: context.tr(TranslationKeys.homeAbout),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Main content
                  Expanded(
                    child: Consumer<V2RayProvider>(
                      builder: (context, provider, _) {
                        // Show loading indicator while initializing
                        if (provider.isInitializing) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.tr('common.loading'),
                                  style: const TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Server selector (now includes Proxy Mode Switch)
                                const ServerSelector(),

                                const SizedBox(height: 20),

                                // Connection button
                                const ConnectionButton(),

                                const SizedBox(height: 40),

                                // Connection stats
                                if (provider.activeConfig != null)
                                  _buildConnectionStats(provider),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStats(V2RayProvider provider) {
    // Get the V2RayService instance
    final v2rayService = provider.v2rayService;

    // Use StreamBuilder to update the UI when statistics change
    return StreamBuilder(
      // Create a periodic stream to update the UI every 1 second for traffic and every 5 seconds for IP
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        // Refresh IP info every 5 seconds (when snapshot.data is multiple of 5)
        if (snapshot.hasData && snapshot.data! % 5 == 0) {
          if (v2rayService.activeConfig != null) {
            // Fetch IP info without showing loading indicator
            v2rayService.fetchIpInfo().catchError((error) {
              // Handle error silently
              debugPrint('Error refreshing IP info: $error');
            });
          }
        }

        final ipInfo = v2rayService.ipInfo;

        return Consumer<WallpaperService>(
          builder: (context, wallpaperService, _) {
            final isGlassBackground = wallpaperService.isGlassBackgroundEnabled;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isGlassBackground
                    ? AppTheme.cardDark.withOpacity(0.7)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('home.connection_statistics'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    Icons.timer,
                    context.tr(TranslationKeys.homeConnectionTime),
                    v2rayService.getFormattedConnectedTime(),
                  ),
                  const Divider(height: 24),

                  // Total traffic usage - updated every second
                  _buildTrafficRow(
                    context.tr('home.traffic_usage'),
                    v2rayService.getFormattedUpload(),
                    v2rayService.getFormattedDownload(),
                    v2rayService.getFormattedTotalTraffic(),
                  ),
                  const Divider(height: 24),
                  // Show IP info without error messages
                  _buildIpInfoRow(
                    IpInfo(
                      ip: ipInfo?.ip ?? '...',
                      country: ipInfo?.country ?? '...',
                      city: ipInfo?.city ?? '...',
                      countryCode: ipInfo?.countryCode ?? '',
                      success: true,
                    ),
                    provider,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIpInfoRow(IpInfo ipInfo, V2RayProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.public, size: 18, color: AppTheme.textGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${ipInfo.country} - ${ipInfo.city}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _shareV2RayLink(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.share, size: 18, color: AppTheme.primaryBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Check Config button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _checkConfig(provider),
            icon: const Icon(Icons.check, size: 18),
            label: Text(context.tr('home.check_config')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textGrey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textGrey)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficRow(
    String label,
    String upload,
    String download,
    String total,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.data_usage, size: 18, color: AppTheme.textGrey),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppTheme.textGrey)),
            const Spacer(),
            Text(
              total,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      upload,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      ' ↑',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      download,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Text(
                      ' ↓',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
