import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/v2ray_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/app_localizations.dart';
import 'dart:convert';
import 'dart:typed_data';

class PerAppTunnelScreen extends StatefulWidget {
  const PerAppTunnelScreen({super.key});

  @override
  State<PerAppTunnelScreen> createState() => _PerAppTunnelScreenState();
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

class _PerAppTunnelScreenState extends State<PerAppTunnelScreen> {
  final V2RayService _v2rayService = V2RayService();
  List<AppInfo> _availableApps = [];
  List<String> _selectedApps = []; // Selected apps will be tunneled
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
      _isLoading = true; // Show loading for app list
    });

    try {
      // Get available apps from device (potentially slow operation)
      if (defaultTargetPlatform == TargetPlatform.android) {
        final apps = await _v2rayService.getInstalledApps();

        // Convert the raw data to AppInfo objects
        List<AppInfo> appInfoList = [];

        final appsList = apps as List<dynamic>? ?? [];
        for (var app in appsList) {
          final appMap = app as Map<String, dynamic>? ?? {};
          appInfoList.add(
            AppInfo(
              name: appMap['name'] ?? context.tr('common.unknown'),
              packageName: appMap['packageName'] ?? '',
              isSystemApp: appMap['isSystemApp'] ?? false,
              icon: appMap['icon'] ?? '', // Add icon data
            ),
          );
        }

        // For "per-app tunnel": selected apps = available - blocked
        final allPackages = appInfoList.map((a) => a.packageName).toSet();
        final blockedSet = savedBlockedApps.toSet();
        final selectedSet = allPackages.difference(blockedSet);

        setState(() {
          _availableApps = appInfoList;
          _filteredApps = List.from(appInfoList);
          _selectedApps = selectedSet.toList();
          _isLoading = false;
        });
      } else {
        // Non-Android platforms
        setState(() {
          _availableApps = [];
          _filteredApps = [];
          // No apps available; default to empty selection
          _selectedApps = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('common.error')}: $e')),
        );
      }
    }
  }

  Future<void> _savePerAppTunnel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Inverse logic: blocked = allPackages - selected
      final allPackages = _availableApps.map((a) => a.packageName).toSet();
      final selectedSet = _selectedApps.toSet();
      final blockedSet = allPackages.difference(selectedSet);
      final blockedList = blockedSet.where((p) => p.isNotEmpty).toList();

      // If nothing should be blocked, remove key
      if (blockedList.isEmpty) {
        await prefs.remove('blocked_apps');
      } else {
        await prefs.setStringList('blocked_apps', blockedList);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedApps.isEmpty
                  ? context.tr('per_app_tunnel.all_blocked')
                  : context.tr('per_app_tunnel.updated_successfully'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('per_app_tunnel.failed_save')}: $e'),
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
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr('per_app_tunnel.title')),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          // Select all button
          if (_availableApps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: context.tr('per_app_tunnel.select_all_tooltip'),
              onPressed: () {
                setState(() {
                  _selectedApps = _availableApps
                      .map((e) => e.packageName)
                      .toList();
                });
              },
            ),
          // Clear selection button
          if (_selectedApps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: context.tr('per_app_tunnel.clear_selection_tooltip'),
              onPressed: () {
                setState(() {
                  _selectedApps = [];
                });
              },
            ),
          TextButton(
            onPressed: _savePerAppTunnel,
            child: Text(
              context.tr('common.save'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      hintText: context.tr('per_app_tunnel.search_hint'),
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: AppTheme.primaryDark.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.tr('per_app_tunnel.info_banner'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                // App list
                Expanded(
                  child: _filteredApps.isEmpty
                      ? Center(
                          child: Text(
                            context.tr('per_app_tunnel.no_apps_found'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredApps.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFF323232),
                          ),
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            final isSelected = _selectedApps.contains(
                              app.packageName,
                            );
                            return ListTile(
                              leading: _buildAppIcon(app),
                              title: Text(
                                app.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                app.packageName,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                activeColor: AppTheme.primaryGreen,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      if (!_selectedApps.contains(
                                        app.packageName,
                                      )) {
                                        _selectedApps.add(app.packageName);
                                      }
                                    } else {
                                      _selectedApps.remove(app.packageName);
                                    }
                                  });
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedApps.remove(app.packageName);
                                  } else {
                                    _selectedApps.add(app.packageName);
                                  }
                                });
                              },
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
