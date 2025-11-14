import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/v2ray_service.dart';
import '../utils/app_localizations.dart';
import '../providers/language_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:typed_data';

class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({super.key});

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class AppInfo {
  final String packageName;
  final String name;
  final bool isSystemApp;
  final String icon; // Base64 encoded icon

  AppInfo({
    required this.packageName,
    required this.name,
    required this.isSystemApp,
    required this.icon,
  });
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  final V2RayService _v2rayService = V2RayService();
  List<AppInfo> _availableApps = [];
  List<String> _selectedApps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApps = List.from(_availableApps);
      } else {
        _filteredApps = _availableApps
            .where(
              (app) =>
                  app.name.toLowerCase().contains(query.toLowerCase()) ||
                  app.packageName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _loadData() async {
    // Load saved blocked apps first (fast operation)
    final prefs = await SharedPreferences.getInstance();
    final savedBlockedApps = prefs.getStringList('blocked_apps') ?? [];

    setState(() {
      _selectedApps = savedBlockedApps;
      _isLoading = true; // Show loading for app list
    });

    try {
      // Get available apps from device (potentially slow operation)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final apps = await _v2rayService.getInstalledApps();

        // Convert the raw data to AppInfo objects
        List<AppInfo> appInfoList = [];

        // For Android, we expect a list of maps with name and packageName
        final appsList = apps as List<dynamic>? ?? [];
        for (var app in appsList) {
          final appMap = app as Map<String, dynamic>? ?? {};
          appInfoList.add(
            AppInfo(
              name:
                  appMap['name'] ??
                  context.tr(TranslationKeys.blockedAppsUnknownApp),
              packageName: appMap['packageName'] ?? '',
              isSystemApp: appMap['isSystemApp'] ?? false,
              icon: appMap['icon'] ?? '', // Add icon data
            ),
          );
        }

        setState(() {
          _availableApps = appInfoList;
          _filteredApps = List.from(appInfoList);
          _isLoading = false;
        });
      } else {
        // Non-Android platforms
        setState(() {
          _availableApps = [];
          _filteredApps = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.blockedAppsFailedToLoad,
                parameters: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveBlockedApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // If _selectedApps is empty, save null by removing the key
      if (_selectedApps.isEmpty) {
        await prefs.remove('blocked_apps');
      } else {
        await prefs.setStringList('blocked_apps', _selectedApps);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedApps.isEmpty
                  ? context.tr(TranslationKeys.blockedAppsNoAppsSelected)
                  : context.tr(TranslationKeys.blockedAppsSavedSuccessfully),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.blockedAppsFailedToSave,
                parameters: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
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
          child: _buildBlockedAppsScreen(context),
        );
      },
    );
  }

  Widget _buildBlockedAppsScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.blockedAppsTitle)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          // Clear selection button
          if (_selectedApps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: context.tr(
                TranslationKeys.blockedAppsClearAllSelections,
              ),
              onPressed: () {
                setState(() {
                  _selectedApps = [];
                });
              },
            ),
          TextButton(
            onPressed: _saveBlockedApps,
            child: Text(
              context.tr(TranslationKeys.commonSave),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(
                      TranslationKeys.commonLoadingApps,
                    ), // Use translated text
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterApps,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: context.tr(
                        TranslationKeys.blockedAppsSearchApps,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: AppTheme.primaryDark.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // App list
                Expanded(
                  child: _filteredApps.isEmpty
                      ? Center(
                          child: Text(
                            _availableApps.isEmpty
                                ? context.tr(
                                    TranslationKeys.blockedAppsNoAppsFound,
                                  )
                                : context.tr(
                                    TranslationKeys.blockedAppsNoMatchingApps,
                                  ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredApps.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            final isSelected = _selectedApps.contains(
                              app.packageName,
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              color: AppTheme.primaryDark.withValues(
                                alpha: 0.8,
                              ),
                              child: ListTile(
                                leading: _buildAppIcon(app),
                                title: Text(
                                  app.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  app.packageName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  activeColor: AppTheme.connectedGreen,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedApps.add(app.packageName);
                                      } else {
                                        _selectedApps.remove(app.packageName);
                                      }
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    if (_selectedApps.contains(
                                      app.packageName,
                                    )) {
                                      _selectedApps.remove(app.packageName);
                                    } else {
                                      _selectedApps.add(app.packageName);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppIcon(AppInfo app) {
    if (app.icon.isNotEmpty) {
      try {
        // Decode base64 string to image
        Uint8List bytes = base64Decode(app.icon);
        return CircleAvatar(radius: 20, backgroundImage: MemoryImage(bytes));
      } catch (e) {
        // If there's an error decoding the icon, fall back to text avatar
        return CircleAvatar(
          backgroundColor: app.isSystemApp
              ? Colors.blueGrey
              : AppTheme.connectedGreen,
          child: Text(
            app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }
    } else {
      // Fall back to text avatar if no icon data
      return CircleAvatar(
        backgroundColor: app.isSystemApp
            ? Colors.blueGrey
            : AppTheme.connectedGreen,
        child: Text(
          app.name.isNotEmpty ? app.name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      );
    }
  }
}
