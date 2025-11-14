import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptions = prefs.getStringList('v2ray_subscriptions') ?? [];
      final configs = prefs.getStringList('v2ray_configs') ?? [];
      final blockedApps = prefs.getStringList('blocked_apps') ?? [];

      final data = {
        'subscriptions': subscriptions,
        'configs': configs,
        'blocked_apps': blockedApps,
      };

      final jsonString = jsonEncode(data);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'settings-pc-$timestamp.json';

      // Get the Downloads directory
      Directory? downloadsDir;
      try {
        downloadsDir = Directory('/storage/emulated/0/Download');
        // Check if the directory exists, create it if it doesn't
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } catch (e) {
        // Fallback to temporary directory if Downloads is inaccessible
        downloadsDir = await getTemporaryDirectory();
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(jsonString);

      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.backupRestoreBackupSaved,
          parameters: {'fileName': 'Downloads/$fileName'},
        );
      });
    } catch (e) {
      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.backupRestoreErrorExporting,
          parameters: {'error': e.toString()},
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _statusMessage = context.tr(
            TranslationKeys.backupRestoreNoFileSelected,
          );
        });
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'v2ray_subscriptions',
        List<String>.from(data['subscriptions'] ?? []),
      );
      await prefs.setStringList(
        'v2ray_configs',
        List<String>.from(data['configs'] ?? []),
      );
      await prefs.setStringList(
        'blocked_apps',
        List<String>.from(data['blocked_apps'] ?? []),
      );

      setState(() {
        _statusMessage = context.tr(TranslationKeys.backupRestoreDataImported);
      });
    } catch (e) {
      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.backupRestoreErrorImporting,
          parameters: {'error': e.toString()},
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: _buildBackupRestoreScreen(context),
        );
      },
    );
  }

  Widget _buildBackupRestoreScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.backupRestoreTitle)),
        backgroundColor: AppTheme.surfaceContainer,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Card(
                color: AppTheme.cardDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.backup,
                              color: AppTheme.primaryBlue,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    TranslationKeys.backupRestoreBackupData,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr(
                                    TranslationKeys
                                        .backupRestoreBackupDescription,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _exportData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.upload_file, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr(
                                        TranslationKeys.backupRestoreExportNow,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.connectedGreen,
                    AppTheme.connectedGreen.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.connectedGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Card(
                color: AppTheme.cardDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.connectedGreen.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.restore,
                              color: AppTheme.connectedGreen,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    TranslationKeys.backupRestoreRestoreData,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.tr(
                                    TranslationKeys
                                        .backupRestoreRestoreDescription,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _importData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.connectedGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.download, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr(
                                        TranslationKeys.backupRestoreImportNow,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage!.contains('Error')
                      ? AppTheme.disconnectedRed.withValues(alpha: 0.2)
                      : AppTheme.connectedGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusMessage!.contains('Error')
                        ? AppTheme.disconnectedRed
                        : AppTheme.connectedGreen,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage!.contains('Error')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _statusMessage!.contains('Error')
                          ? AppTheme.disconnectedRed
                          : AppTheme.connectedGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusMessage!.contains('Error')
                              ? AppTheme.disconnectedRed
                              : AppTheme.connectedGreen,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
