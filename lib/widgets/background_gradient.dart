import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/wallpaper_service.dart';

class BackgroundGradient extends StatelessWidget {
  final Widget child;

  const BackgroundGradient({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<WallpaperService>(
      builder: (context, wallpaperService, _) {
        // Check if wallpaper is enabled and file exists
        final wallpaperFile = wallpaperService.getWallpaperFile();

        if (wallpaperFile != null) {
          return FutureBuilder<bool>(
            future: wallpaperFile.exists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.data != true) {
                // Show gradient while loading or if file doesn't exist
                return _buildGradientBackground();
              }

              return _buildWallpaperBackground(wallpaperFile);
            },
          );
        }

        // Default gradient background
        return _buildGradientBackground();
      },
      child: child,
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.surfaceDark, AppTheme.surfaceContainer],
        ),
      ),
      child: child,
    );
  }

  Widget _buildWallpaperBackground(File wallpaperFile) {
    final String extension = wallpaperFile.path.split('.').last.toLowerCase();

    // For gif files, we'll display the first frame as a static image
    // In a more advanced implementation, we could use a video player
    if (['gif'].contains(extension)) {
      // For now, we'll treat videos like images
      // A more complete solution would use a video player widget
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(wallpaperFile),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(
                alpha: 0.3,
              ), // Add overlay for better text readability
              BlendMode.darken,
            ),
          ),
        ),
        child: child,
      );
    } else {
      // For image files, use the existing implementation
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(wallpaperFile),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(
                alpha: 0.3,
              ), // Add overlay for better text readability
              BlendMode.darken,
            ),
          ),
        ),
        child: child,
      );
    }
  }
}
