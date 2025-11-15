import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class WallpaperService extends ChangeNotifier {
  static const String _wallpaperPathKey = 'home_wallpaper_path';
  static const String _wallpaperEnabledKey = 'home_wallpaper_enabled';
  static const String _glassBackgroundKey = 'glass_background_enabled';

  String? _wallpaperPath;
  bool _isWallpaperEnabled = false;
  bool _isGlassBackgroundEnabled = false;

  String? get wallpaperPath => _wallpaperPath;
  bool get isWallpaperEnabled => _isWallpaperEnabled;
  bool get isGlassBackgroundEnabled => _isGlassBackgroundEnabled;

  /// Initialize the service by loading saved wallpaper settings
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _wallpaperPath = prefs.getString(_wallpaperPathKey);
    _isWallpaperEnabled = prefs.getBool(_wallpaperEnabledKey) ?? false;
    _isGlassBackgroundEnabled = prefs.getBool(_glassBackgroundKey) ?? false;

    // Check if the saved wallpaper file still exists
    if (_wallpaperPath != null && _isWallpaperEnabled) {
      final file = File(_wallpaperPath!);
      if (!await file.exists()) {
        // File no longer exists, disable wallpaper
        await removeWallpaper();
      }
    }

    notifyListeners();
  }

  /// Pick an image or video from gallery and save it as wallpaper
  Future<bool> pickAndSetWallpaper() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? media = await picker.pickMedia();

      if (media == null) return false;

      // Get app documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String wallpapersDir = '${appDir.path}/wallpapers';

      // Create wallpapers directory if it doesn't exist
      final Directory wallpaperDirectory = Directory(wallpapersDir);
      if (!await wallpaperDirectory.exists()) {
        await wallpaperDirectory.create(recursive: true);
      }

      // Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = media.path.split('.').last;
      final String fileName = 'wallpaper_$timestamp.$extension';
      final String savePath = '$wallpapersDir/$fileName';

      // Copy the selected media to app directory
      final File sourceFile = File(media.path);
      final File destinationFile = await sourceFile.copy(savePath);

      // Save wallpaper path and enable it
      await _saveWallpaperSettings(destinationFile.path, true);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting wallpaper: $e');
      }
      return false;
    }
  }

  /// Remove current wallpaper and revert to default background
  Future<void> removeWallpaper() async {
    if (_wallpaperPath != null) {
      try {
        final file = File(_wallpaperPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting wallpaper file: $e');
        }
      }
    }

    await _saveWallpaperSettings(null, false);
  }

  /// Save wallpaper settings to SharedPreferences
  Future<void> _saveWallpaperSettings(String? path, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    _wallpaperPath = path;
    _isWallpaperEnabled = enabled;

    if (path != null) {
      await prefs.setString(_wallpaperPathKey, path);
    } else {
      await prefs.remove(_wallpaperPathKey);
    }

    await prefs.setBool(_wallpaperEnabledKey, enabled);
    notifyListeners();
  }

  /// Set glass background setting
  Future<void> setGlassBackground(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    _isGlassBackgroundEnabled = enabled;
    await prefs.setBool(_glassBackgroundKey, enabled);
    notifyListeners();
  }

  /// Get wallpaper file if it exists and is enabled
  File? getWallpaperFile() {
    if (_isWallpaperEnabled && _wallpaperPath != null) {
      final file = File(_wallpaperPath!);
      return file;
    }
    return null;
  }

  /// Check if wallpaper file exists
  Future<bool> wallpaperFileExists() async {
    if (_wallpaperPath == null) return false;
    final file = File(_wallpaperPath!);
    return await file.exists();
  }

  /// Clean up old wallpaper files (keep only the current one)
  Future<void> cleanupOldWallpapers() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String wallpapersDir = '${appDir.path}/wallpapers';
      final Directory wallpaperDirectory = Directory(wallpapersDir);

      if (!await wallpaperDirectory.exists()) return;

      final List<FileSystemEntity> files = await wallpaperDirectory
          .list()
          .toList();

      for (final FileSystemEntity entity in files) {
        if (entity is File) {
          // Don't delete the current wallpaper
          if (_wallpaperPath != null && entity.path != _wallpaperPath) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old wallpapers: $e');
      }
    }
  }

  /// Set wallpaper from URL
  Future<bool> setWallpaperFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Get app documents directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String wallpapersDir = '${appDir.path}/wallpapers';

        // Create wallpapers directory if it doesn't exist
        final Directory wallpaperDirectory = Directory(wallpapersDir);
        if (!await wallpaperDirectory.exists()) {
          await wallpaperDirectory.create(recursive: true);
        }

        // Generate unique filename
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final String extension = url.split('.').last.split('?').first;
        final String fileName = 'wallpaper_$timestamp.$extension';
        final String savePath = '$wallpapersDir/$fileName';

        // Save the image
        final File file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);

        // Save wallpaper path and enable it
        await _saveWallpaperSettings(file.path, true);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting wallpaper from URL: $e');
      }
      return false;
    }
  }
}
