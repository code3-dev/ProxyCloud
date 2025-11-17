import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

    // Clean up old wallpapers on startup to prevent app size bloat
    await cleanupAllOldWallpapers();

    notifyListeners();
  }

  /// Pick an image or video from gallery and save it as wallpaper
  Future<bool> pickAndSetWallpaper() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? media = await picker.pickMedia();

      if (media == null) return false;

      // Clean up old wallpapers before setting new one
      await cleanupAllOldWallpapers();

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
    
    // Clean up any remaining old wallpapers
    await cleanupAllOldWallpapers();
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

  /// Clear cached network images to free up space
  Future<void> clearCachedImages() async {
    try {
      // Clear all cached network images using the default cache manager
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cached images: $e');
      }
    }
  }

  /// Comprehensive cleanup of all wallpaper-related files and directories
  Future<void> cleanupAllOldWallpapers() async {
    try {
      // Clear cached network images to free up space
      await clearCachedImages();
      
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
        } else if (entity is Directory) {
          // Delete any subdirectories that might contain cached wallpapers
          await entity.delete(recursive: true);
        }
      }
      
      // Also clean up any loose wallpaper files in the app directory (legacy)
      final List<FileSystemEntity> appDirContents = await appDir.list().toList();
      for (final FileSystemEntity entity in appDirContents) {
        if (entity is File) {
          final String fileName = entity.path.split('/').last;
          if (fileName.startsWith('wallpaper_') && 
              (fileName.endsWith('.jpg') || fileName.endsWith('.png') || 
               fileName.endsWith('.jpeg') || fileName.endsWith('.gif'))) {
            // Only delete if it's not the current wallpaper
            if (_wallpaperPath == null || entity.path != _wallpaperPath) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in comprehensive wallpaper cleanup: $e');
      }
    }
  }

  /// Set wallpaper from URL
  Future<bool> setWallpaperFromUrl(String url) async {
    try {
      // Clean up old wallpapers before setting new one
      await cleanupAllOldWallpapers();
      
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