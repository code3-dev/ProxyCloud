import 'dart:convert';

class AppUpdate {
  final String version;
  final String url;
  final String messText;

  // Current app version - manually set
  static const String currentAppVersion = '3.8.3';

  AppUpdate({required this.version, required this.url, required this.messText});

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      version: json['version'] ?? '',
      url: json['url'] ?? '',
      messText: json['messText'] ?? '',
    );
  }

  static AppUpdate? fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return AppUpdate.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  bool hasUpdate() {
    // Use the manually set current version
    return _isNewerVersion(currentAppVersion, version);
  }

  bool _isNewerVersion(String currentVersion, String newVersion) {
    try {
      List<int> current = currentVersion.split('.').map(int.parse).toList();
      List<int> newer = newVersion.split('.').map(int.parse).toList();

      // Ensure both lists have at least 3 elements
      while (current.length < 3) {
        current.add(0);
      }
      while (newer.length < 3) {
        newer.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (newer[i] > current[i]) {
          return true;
        } else if (newer[i] < current[i]) {
          return false;
        }
      }
      return false; // Versions are equal
    } catch (e) {
      return false; // Error parsing versions
    }
  }
}
