import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/v2ray_provider.dart';
import '../theme/app_theme.dart';
import '../services/wallpaper_service.dart';

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<V2RayProvider, WallpaperService>(
      builder: (context, provider, wallpaperService, _) {
        final activeConfig = provider.activeConfig;
        final isConnecting = provider.isConnecting;
        final errorMessage = provider.errorMessage;
        final isGlassBackground = wallpaperService.isGlassBackgroundEnabled;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getStatusGradient(activeConfig != null, isConnecting),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(
                  activeConfig != null,
                  isConnecting,
                ).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
          child: Column(
            children: [
              // Status icon and text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isConnecting)
                    _buildConnectingAnimation()
                  else
                    Icon(
                      activeConfig != null ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 28,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    _getStatusText(activeConfig, isConnecting),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Connected server info
              if (activeConfig != null && !isConnecting)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Connected to ${activeConfig.remark}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Error message
              if (errorMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isGlassBackground
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectingAnimation() {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 8, height: 8, color: Colors.white)
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1500.ms),
          Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 3000.ms, begin: 0.2, end: 1.2),
        ],
      ),
    );
  }

  List<Color> _getStatusGradient(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return [
        AppTheme.connectingBlue,
        AppTheme.connectingBlue.withValues(alpha: 0.8),
      ];
    }
    if (isConnected) {
      return [
        AppTheme.connectedGreen,
        AppTheme.connectedGreen.withValues(alpha: 0.8),
      ];
    }
    return [
      AppTheme.disconnectedRed,
      AppTheme.disconnectedRed.withValues(alpha: 0.8),
    ];
  }

  Color _getStatusColor(bool isConnected, bool isConnecting) {
    if (isConnecting) return AppTheme.connectingBlue;
    return isConnected ? AppTheme.connectedGreen : AppTheme.disconnectedRed;
  }

  String _getStatusText(dynamic activeConfig, bool isConnecting) {
    if (isConnecting) {
      return 'Connecting...';
    }
    return activeConfig != null ? 'Connected' : 'Disconnected';
  }
}
