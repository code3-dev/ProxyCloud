import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallpaper_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';
import 'wallpaper_store_screen.dart';

class WallpaperSettingsScreen extends StatefulWidget {
  const WallpaperSettingsScreen({super.key});

  @override
  State<WallpaperSettingsScreen> createState() =>
      _WallpaperSettingsScreenState();
}

class _WallpaperSettingsScreenState extends State<WallpaperSettingsScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize wallpaper service if not already done
      final wallpaperService = Provider.of<WallpaperService>(
        context,
        listen: false,
      );
      wallpaperService.initialize();
    });
  }

  Future<void> _pickWallpaper() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final wallpaperService = Provider.of<WallpaperService>(
        context,
        listen: false,
      );
      final success = await wallpaperService.pickAndSetWallpaper();

      if (success) {
        // Clean up old wallpapers to save space
        await wallpaperService.cleanupOldWallpapers();

        setState(() {
          _statusMessage = context.tr(
            TranslationKeys.wallpaperSettingsSetSuccess,
          );
        });
      } else {
        setState(() {
          _statusMessage = context.tr(TranslationKeys.wallpaperSettingsNoImage);
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.wallpaperSettingsErrorSet,
          parameters: {'error': e.toString()},
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeWallpaper() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final wallpaperService = Provider.of<WallpaperService>(
        context,
        listen: false,
      );
      await wallpaperService.removeWallpaper();

      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.wallpaperSettingsRemoveSuccess,
        );
      });
    } catch (e) {
      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.wallpaperSettingsErrorRemove,
          parameters: {'error': e.toString()},
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showRemoveConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          context.tr(TranslationKeys.wallpaperSettingsRemoveTitle),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          context.tr(TranslationKeys.wallpaperSettingsRemoveContent),
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr(TranslationKeys.commonCancel)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr(TranslationKeys.wallpaperSettingsRemove)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeWallpaper();
    }
  }

  Future<void> _toggleGlassBackground(bool value) async {
    final wallpaperService = Provider.of<WallpaperService>(
      context,
      listen: false,
    );
    await wallpaperService.setGlassBackground(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.wallpaperSettingsTitle)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: Consumer<WallpaperService>(
        builder: (context, wallpaperService, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Glass background toggle
                  _buildGlassBackgroundToggle(wallpaperService),

                  const SizedBox(height: 16),

                  // Current wallpaper preview
                  if (wallpaperService.isWallpaperEnabled &&
                      wallpaperService.wallpaperPath != null)
                    _buildCurrentWallpaperCard(wallpaperService)
                  else
                    _buildNoWallpaperCard(),

                  const SizedBox(height: 16),

                  // Actions
                  _buildActionsCard(wallpaperService),

                  // Status message
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _statusMessage!.contains('Error') ||
                                _statusMessage!.contains('failed')
                            ? Colors.red.withOpacity(0.1)
                            : AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _statusMessage!.contains('Error') ||
                                  _statusMessage!.contains('failed')
                              ? Colors.red
                              : AppTheme.primaryBlue,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _statusMessage!.contains('Error') ||
                                    _statusMessage!.contains('failed')
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color:
                                _statusMessage!.contains('Error') ||
                                    _statusMessage!.contains('failed')
                                ? Colors.red
                                : AppTheme.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                color:
                                    _statusMessage!.contains('Error') ||
                                        _statusMessage!.contains('failed')
                                    ? Colors.red
                                    : AppTheme.primaryBlue,
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
        },
      ),
    );
  }

  Widget _buildGlassBackgroundToggle(WallpaperService wallpaperService) {
    return Card(
      color: AppTheme.surfaceCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr(TranslationKeys.wallpaperSettingsGlassBackground),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Switch(
              value: wallpaperService.isGlassBackgroundEnabled,
              onChanged: (value) {
                setState(() {
                  _toggleGlassBackground(value);
                });
              },
              activeColor: AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWallpaperCard(WallpaperService wallpaperService) {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(TranslationKeys.wallpaperSettingsCurrent),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                if (wallpaperService.wallpaperPath != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenWallpaperViewer(
                        imagePath: wallpaperService.wallpaperPath!,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade700),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FutureBuilder<bool>(
                    future: wallpaperService.wallpaperFileExists(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.data == true &&
                          wallpaperService.wallpaperPath != null) {
                        return Image.file(
                          File(wallpaperService.wallpaperPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr(
                                      TranslationKeys
                                          .wallpaperSettingsFailedLoad,
                                    ),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr(
                                TranslationKeys.wallpaperSettingsImageNotFound,
                              ),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWallpaperCard() {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(TranslationKeys.wallpaperSettingsDefault),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.surfaceDark, AppTheme.surfaceContainer],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gradient, color: Colors.white54, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        TranslationKeys.wallpaperSettingsDefaultBackground,
                      ),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(WallpaperService wallpaperService) {
    return Card(
      color: AppTheme.surfaceCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(TranslationKeys.wallpaperSettingsActions),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Select new wallpaper button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickWallpaper,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.photo_library),
                label: Text(
                  context.tr(TranslationKeys.wallpaperSettingsSelect),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Wallpaper store button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WallpaperStoreScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.store),
                label: Text(
                  context.tr(TranslationKeys.wallpaperSettingsStoreButton),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Remove wallpaper button (only show if wallpaper is set)
            if (wallpaperService.isWallpaperEnabled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _showRemoveConfirmation,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    context.tr(TranslationKeys.wallpaperSettingsRemove),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Info text
            Text(
              context.tr(TranslationKeys.wallpaperSettingsInfo),
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

// Full-screen wallpaper viewer widget
class FullScreenWallpaperViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenWallpaperViewer({Key? key, required this.imagePath})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
