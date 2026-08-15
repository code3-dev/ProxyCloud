// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_v2ray_client/url/url.dart';

/// Vless URL parser and adapter to produce V2Ray configuration pieces.
///
/// It parses a `vless://` share link into structured fields and exposes
/// outbound and stream settings compatible with the V2Ray core.
class VlessURL extends V2RayURL {
  /// Creates a VlessURL by parsing the provided vless share link string.
  ///
  /// Throws [ArgumentError] if the url does not start with `vless://` or
  /// cannot be decoded into a valid URI.
  VlessURL({required super.url}) {
    if (!url.startsWith('vless://')) {
      throw ArgumentError('url is invalid');
    }
    final temp = Uri.tryParse(url);
    if (temp == null) {
      throw ArgumentError('url is invalid');
    }
    uri = temp;
    final sni = super.populateTransportSettings(
      transport: uri.queryParameters['type'] ?? 'tcp',
      headerType: uri.queryParameters['headerType'],
      host: uri.queryParameters['host'],
      path: uri.queryParameters['path'],
      seed: uri.queryParameters['seed'],
      quicSecurity: uri.queryParameters['quicSecurity'],
      key: uri.queryParameters['key'],
      mode: uri.queryParameters['mode'],
      serviceName: uri.queryParameters['serviceName'],
    );
    super.populateTlsSettings(
      streamSecurity: uri.queryParameters['security'] ?? '',
      allowInsecure: allowInsecure,
      sni: uri.queryParameters['sni'] ?? sni,
      fingerprint: uri.queryParameters['fp'] ??
          streamSetting['tlsSettings']?['fingerprint'],
      alpns: uri.queryParameters['alpn'],
      publicKey: uri.queryParameters['pbk'] ?? '',
      shortId: uri.queryParameters['sid'] ?? '',
      spiderX: uri.queryParameters['spx'] ?? '',
    );

    // Handle xhttp specific settings
    _populateXhttpSettings();
  }

  /// The parsed URI object from the vless URL.
  late final Uri uri;

  /// Server address extracted from the URI host.
  @override
  String get address => uri.host;

  /// Server port parsed from the URI. Falls back to [super.port] if absent.
  @override
  int get port => uri.hasPort ? uri.port : super.port;

  /// Human-readable remark decoded from the URI fragment.
  @override
  String get remark => Uri.decodeFull(uri.fragment.replaceAll('+', '%20'));

  /// Populate xhttp specific settings
  void _populateXhttpSettings() {
    final transport = uri.queryParameters['type'] ?? 'tcp';
    if (transport == 'xhttp') {
      final extraParam = uri.queryParameters['extra'];
      Map<String, dynamic>? extraSettings;

      if (extraParam != null) {
        try {
          // Decode and parse the extra parameter which contains JSON
          final decodedExtra = Uri.decodeComponent(extraParam);
          extraSettings = jsonDecode(decodedExtra);
        } catch (e) {
          // If parsing fails, continue without extra settings
          print('Failed to parse xhttp extra settings: $e');
        }
      }

      // Create xhttpSettings object
      final xhttpSettings = <String, dynamic>{
        'host': uri.queryParameters['host'] ?? '',
        'path': uri.queryParameters['path'] ?? '/',
        'mode': uri.queryParameters['mode'] ?? 'auto',
      };

      // Add extra settings if available
      if (extraSettings != null) {
        xhttpSettings['extra'] = extraSettings;
      }

      // Add xhttpSettings to streamSetting
      streamSetting['xhttpSettings'] = xhttpSettings;
    }
  }

  /// Outbound configuration map for the vless protocol used by V2Ray core.
  @override
  Map<String, dynamic> get outbound1 => {
        'tag': 'proxy',
        'protocol': 'vless',
        'settings': {
          'vnext': [
            {
              'address': address,
              'port': port,
              'users': [
                {
                  'id': uri.userInfo,
                  'alterId': null,
                  'security': security,
                  'level': level,
                  'encryption': uri.queryParameters['encryption'] ?? 'none',
                  'flow': uri.queryParameters['flow'] ?? '',
                }
              ]
            }
          ],
          'servers': null,
          'response': null,
          'network': null,
          'address': null,
          'port': null,
          'domainStrategy': null,
          'redirect': null,
          'userLevel': null,
          'inboundTag': null,
          'secretKey': null,
          'peers': null
        },
        'streamSettings': streamSetting,
        'proxySettings': null,
        'sendThrough': null,
        'mux': {
          'enabled': false,
          'concurrency': 8,
        },
      };
}
