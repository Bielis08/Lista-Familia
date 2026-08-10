import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class GithubRelease {
  final String version;
  final String? releaseNote;
  final String apkUrl;
  final String assetId;

  const GithubRelease({
    required this.version,
    this.releaseNote,
    required this.apkUrl,
    required this.assetId,
  });
}

class UpdateService {
  static const String _ownerGithub = 'Bielis08';
  static const String _repositoryGithub = 'Lista-Familia';
  static const String _apiUrl =
      'https://api.github.com/repos/$_ownerGithub/$_repositoryGithub/releases/latest';

  static const String _githubToken = String.fromEnvironment(
    'GITHUB_TOKEN',
    defaultValue: '',
  );

  final Dio _dio = Dio();

  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<GithubRelease?> checkForUpdate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _apiUrl,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            if (_githubToken.isNotEmpty) 'Authorization': 'token $_githubToken',
          },
        ),
      );

      final data = response.data;
      if (data == null) return null;

      final tagName = data['tag_name'] as String? ?? '';
      final version = tagName.replaceFirst('v', '');
      final releaseNote = data['body'] as String?;

      String? apkUrl;
      String? assetId;
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          assetId = asset['id']?.toString();
          break;
        }
      }

      if (apkUrl == null || assetId == null || version.isEmpty) return null;

      final currentVersion = await getCurrentVersion();
      if (!_isNewerVersion(version, currentVersion)) return null;

      return GithubRelease(
        version: version,
        releaseNote: releaseNote,
        apkUrl: apkUrl,
        assetId: assetId,
      );
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  bool _isNewerVersion(String newVersion, String currentVersion) {
    final newParts = newVersion.split('.').map(int.tryParse).whereType<int>().toList();
    final currentParts = currentVersion.split('.').map(int.tryParse).whereType<int>().toList();

    final maxLen = newParts.length > currentParts.length
        ? newParts.length
        : currentParts.length;

    for (var i = 0; i < maxLen; i++) {
      final n = i < newParts.length ? newParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (n > c) return true;
      if (n < c) return false;
    }
    return false;
  }

  Future<String?> downloadApk(
    String assetId,
    void Function(double progress)? onProgress,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/update.apk';

      final downloadUrl =
          'https://api.github.com/repos/$_ownerGithub/$_repositoryGithub/releases/assets/$assetId';

      await _dio.download(
        downloadUrl,
        filePath,
        options: Options(
          headers: {
            'Accept': 'application/octet-stream',
            if (_githubToken.isNotEmpty) 'Authorization': 'token $_githubToken',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      return filePath;
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      return null;
    }
  }

  Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error installing APK: $e');
      return false;
    }
  }
}
