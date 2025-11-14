import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/telegram_proxy.dart';
import '../providers/telegram_proxy_provider.dart';
import '../widgets/background_gradient.dart';
import '../widgets/error_snackbar.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';
import '../services/wallpaper_service.dart';

class TelegramProxyScreen extends StatefulWidget {
  const TelegramProxyScreen({Key? key}) : super(key: key);

  @override
  State<TelegramProxyScreen> createState() => _TelegramProxyScreenState();
}

class _TelegramProxyScreenState extends State<TelegramProxyScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch proxies when screen is first loaded
    Future.microtask(() {
      Provider.of<TelegramProxyProvider>(context, listen: false).fetchProxies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(context.tr(TranslationKeys.telegramProxyTitle)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                Provider.of<TelegramProxyProvider>(
                  context,
                  listen: false,
                ).fetchProxies();
              },
              tooltip: context.tr(TranslationKeys.telegramProxyRefresh),
            ),
          ],
        ),
        body: Consumer2<TelegramProxyProvider, WallpaperService>(
          builder: (context, provider, wallpaperService, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(TranslationKeys.telegramProxyErrorLoading),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        provider.fetchProxies();
                      },
                      child: Text(
                        context.tr(TranslationKeys.telegramProxyTryAgain),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.proxies.isEmpty) {
              return Center(
                child: Text(context.tr(TranslationKeys.telegramProxyNoProxies)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.proxies.length,
              itemBuilder: (context, index) {
                final proxy = provider.proxies[index];
                return _buildProxyCard(
                  context,
                  proxy,
                  wallpaperService.isGlassBackgroundEnabled,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProxyCard(
    BuildContext context,
    TelegramProxy proxy,
    bool isGlassBackground,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isGlassBackground
          ? AppTheme.cardDark.withOpacity(0.7)
          : AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with host and port
            Row(
              children: [
                Expanded(
                  child: Text(
                    proxy.host,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryBlue, width: 1),
                  ),
                  child: Text(
                    context.tr(
                      TranslationKeys.telegramProxyPort,
                      parameters: {'port': proxy.port.toString()},
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Country and provider info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public, size: 18, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        context.tr(
                          TranslationKeys.telegramProxyCountry,
                          parameters: {'country': proxy.country},
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.tr(
                              TranslationKeys.telegramProxyProvider,
                              parameters: {'provider': proxy.provider},
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Uptime indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    context.tr(
                      TranslationKeys.telegramProxyUptime,
                      parameters: {'uptime': proxy.uptime.toString()},
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Uptime progress bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: proxy.uptime / 100,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          proxy.uptime > 80
                              ? Colors.green
                              : proxy.uptime > 60
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 20),
                        label: Text(
                          context.tr(TranslationKeys.telegramProxyCopyDetails),
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  'Server: ${proxy.host}\nPort: ${proxy.port}\nSecret: ${proxy.secret}',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr(
                                  TranslationKeys.telegramProxyDetailsCopied,
                                ),
                              ),
                              backgroundColor: AppTheme.primaryBlue,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.link, size: 20),
                        label: Text(
                          context.tr(TranslationKeys.telegramProxyCopyUrl),
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: proxy.telegramHttpsUrl),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr(
                                  TranslationKeys.telegramProxyUrlCopied,
                                ),
                              ),
                              backgroundColor: AppTheme.primaryBlue,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.telegram, size: 20),
                  label: Text(
                    context.tr(TranslationKeys.telegramProxyConnect),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final url = proxy.telegramUrl;
                    try {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ErrorSnackbar.show(
                          context,
                          context.tr(TranslationKeys.telegramProxyNotInstalled),
                        );
                      }
                    } catch (e) {
                      ErrorSnackbar.show(
                        context,
                        context.tr(
                          TranslationKeys.telegramProxyLaunchError,
                          parameters: {'error': e.toString()},
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
