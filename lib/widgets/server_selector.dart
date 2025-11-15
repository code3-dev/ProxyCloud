import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2ray_config.dart';
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';
import '../screens/server_selection_screen.dart';
import '../services/wallpaper_service.dart';
import 'error_snackbar.dart';

class ServerSelector extends StatelessWidget {
  const ServerSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<V2RayProvider, LanguageProvider, WallpaperService>(
      builder: (context, provider, languageProvider, wallpaperService, _) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: _buildServerSelector(context, provider, wallpaperService),
        );
      },
    );
  }

  Widget _buildServerSelector(
    BuildContext context,
    V2RayProvider provider,
    WallpaperService wallpaperService,
  ) {
    final selectedConfig = provider.selectedConfig;
    final configs = provider.configs;
    final isConnecting = provider.isConnecting;
    final isLoadingServers = provider.isLoadingServers;
    final isGlassBackground = wallpaperService.isGlassBackgroundEnabled;

    if (isLoadingServers) {
      return _LoadingServerCard(isGlassBackground: isGlassBackground);
    }

    if (configs.isEmpty) {
      return _EmptyServerCard(isGlassBackground: isGlassBackground);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isGlassBackground
          ? AppTheme.surfaceCard.withOpacity(0.7)
          : AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr(TranslationKeys.homeSelectServer),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: isConnecting
                  ? null
                  : () {
                      // Check if already connected to VPN
                      if (provider.activeConfig != null) {
                        // Show popup to inform user to disconnect first
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              context.tr(
                                TranslationKeys.serverSelectorConnectionActive,
                              ),
                            ),
                            content: Text(
                              context.tr(
                                TranslationKeys.serverSelectorDisconnectFirst,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  context.tr(TranslationKeys.commonOk),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Not connected, show server selector as full page
                        showServerSelectionScreen(
                          context: context,
                          configs: configs,
                          selectedConfig: selectedConfig,
                          isConnecting: isConnecting,
                          onConfigSelected: (config) async {
                            await provider.selectConfig(config);
                          },
                        );
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isGlassBackground
                      ? AppTheme.surfaceContainer.withOpacity(0.7)
                      : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceCard),
                ),
                child: Row(
                  children: [
                    if (selectedConfig != null) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getServerStatusColor(
                            selectedConfig,
                            provider,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedConfig.remark,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Text(
                          context.tr(
                            TranslationKeys.serverSelectorSelectServer,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.connectedGreen,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Color _getServerStatusColor(V2RayConfig config, V2RayProvider provider) {
    // Check if this is the active config (connected)
    final activeConfig = provider.activeConfig;
    if (activeConfig != null && activeConfig.id == config.id) {
      return AppTheme.connectedGreen;
    }
    // Check if this is the selected config (but not connected)
    final selectedConfig = provider.selectedConfig;
    if (selectedConfig != null && selectedConfig.id == config.id) {
      return Colors.orange;
    }
    return AppTheme.textGrey;
  }
}

class _LoadingServerCard extends StatelessWidget {
  final bool isGlassBackground;

  const _LoadingServerCard({required this.isGlassBackground});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isGlassBackground
          ? AppTheme.surfaceCard.withOpacity(0.7)
          : AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.connectedGreen),
              const SizedBox(height: 16),
              Text(context.tr(TranslationKeys.serverSelectorLoadingServers)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final provider = Provider.of<V2RayProvider>(
                    context,
                    listen: false,
                  );
                  try {
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
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${context.tr(TranslationKeys.serverSelectorErrorRefreshing)}: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                },
                child: Text(context.tr(TranslationKeys.commonRefresh)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyServerCard extends StatelessWidget {
  final bool isGlassBackground;

  const _EmptyServerCard({required this.isGlassBackground});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isGlassBackground
          ? AppTheme.surfaceCard.withOpacity(0.7)
          : AppTheme.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppTheme.textGrey),
              const SizedBox(height: 16),
              Text(context.tr(TranslationKeys.serverSelectorNoServers)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final provider = Provider.of<V2RayProvider>(
                    context,
                    listen: false,
                  );
                  try {
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
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${context.tr(TranslationKeys.serverSelectorErrorRefreshing)}: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                },
                child: Text(context.tr(TranslationKeys.commonRefresh)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
