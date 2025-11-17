import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/wallpaper_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class WallpaperStoreScreen extends StatefulWidget {
  const WallpaperStoreScreen({Key? key}) : super(key: key);

  @override
  State<WallpaperStoreScreen> createState() => _WallpaperStoreScreenState();
}

class _WallpaperStoreScreenState extends State<WallpaperStoreScreen> {
  final String _storeUrl =
      'https://raw.githubusercontent.com/code3-dev/code3-dev/refs/heads/main/pc.json';
  List<String> _wallpapers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWallpapers();
  }

  Future<void> _fetchWallpapers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(_storeUrl))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final List<dynamic> data = json.decode(response.body);
        final List<String> wallpapers = data
            .map((item) => item.toString())
            .toList();

        setState(() {
          _wallpapers = wallpapers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = context.tr(
            TranslationKeys.wallpaperStoreErrorLoading,
            parameters: {'error': 'HTTP ${response.statusCode}'},
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.tr(
          TranslationKeys.wallpaperStoreErrorLoading,
          parameters: {'error': e.toString()},
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadWallpaper(String url) async {
    try {
      // Use Android Download Manager for downloading
      const platform = MethodChannel('com.cloud.pira/download');

      // Generate filename from URL
      final String fileName = url.split('/').last;

      // Invoke the Android Download Manager
      final String downloadId = await platform.invokeMethod('downloadFile', {
        'url': url,
        'fileName': fileName,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.wallpaperStoreDownloadSuccess),
          ),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.wallpaperStoreDownloadError,
              parameters: {'error': e.message ?? 'Unknown error'},
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.wallpaperStoreDownloadError,
              parameters: {'error': e.toString()},
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setAsWallpaper(String url) async {
    try {
      final wallpaperService = Provider.of<WallpaperService>(
        context,
        listen: false,
      );

      // Use the service method which handles cleanup automatically
      final success = await wallpaperService.setWallpaperFromUrl(url);
      if (!success) {
        throw Exception('Failed to set wallpaper from URL');
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr(TranslationKeys.wallpaperStoreSetSuccess)),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );

      // Go back to the previous screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.wallpaperStoreDownloadError,
              parameters: {'error': e.toString()},
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.wallpaperStoreTitle)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(TranslationKeys.wallpaperStoreLoading),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchWallpapers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                    child: Text(
                      context.tr(TranslationKeys.wallpaperStoreRetry),
                    ),
                  ),
                ],
              ),
            )
          : _wallpapers.isEmpty
          ? Center(
              child: Text(
                context.tr(TranslationKeys.wallpaperStoreNoWallpapers),
                style: const TextStyle(color: Colors.white70),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio:
                    0.9, // Increased to give more space for buttons
              ),
              itemCount: _wallpapers.length,
              itemBuilder: (context, index) {
                final wallpaperUrl = _wallpapers[index];
                return _WallpaperItem(
                  imageUrl: wallpaperUrl,
                  onDownload: () => _downloadWallpaper(wallpaperUrl),
                  onSetAsWallpaper: () => _setAsWallpaper(wallpaperUrl),
                  onTap: () => _showFullScreenImage(wallpaperUrl),
                );
              },
            ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }
}

class _WallpaperItem extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onDownload;
  final VoidCallback onSetAsWallpaper;
  final VoidCallback onTap;

  const _WallpaperItem({
    required this.imageUrl,
    required this.onDownload,
    required this.onSetAsWallpaper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image container - takes most of the space
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade800,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Buttons container - fixed height to prevent overflow
          SizedBox(
            height: 60, // Fixed height to prevent overflow
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Set as wallpaper button
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: double.infinity,
                      child: ElevatedButton(
                        onPressed: onSetAsWallpaper,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          context.tr(
                            TranslationKeys.wallpaperStoreSetAsWallpaper,
                          ),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Download button
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: double.infinity,
                      child: OutlinedButton(
                        onPressed: onDownload,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          context.tr(TranslationKeys.wallpaperStoreDownload),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({Key? key, required this.imageUrl})
    : super(key: key);

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late Future<void> _downloadFuture;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () {
              _downloadImage(widget.imageUrl);
            },
          ),
          IconButton(
            icon: const Icon(Icons.wallpaper, color: Colors.white),
            onPressed: () {
              _setAsWallpaper(widget.imageUrl);
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white70, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImage(String url) async {
    try {
      // Use Android Download Manager for downloading
      const platform = MethodChannel('com.cloud.pira/download');

      // Generate filename from URL
      final String fileName = url.split('/').last;

      // Invoke the Android Download Manager
      final String downloadId = await platform.invokeMethod('downloadFile', {
        'url': url,
        'fileName': fileName,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.wallpaperStoreDownloadSuccess),
          ),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.wallpaperStoreDownloadError,
              parameters: {'error': e.message ?? 'Unknown error'},
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.wallpaperStoreDownloadError,
              parameters: {'error': e.toString()},
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setAsWallpaper(String url) async {
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

        // Generate filename from URL
        final String fileName = url.split('/').last;
        final String savePath = '$wallpapersDir/$fileName';

        // Save the image
        final File file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);

        // Set as wallpaper using the wallpaper service
        final wallpaperService = Provider.of<WallpaperService>(
          context,
          listen: false,
        );

        // Set the wallpaper using the existing method
        final success = await wallpaperService.setWallpaperFromUrl(url);
        if (!success) {
          throw Exception('Failed to set wallpaper from URL');
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(TranslationKeys.wallpaperStoreSetSuccess)),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );

        // Go back to the previous screen
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception(
          'Failed to download image: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.wallpaperStoreDownloadError,
              parameters: {'error': e.toString()},
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
