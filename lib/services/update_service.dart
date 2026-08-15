import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:proxycloud/models/app_update.dart';

import '../utils/app_localizations.dart';

class UpdateService {
  static const String updateUrl =
      'https://raw.githubusercontent.com/code3-dev/ProxyCloud-GUI/refs/heads/main/config/mobile.json';

  // Check for updates
  Future<AppUpdate?> checkForUpdates() async {
    try {
      final response = await http
          .get(Uri.parse(updateUrl))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Network timeout: Check your internet connection',
              );
            },
          );
      if (response.statusCode == 200) {
        final AppUpdate? update = AppUpdate.fromJsonString(response.body);
        if (update != null && update.hasUpdate()) {
          return update;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  // Show update dialog
  void showUpdateDialog(BuildContext context, AppUpdate update) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.tr(TranslationKeys.updateServiceUpdateAvailable)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                TranslationKeys.updateServiceNewVersion,
                parameters: {'version': update.version},
              ),
            ),
            const SizedBox(height: 8),
            Text(update.messText),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr(TranslationKeys.updateServiceLater)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(update.url.trim());
            },
            child: Text(context.tr(TranslationKeys.updateServiceDownload)),
          ),
        ],
      ),
    );
  }

  // Launch URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
      // If context is available, we could show a localized error message
      // For now, keeping the debug print as it's mainly for development
    }
  }
}
