import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String releaseNotes;
  final String downloadUrl;

  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class UpdateService {
  // Current app version installed
  static const String currentVersion = 'v1.0.31';

  // GitHub Release Endpoint for Bitify
  static const String _releasesApiUrl =
      'https://api.github.com/repos/prosenjitdebnath08/bitify/releases/latest';

  /// Check if a newer version is available on GitHub
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_releasesApiUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latestTag = data['tag_name'] as String? ?? currentVersion;
        final title = data['name'] as String? ?? 'Bitify Update';
        final body = data['body'] as String? ?? 'New performance enhancements & bug fixes.';

        String downloadUrl = 'https://github.com/prosenjitdebnath08/bitify/releases/latest/download/app-release.apk';
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? downloadUrl;
            break;
          }
        }

        final hasUpdate = _isNewerVersion(latestTag, currentVersion);

        return UpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: currentVersion,
          latestVersion: latestTag,
          title: title,
          releaseNotes: body,
          downloadUrl: downloadUrl,
        );
      }
    } catch (e) {
      debugPrint('UpdateService check error: $e');
    }

    return const UpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      title: 'Up to Date',
      releaseNotes: 'You are using the latest version of Bitify.',
      downloadUrl: '',
    );
  }

  /// Launch download URL in phone's browser
  static Future<void> launchDownload(String url) async {
    final uri = Uri.parse(
      url.isNotEmpty
          ? url
          : 'https://github.com/prosenjitdebnath08/bitify/releases/latest/download/app-release.apk',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch update URL: $e');
    }
  }

  /// Compare version tags like 'v1.0.5' > 'v1.0.4'
  static bool _isNewerVersion(String latest, String current) {
    if (latest == current) return false;
    final lClean = latest.replaceAll('v', '').trim();
    final cClean = current.replaceAll('v', '').trim();

    final lParts = lClean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final cParts = cClean.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (int i = 0; i < lParts.length && i < cParts.length; i++) {
      if (lParts[i] > cParts[i]) return true;
      if (lParts[i] < cParts[i]) return false;
    }

    return lParts.length > cParts.length;
  }
}
