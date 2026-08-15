// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:async';

import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class HostCheckerScreen extends StatefulWidget {
  const HostCheckerScreen({super.key});

  @override
  State<HostCheckerScreen> createState() => _HostCheckerScreenState();
}

class _HostCheckerScreenState extends State<HostCheckerScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;
  int _timeoutSeconds = 10; // Default timeout in seconds

  // List of default URLs for quick selection
  final List<String> _defaultUrls = [
    'https://www.google.com',
    'https://www.youtube.com',
    'https://firebase.google.com',
    'https://x.com',
    'https://chatgpt.com',
    'https://gemini.google.com',
    'https://www.tiktok.com',
    'https://www.instagram.com',
    'https://www.facebook.com',
    'https://telegram.org',
    'https://www.github.com',
    'https://www.stackoverflow.com',
    'https://www.reddit.com',
    'https://www.wikipedia.org',
    'https://www.amazon.com',
    'https://www.netflix.com',
    'https://www.spotify.com',
    'https://www.discord.com',
    'https://www.whatsapp.com',
    'https://www.linkedin.com',
    'https://www.microsoft.com',
    'https://www.apple.com',
    'https://www.cloudflare.com',
    'https://www.bing.com',
    'https://www.yahoo.com',
    'https://www.duckduckgo.com',
    'https://www.twitch.tv',
    'https://www.paypal.com',
  ];

  // Map of URL display names
  final Map<String, String> _urlDisplayNames = {
    'https://www.google.com': 'Google',
    'https://www.youtube.com': 'YouTube',
    'https://firebase.google.com': 'Firebase',
    'https://x.com': 'X (Twitter)',
    'https://chatgpt.com': 'ChatGPT',
    'https://gemini.google.com': 'Gemini',
    'https://www.tiktok.com': 'TikTok',
    'https://www.instagram.com': 'Instagram',
    'https://www.facebook.com': 'Facebook',
    'https://telegram.org': 'Telegram',
    'https://www.github.com': 'GitHub',
    'https://www.stackoverflow.com': 'Stack Overflow',
    'https://www.reddit.com': 'Reddit',
    'https://www.wikipedia.org': 'Wikipedia',
    'https://www.amazon.com': 'Amazon',
    'https://www.netflix.com': 'Netflix',
    'https://www.spotify.com': 'Spotify',
    'https://www.discord.com': 'Discord',
    'https://www.whatsapp.com': 'WhatsApp',
    'https://www.linkedin.com': 'LinkedIn',
    'https://www.microsoft.com': 'Microsoft',
    'https://www.apple.com': 'Apple',
    'https://www.cloudflare.com': 'Cloudflare',
    'https://www.bing.com': 'Bing',
    'https://www.yahoo.com': 'Yahoo',
    'https://www.duckduckgo.com': 'DuckDuckGo',
    'https://www.twitch.tv': 'Twitch',
    'https://www.paypal.com': 'PayPal',
  };

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkHost() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _errorMessage = context.tr(TranslationKeys.hostCheckerErrorEmptyUrl);
      });
      return;
    }

    // Validate URL format
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _errorMessage = context.tr(TranslationKeys.hostCheckerErrorInvalidUrl);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final stopwatch = Stopwatch()..start();

      final response = await http
          .get(Uri.parse(url))
          .timeout(
            Duration(seconds: _timeoutSeconds),
            onTimeout: () {
              throw Exception(
                context.tr(
                  TranslationKeys.hostCheckerErrorTimeout,
                  parameters: {'seconds': _timeoutSeconds.toString()},
                ),
              );
            },
          );

      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;

      setState(() {
        _isLoading = false;
        _result = {
          'statusCode': response.statusCode,
          'responseTime': responseTime,
          'isSuccess': response.statusCode >= 200 && response.statusCode < 300,
          'headers': response.headers,
          'contentLength': response.contentLength,
          'timeoutUsed': _timeoutSeconds,
        };
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Instead of showing error message, create a result with status false
        _result = {
          'statusCode': 0,
          'responseTime': 0,
          'isSuccess': false,
          'headers': <String, String>{},
          'contentLength': 0,
          'timeoutUsed': _timeoutSeconds,
          'errorMessage': context.tr(
            TranslationKeys.hostCheckerErrorConnection,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.hostCheckerTitle)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUrlInput(),
            const SizedBox(height: 16),
            _buildTimeoutSettings(),
            const SizedBox(height: 24),
            _buildCheckButton(),
            const SizedBox(height: 24),
            Expanded(child: _buildResultSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Column(
      children: [
        Card(
          color: AppTheme.cardDark,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: context.tr(TranslationKeys.hostCheckerEnterUrl),
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.link,
                        color: AppTheme.connectedGreen,
                      ),
                      suffixIcon: _urlController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _urlController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _checkHost(),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.connectedGreen,
                  ),
                  tooltip: context.tr(
                    TranslationKeys.hostCheckerSelectDefaultUrl,
                  ),
                  onSelected: (String url) {
                    setState(() {
                      _urlController.text = url;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return _defaultUrls.map((String url) {
                      return PopupMenuItem<String>(
                        value: url,
                        child: Text(_urlDisplayNames[url] ?? url),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _defaultUrls.take(8).map((url) {
            return InkWell(
              onTap: () {
                setState(() {
                  _urlController.text = url;
                });
              },
              child: Chip(
                backgroundColor: AppTheme.cardDark,
                label: Text(
                  _urlDisplayNames[url] ?? url,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeoutSettings() {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timer,
                  color: AppTheme.connectedGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr(TranslationKeys.hostCheckerTimeoutSettings),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(
                      TranslationKeys.hostCheckerTimeoutSeconds,
                      parameters: {'seconds': _timeoutSeconds.toString()},
                    ),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    initialValue: _timeoutSeconds,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.connectedGreen,
                        ),
                      ),
                    ),
                    dropdownColor: AppTheme.cardDark,
                    style: const TextStyle(color: Colors.white),
                    items: [5, 10, 15, 20, 30, 45, 60]
                        .map(
                          (seconds) => DropdownMenuItem<int>(
                            value: seconds,
                            child: Text(
                              '${seconds}s',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _timeoutSeconds = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _checkHost,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              context.tr(TranslationKeys.hostCheckerCheckHost),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildResultSection() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              context.tr(TranslationKeys.hostCheckerCheckingHost),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              context.tr(TranslationKeys.commonError),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, color: Colors.grey[400], size: 64),
            const SizedBox(height: 16),
            Text(
              context.tr(TranslationKeys.hostCheckerEnterUrlInstruction),
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildResponseDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool isSuccess = _result!['isSuccess'] as bool;
    final int statusCode = _result!['statusCode'] as int;
    final int responseTime = _result!['responseTime'] as int;
    final String? errorMessage = _result!['errorMessage'] as String?;

    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(TranslationKeys.hostCheckerStatus),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSuccess
                            ? context.tr(TranslationKeys.hostCheckerSuccess)
                            : context.tr(TranslationKeys.hostCheckerFailed),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (statusCode > 0)
                        Text(
                          context.tr(
                            TranslationKeys.hostCheckerStatusCode,
                            parameters: {'code': statusCode.toString()},
                          ),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      if (responseTime > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                            TranslationKeys.hostCheckerResponseTime,
                            parameters: {'time': responseTime.toString()},
                          ),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                      if (errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseDetailsCard() {
    final int? contentLength = _result!['contentLength'] as int?;
    final bool isSuccess = _result!['isSuccess'] as bool;
    final int timeoutUsed = _result!['timeoutUsed'] as int;

    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(TranslationKeys.hostCheckerResponseDetails),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr(TranslationKeys.hostCheckerUrl),
              _urlController.text,
            ),
            if (contentLength != null && contentLength > 0)
              _buildInfoRow(
                context.tr(TranslationKeys.hostCheckerContentLength),
                '${(contentLength / 1024).toStringAsFixed(2)} KB',
              ),
            if (isSuccess) ...[
              const SizedBox(height: 8),
              Text(
                context.tr(TranslationKeys.hostCheckerHeadersSecurityNote),
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
