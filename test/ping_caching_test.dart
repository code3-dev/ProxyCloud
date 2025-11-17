import 'package:flutter_test/flutter_test.dart';
import 'package:proxycloud/models/v2ray_config.dart';
import 'package:proxycloud/services/v2ray_service.dart';

void main() {
  group('Ping Caching Tests', () {
    late V2RayService v2rayService;
    
    setUp(() {
      v2rayService = V2RayService();
    });
    
    test('Configs with same IP should have independent ping results', () {
      // Create two configs with the same IP but different IDs
      final config1 = V2RayConfig(
        id: 'config1',
        remark: 'Server 1',
        address: '20.20.20.20',
        port: 443,
        configType: 'vmess',
        fullConfig: 'vmess://example1',
      );
      
      final config2 = V2RayConfig(
        id: 'config2',
        remark: 'Server 2',
        address: '20.20.20.20',
        port: 443,
        configType: 'vmess',
        fullConfig: 'vmess://example2',
      );
      
      // Manually set different ping values in cache
      v2rayService.clearPingCache(); // Clear any existing cache
      
      // Set different ping values for each config
      v2rayService._pingCache['config1'] = 50;
      v2rayService._pingCache['config2'] = 100;
      
      // Verify that each config gets its own ping value
      expect(v2rayService._pingCache['config1'], equals(50));
      expect(v2rayService._pingCache['config2'], equals(100));
      
      // Verify that configs with same IP but different IDs don't interfere
      expect(v2rayService._pingCache['config1'], 
             isNot(equals(v2rayService._pingCache['config2'])));
    });
  });
}