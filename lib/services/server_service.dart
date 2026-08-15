import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/v2ray_config.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';

class ServerService {
  Future<List<V2RayConfig>> fetchServers({required String customUrl}) async {
    try {
      final url = customUrl;
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Network timeout: Check your internet connection',
              );
            },
          );

      if (response.statusCode == 200) {
        final String responseBody = response.body;
        final List<V2RayConfig> servers = [];

        // Split the response by lines and process each line
        final lines = responseBody.split('\n');

        debugPrint('Fetched ${lines.length} lines from server');

        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;

          debugPrint(
            'Processing line: ${line.substring(0, line.length > 30 ? 30 : line.length)}...',
          );

          try {
            // Try to parse as JSON first
            if (line.startsWith('{') && line.endsWith('}')) {
              final serverJson = jsonDecode(line);
              final config = _parseJsonConfig(serverJson);
              if (config != null) {
                servers.add(config);
                debugPrint('Added JSON config: ${config.remark}');
              }
            }
            // If not JSON, try to parse as a V2Ray URI (vmess://, vless://, etc.)
            else if (line.contains('://')) {
              final config = _parseUriConfig(line);
              if (config != null) {
                servers.add(config);
                debugPrint('Added URI config: ${config.remark}');
              } else {
                debugPrint(
                  'Failed to parse URI: ${line.substring(0, line.length > 30 ? 30 : line.length)}...',
                );
              }
            } else {
              debugPrint(
                'Line is not JSON or URI format: ${line.substring(0, line.length > 30 ? 30 : line.length)}...',
              );
            }
          } catch (e) {
            debugPrint('Error parsing server line: $e');
          }
        }

        debugPrint('Successfully parsed ${servers.length} servers');
        return servers;
      } else {
        throw Exception('Failed to load servers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching servers: $e');
      return [];
    }
  }

  // Parse a JSON configuration
  V2RayConfig? _parseJsonConfig(Map<String, dynamic> json) {
    try {
      return V2RayConfig(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        remark: json['remark'] ?? json['ps'] ?? 'Unknown Server',
        address: json['address'] ?? json['add'] ?? '',
        port:
            int.tryParse(json['port']?.toString() ?? '') ??
            int.tryParse(json['port']?.toString() ?? '') ??
            443,
        configType: json['type'] ?? json['net'] ?? 'vmess',
        fullConfig: jsonEncode(json),
      );
    } catch (e) {
      debugPrint('Error parsing JSON config: $e');
      return null;
    }
  }

  // Parse a URI configuration (vmess://, vless://, etc.)
  V2RayConfig? _parseUriConfig(String uri) {
    try {
      debugPrint(
        'Parsing URI: ${uri.substring(0, uri.length > 30 ? 30 : uri.length)}...',
      );

      // Use V2ray to parse the URL
      if (uri.startsWith('vmess://') ||
          uri.startsWith('vless://') ||
          uri.startsWith('trojan://') ||
          uri.startsWith('ss://')) {
        try {
          V2RayURL parser = V2ray.parseFromURL(uri);
          String configType = '';

          if (uri.startsWith('vmess://')) {
            configType = 'vmess';
          } else if (uri.startsWith('vless://')) {
            configType = 'vless';
          } else if (uri.startsWith('ss://')) {
            configType = 'shadowsocks';
          } else if (uri.startsWith('trojan://')) {
            configType = 'trojan';
          }

          // Use the parsed address and port from the V2RayURL parser
          String address = parser.address;
          int port = parser.port;

          debugPrint(
            'Parsed URI with V2ray: remark=${parser.remark}, address=$address, port=$port',
          );

          return V2RayConfig(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            remark: parser.remark,
            address: address,
            port: port,
            configType: configType,
            fullConfig: uri,
          );
        } catch (e) {
          debugPrint('Error parsing with V2ray: $e');
          return null;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing URI config: $e');
      return null;
    }
  }
}
