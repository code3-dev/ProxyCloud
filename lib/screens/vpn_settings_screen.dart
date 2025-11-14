import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/error_snackbar.dart';
import '../utils/app_localizations.dart';
import '../providers/v2ray_provider.dart';

// Constants for shared preferences keys
const String _pingBatchSizeKey = 'ping_batch_size';

class VpnSettingsScreen extends StatefulWidget {
  const VpnSettingsScreen({Key? key}) : super(key: key);

  @override
  State<VpnSettingsScreen> createState() => _VpnSettingsScreenState();
}

class _VpnSettingsScreenState extends State<VpnSettingsScreen> {
  final TextEditingController bypassSubnetController = TextEditingController();
  final TextEditingController dnsServerController = TextEditingController();
  final TextEditingController pingBatchSizeController = TextEditingController();
  bool isEnabled = false;
  bool isLoading = true;
  bool isDnsEnabled = false; // For custom DNS settings
  bool isProxyModeEnabled = false; // For proxy mode settings

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    bypassSubnetController.dispose();
    dnsServerController.dispose();
    pingBatchSizeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String savedSubnets = prefs.getString('bypass_subnets') ?? '';
      final bool savedEnabled =
          prefs.getBool('bypass_subnets_enabled') ?? false;
      final bool savedDnsEnabled = prefs.getBool('custom_dns_enabled') ?? false;
      final String savedDnsServers =
          prefs.getString('custom_dns_servers') ??
          '1.1.1.1\n1.0.0.1\n8.8.8.8\n8.8.4.4';
      final int savedPingBatchSize =
          prefs.getInt(_pingBatchSizeKey) ?? 5; // Default to 5
      final bool savedProxyModeEnabled =
          prefs.getBool('proxy_mode_enabled') ?? false;

      setState(() {
        bypassSubnetController.text = savedSubnets;
        dnsServerController.text = savedDnsServers;
        pingBatchSizeController.text = savedPingBatchSize.toString();
        isEnabled = savedEnabled;
        isDnsEnabled = savedDnsEnabled;
        isProxyModeEnabled = savedProxyModeEnabled;
        isLoading = false;
      });

      // Update the provider's proxy mode state
      if (mounted) {
        final v2rayProvider = Provider.of<V2RayProvider>(
          context,
          listen: false,
        );
        v2rayProvider.toggleProxyMode(savedProxyModeEnabled);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ErrorSnackbar.show(
          context,
          context
              .tr(TranslationKeys.vpnSettingsErrorLoading)
              .replaceAll('{error}', e.toString()),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'bypass_subnets',
        bypassSubnetController.text.trim(),
      );
      await prefs.setBool('bypass_subnets_enabled', isEnabled);
      await prefs.setBool('proxy_mode_enabled', isProxyModeEnabled);
      await prefs.setBool('custom_dns_enabled', isDnsEnabled);
      await prefs.setString(
        'custom_dns_servers',
        dnsServerController.text.trim(),
      );

      // Save ping batch size (ensure it's between 1 and 10)
      int pingBatchSize = 5; // Default value
      try {
        pingBatchSize = int.parse(pingBatchSizeController.text.trim());
        if (pingBatchSize < 1) pingBatchSize = 1;
        if (pingBatchSize > 10) pingBatchSize = 10;
      } catch (e) {
        // If parsing fails, use default value
        pingBatchSize = 5;
      }
      await prefs.setInt(_pingBatchSizeKey, pingBatchSize);

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(TranslationKeys.vpnSettingsSavedSuccess)),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ErrorSnackbar.show(
          context,
          context
              .tr(TranslationKeys.vpnSettingsErrorSaving)
              .replaceAll('{error}', e.toString()),
        );
      }
    }
  }

  void _resetToDefaultSubnets() {
    final List<String> defaultSubnets = [
      "0.0.0.0/5",
      "8.0.0.0/7",
      "11.0.0.0/8",
      "12.0.0.0/6",
      "16.0.0.0/4",
      "32.0.0.0/3",
      "64.0.0.0/2",
      "128.0.0.0/3",
      "160.0.0.0/5",
      "168.0.0.0/6",
      "172.0.0.0/12",
      "172.32.0.0/11",
      "172.64.0.0/10",
      "172.128.0.0/9",
      "173.0.0.0/8",
      "174.0.0.0/7",
      "176.0.0.0/4",
      "192.0.0.0/9",
      "192.128.0.0/11",
      "192.160.0.0/13",
      "192.169.0.0/16",
      "192.170.0.0/15",
      "192.172.0.0/14",
      "192.176.0.0/12",
      "192.192.0.0/10",
      "193.0.0.0/8",
      "194.0.0.0/7",
      "196.0.0.0/6",
      "200.0.0.0/5",
      "208.0.0.0/4",
      "240.0.0.0/4",
    ];

    setState(() {
      bypassSubnetController.text = defaultSubnets.join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<V2RayProvider>(
      builder: (context, v2rayProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.primaryDark,
          appBar: AppBar(
            title: Text(context.tr(TranslationKeys.vpnSettingsTitle)),
            backgroundColor: AppTheme.primaryBlue,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSettings,
                tooltip: context.tr(TranslationKeys.vpnSettingsSave),
              ),
            ],
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: AppTheme.secondaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.tr(
                                      TranslationKeys.vpnSettingsBypassSubnets,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Switch(
                                    value: isEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        isEnabled = value;
                                      });
                                    },
                                    // Updated deprecated activeThumbColor to activeColor
                                    activeColor: AppTheme.primaryGreen,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsBypassSubnetsDesc,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: bypassSubnetController,
                                decoration: InputDecoration(
                                  hintText: context.tr(
                                    TranslationKeys
                                        .vpnSettingsBypassSubnetsHint,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.cardDark,
                                ),
                                style: const TextStyle(fontSize: 14),
                                maxLines: 10,
                                minLines: 5,
                                enabled: isEnabled,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: isEnabled
                                        ? _resetToDefaultSubnets
                                        : null,
                                    child: Text(
                                      context.tr(
                                        TranslationKeys.vpnSettingsResetDefault,
                                      ),
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: isEnabled
                                        ? () {
                                            setState(() {
                                              bypassSubnetController.clear();
                                            });
                                          }
                                        : null,
                                    child: Text(
                                      context.tr(
                                        TranslationKeys.vpnSettingsClearAll,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Proxy Mode Card
                      Card(
                        color: AppTheme.secondaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.tr(
                                      TranslationKeys.vpnSettingsProxyMode,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Switch(
                                    value: isProxyModeEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        isProxyModeEnabled = value;
                                      });
                                      // Update the provider's proxy mode state
                                      v2rayProvider.toggleProxyMode(value);
                                    },
                                    activeColor: AppTheme.primaryGreen,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsProxyModeDesc,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (isProxyModeEnabled) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardDark,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr(
                                          TranslationKeys
                                              .vpnSettingsProxyInformation,
                                        ),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr(
                                          TranslationKeys.vpnSettingsHttpProxy,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr(
                                          TranslationKeys.vpnSettingsProxyNote,
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orangeAccent,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Connection Type card removed - using VPN mode only
                      Card(
                        color: AppTheme.secondaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.tr(
                                      TranslationKeys.vpnSettingsCustomDns,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Switch(
                                    value: isDnsEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        isDnsEnabled = value;
                                      });
                                    },
                                    // Updated deprecated activeThumbColor to activeColor
                                    activeColor: AppTheme.primaryGreen,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsCustomDnsDesc,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: dnsServerController,
                                decoration: InputDecoration(
                                  hintText: context.tr(
                                    TranslationKeys.vpnSettingsCustomDnsHint,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.cardDark,
                                ),
                                style: const TextStyle(fontSize: 14),
                                maxLines: 3,
                                minLines: 1,
                                enabled: isDnsEnabled,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: isDnsEnabled
                                        ? () {
                                            setState(() {
                                              dnsServerController.text =
                                                  '1.1.1.1\n1.0.0.1\n8.8.8.8\n8.8.4.4';
                                            });
                                          }
                                        : null,
                                    child: Text(
                                      context.tr(
                                        TranslationKeys
                                            .vpnSettingsDnsResetDefault,
                                      ),
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsChangesEffect,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: AppTheme.secondaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsPingBatchSize,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsPingBatchSizeDesc,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: pingBatchSizeController,
                                decoration: InputDecoration(
                                  hintText: context.tr(
                                    'vpn_settings.ping_batch_size_hint',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.cardDark,
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        pingBatchSizeController.text = '5';
                                      });
                                    },
                                    child: Text(
                                      context.tr(
                                        TranslationKeys.vpnSettingsResetDefault,
                                      ),
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: AppTheme.secondaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsAboutBypass,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsAboutBypassDesc,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsAboutBypassExample,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 8),
                              Text(
                                context.tr(
                                  TranslationKeys.vpnSettingsChangesEffect,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
