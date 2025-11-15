import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/update_service.dart';
import '../models/app_update.dart';
import '../utils/app_localizations.dart';
import '../providers/language_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ip_info_screen.dart';
import 'host_checker_screen.dart';
import 'speedtest_screen.dart';
import 'subscription_management_screen.dart';
import 'vpn_settings_screen.dart';
import 'blocked_apps_screen.dart';
import 'per_app_tunnel_screen.dart';
import 'backup_restore_screen.dart';
import 'wallpaper_settings_screen.dart';
import 'wallpaper_store_screen.dart';
import 'battery_settings_screen.dart';
import 'language_settings_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  AppUpdate? _update;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateService = UpdateService();
    final update = await updateService.checkForUpdates();

    setState(() {
      _update = update;
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(TrHelper.errorUrlFormat(context, url))),
        );
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr('common.exit')),
          content: Text(context.tr('common.exit_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('common.exit_cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              child: Text(context.tr('common.exit_yes')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: Scaffold(
            backgroundColor: AppTheme.primaryDark,
            appBar: AppBar(
              title: Text(context.tr(TranslationKeys.toolsTitle)),
              backgroundColor: AppTheme.surfaceContainer,
              elevation: 0,
              centerTitle: true,
            ),
            body: CustomScrollView(
              slivers: [
                if (_update != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildUpdateCard(context, _update!),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                    delegate: SliverChildListDelegate([
                      _buildToolCard(
                        context,
                        title: context.tr(
                          TranslationKeys.toolsLanguageSettings,
                        ),
                        description: context.tr(
                          TranslationKeys.toolsLanguageSettingsDesc,
                        ),
                        icon: Icons.language,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LanguageSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(
                          TranslationKeys.toolsSubscriptionManager,
                        ),
                        description: context.tr(
                          'tools.subscription_manager_desc',
                        ),
                        icon: Icons.subscriptions,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SubscriptionManagementScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsIpInformation),
                        description: context.tr('tools.ip_information_desc'),
                        icon: Icons.public,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const IpInfoScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsHostChecker),
                        description: context.tr('tools.host_checker_desc'),
                        icon: Icons.link,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HostCheckerScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsSpeedTest),
                        description: context.tr('tools.speed_test_desc'),
                        icon: Icons.speed,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SpeedtestScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsBlockedApps),
                        description: context.tr('tools.blocked_apps_desc'),
                        icon: Icons.block,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BlockedAppsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsPerAppTunnel),
                        description: context.tr('tools.per_app_tunnel_desc'),
                        icon: Icons.shield_moon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PerAppTunnelScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsHomeWallpaper),
                        description: context.tr('tools.home_wallpaper_desc'),
                        icon: Icons.wallpaper,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WallpaperSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsWallpaperStore),
                        description: context.tr('tools.wallpaper_store_desc'),
                        icon: Icons.store,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const WallpaperStoreScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsVpnSettings),
                        description: context.tr('tools.vpn_settings_desc'),
                        icon: Icons.settings,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VpnSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(
                          TranslationKeys.toolsBatteryBackground,
                        ),
                        description: context.tr(
                          'tools.battery_background_desc',
                        ),
                        icon: Icons.battery_charging_full,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BatterySettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr(TranslationKeys.toolsBackupRestore),
                        description: context.tr('tools.backup_restore_desc'),
                        icon: Icons.backup,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BackupRestoreScreen(),
                            ),
                          );
                        },
                      ),
                      _buildToolCard(
                        context,
                        title: context.tr('common.exit'),
                        description: context.tr('common.exit_app'),
                        icon: Icons.exit_to_app,
                        onTap: _showExitConfirmation,
                        isExitButton: true,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isExitButton = false,
  }) {
    final iconColor = isExitButton ? Colors.red : AppTheme.primaryBlue;
    final backgroundColor = isExitButton
        ? Colors.red.withValues(alpha: 0.1)
        : AppTheme.primaryBlue.withValues(alpha: 0.1);
    final borderColor = isExitButton
        ? Colors.red.withValues(alpha: 0.3)
        : Colors.transparent;

    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: isExitButton ? 1 : 0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isExitButton ? Colors.red : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isExitButton ? Colors.redAccent : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, AppUpdate update) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.system_update,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Update Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        TrHelper.versionFormat(
                          context,
                          update.version,
                          isNew: true,
                        ),
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(update.messText, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  TrHelper.versionFormat(context, AppUpdate.currentAppVersion),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _launchUrl(update.url.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                  child: Text(context.tr('tools.update_now')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
