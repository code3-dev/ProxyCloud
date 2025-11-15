import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/v2ray_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class IpInfoScreen extends StatefulWidget {
  const IpInfoScreen({Key? key}) : super(key: key);

  @override
  State<IpInfoScreen> createState() => _IpInfoScreenState();
}

class _IpInfoScreenState extends State<IpInfoScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _ipData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchIpInfo();
  }

  Future<void> _fetchIpInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch the full details from the API using our new two-step approach
      final fullResponse = await _fetchFullIpDetails();
      setState(() {
        _ipData = fullResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchFullIpDetails() async {
    try {
      // Step 1: Try ipwho.is API first
      final ipWhoResponse = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Network timeout for ipwho.is');
            },
          );

      if (ipWhoResponse.statusCode == 200) {
        final data = jsonDecode(ipWhoResponse.body);

        // Check if the response is successful
        if (data['success'] == true) {
          // Map ipwho.is response to the format expected by the UI
          return {
            'ip': data['ip'] ?? '',
            'country_name': data['country'] ?? '',
            'country_code': data['country_code'] ?? '',
            'region_name': data['region'] ?? '',
            'region_code': data['region_code'] ?? '',
            'city_name': data['city'] ?? '',
            'continent_name': data['continent'] ?? '',
            'continent_code': data['continent_code'] ?? '',
            'postal_code': data['postal'] ?? '',
            'time_zone': data['timezone']?['id'] ?? '',
            'latitude': data['latitude']?.toString() ?? '',
            'longitude': data['longitude']?.toString() ?? '',
            'isp_name': data['connection']?['isp'] ?? '',
            'as_number': data['connection']?['asn'] ?? '',
            'accuracy_radius': '',
          };
        }
      }

      // Step 2: Fall back to ipleak.net if ipwho.is fails or returns unsuccessful
      print(
        'ipwho.is failed or returned unsuccessful, falling back to ipleak.net',
      );
      final ipLeakResponse = await http
          .get(Uri.parse('https://ipleak.net/json/'))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Network timeout for ipleak.net');
            },
          );

      if (ipLeakResponse.statusCode == 200) {
        return jsonDecode(ipLeakResponse.body);
      } else {
        throw Exception(
          'Both IP services failed. ipwho.is status: ${ipWhoResponse.statusCode}, ipleak.net status: ${ipLeakResponse.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch full IP details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        title: Text(context.tr('ip_info.title')),
        backgroundColor: AppTheme.surfaceContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchIpInfo,
            tooltip: context.tr('common.refresh'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('common.error'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchIpInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('common.retry')),
            ),
          ],
        ),
      );
    }

    if (_ipData == null) {
      return Center(
        child: Text(
          context.tr('ip_info.no_info_available'),
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchIpInfo,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            _buildLocationCard(),
            const SizedBox(height: 20),
            _buildNetworkCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.tr('ip_info.summary'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoRow(
                  context.tr('ip_info.ip_address'),
                  _ipData!['ip'] ?? context.tr('common.unknown'),
                  Icons.computer,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context.tr('ip_info.location'),
                  '${_ipData!['country_name'] ?? context.tr('common.unknown')} - ${_ipData!['city_name'] ?? context.tr('common.unknown')}',
                  Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context.tr('ip_info.isp'),
                  _ipData!['isp_name'] ?? context.tr('common.unknown'),
                  Icons.business,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      color: AppTheme.surfaceCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr('ip_info.location'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              context.tr('ip_info.country'),
              '${_ipData!['country_name'] ?? context.tr('common.unknown')} (${_ipData!['country_code'] ?? context.tr('common.unknown')})',
              Icons.flag,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.region'),
              '${_ipData!['region_name'] ?? context.tr('common.unknown')} (${_ipData!['region_code'] ?? context.tr('common.unknown')})',
              Icons.map,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.city'),
              _ipData!['city_name'] ?? context.tr('common.unknown'),
              Icons.location_city,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.continent'),
              '${_ipData!['continent_name'] ?? context.tr('common.unknown')} (${_ipData!['continent_code'] ?? context.tr('common.unknown')})',
              Icons.public,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.postal_code'),
              _ipData!['postal_code']?.toString() ??
                  context.tr('common.unknown'),
              Icons.markunread_mailbox,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.time_zone'),
              _ipData!['time_zone'] ?? context.tr('common.unknown'),
              Icons.access_time,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.coordinates'),
              '${_ipData!['latitude']?.toString() ?? context.tr('common.unknown')}, ${_ipData!['longitude']?.toString() ?? context.tr('common.unknown')}',
              Icons.gps_fixed,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.accuracy_radius'),
              '${_ipData!['accuracy_radius']?.toString() ?? context.tr('common.unknown')} ${context.tr('ip_info.km')}',
              Icons.radar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard() {
    return Card(
      color: AppTheme.surfaceCard,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.network_wifi,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.tr('ip_info.network'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              context.tr('ip_info.isp'),
              _ipData!['isp_name'] ?? context.tr('common.unknown'),
              Icons.business,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.as_number'),
              _ipData!['as_number']?.toString() ?? context.tr('common.unknown'),
              Icons.numbers,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
