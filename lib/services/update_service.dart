import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

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

enum UpdateCheckStatus { updateAvailable, upToDate, error }

class UpdateCheckResult {
  final UpdateCheckStatus status;
  final GithubRelease? release;

  const UpdateCheckResult({required this.status, this.release});

  bool get hasUpdate => status == UpdateCheckStatus.updateAvailable && release != null;
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

  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _sendTimeout = Duration(seconds: 15);
  static const Duration _checkTimeout = Duration(seconds: 30);
  static const Duration _downloadTimeout = Duration(minutes: 10);

  static UpdateService? _instance;

  final Dio _dio;

  UpdateService._() : _dio = _createDio();

  @visibleForTesting
  UpdateService.forTesting(Dio dio) : _dio = dio;

  factory UpdateService() {
    _instance ??= UpdateService._();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio();
    dio.options
      ..connectTimeout = _connectTimeout
      ..sendTimeout = _sendTimeout;
    return dio;
  }

  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _apiUrl,
        options: Options(
          receiveTimeout: _checkTimeout,
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            if (_githubToken.isNotEmpty) 'Authorization': 'token $_githubToken',
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        return const UpdateCheckResult(status: UpdateCheckStatus.error);
      }

      final tagName = data['tag_name'] as String? ?? '';
      final version = _stripVersionPrefix(tagName);
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

      if (version.isEmpty || apkUrl == null || assetId == null) {
        return const UpdateCheckResult(status: UpdateCheckStatus.error);
      }

      final currentVersion = await getCurrentVersion();
      if (!isNewerVersion(version, currentVersion)) {
        return const UpdateCheckResult(status: UpdateCheckStatus.upToDate);
      }

      return UpdateCheckResult(
        status: UpdateCheckStatus.updateAvailable,
        release: GithubRelease(
          version: version,
          releaseNote: releaseNote,
          apkUrl: apkUrl,
          assetId: assetId,
        ),
      );
    } on DioException catch (e) {
      debugPrint('Error checking for updates: ${e.message}');
      return const UpdateCheckResult(status: UpdateCheckStatus.error);
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return const UpdateCheckResult(status: UpdateCheckStatus.error);
    }
  }

  static String _stripVersionPrefix(String raw) {
    var version = raw.trim();
    if (version.startsWith('v') || version.startsWith('V')) {
      version = version.substring(1);
    }
    return version;
  }

  static ({List<int> numbers, String? prerelease})? _parseSemVer(String raw) {
    final version = _stripVersionPrefix(raw);
    final dashIndex = version.indexOf('-');
    final plusIndex = version.indexOf('+');
    String main;
    String? prerelease;
    if (dashIndex >= 0) {
      main = version.substring(0, dashIndex);
      final preEnd = plusIndex > dashIndex ? plusIndex : version.length;
      prerelease = version.substring(dashIndex + 1, preEnd);
    } else {
      main = plusIndex >= 0 ? version.substring(0, plusIndex) : version;
    }

    final parts = main.split('.');
    if (parts.isEmpty || parts.any((p) => p.isEmpty)) return null;

    final numbers = <int>[];
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0) return null;
      numbers.add(n);
    }
    return (numbers: numbers, prerelease: prerelease);
  }

  static bool isNewerVersion(String newVersion, String currentVersion) {
    final newSem = _parseSemVer(newVersion);
    final curSem = _parseSemVer(currentVersion);
    if (newSem == null || curSem == null) return false;

    final maxLen = newSem.numbers.length > curSem.numbers.length
        ? newSem.numbers.length
        : curSem.numbers.length;

    for (var i = 0; i < maxLen; i++) {
      final n = i < newSem.numbers.length ? newSem.numbers[i] : 0;
      final c = i < curSem.numbers.length ? curSem.numbers[i] : 0;
      if (n > c) return true;
      if (n < c) return false;
    }

    if (curSem.prerelease == null) return false;
    if (newSem.prerelease == null) return true;
    return newSem.prerelease!.compareTo(curSem.prerelease!) > 0;
  }

  Future<String?> downloadApk(
    String downloadUrl, {
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
    @visibleForTesting String? overrideDirectory,
  }) async {
    String tmpPath = '';
    String filePath = '';
    try {
      final dir = overrideDirectory != null
          ? Directory(overrideDirectory)
          : await getTemporaryDirectory();
      final unique = DateTime.now().millisecondsSinceEpoch.toString();
      filePath = '${dir.path}/update_$unique.apk';
      tmpPath = '$filePath.tmp';

      await _dio.download(
        downloadUrl,
        tmpPath,
        cancelToken: cancelToken,
        deleteOnError: true,
        options: Options(
          receiveTimeout: _downloadTimeout,
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

      final tmpFile = File(tmpPath);
      if (!await tmpFile.exists() || await tmpFile.length() == 0) {
        throw const FileSystemException('Descarga incompleta o vacia');
      }

      final finalFile = File(filePath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tmpFile.rename(finalFile.path);

      return filePath;
    } catch (e) {
      debugPrint('Error downloading APK: $e');
      try {
        final tmpFile = File(tmpPath);
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (_) {}
      return null;
    }
  }

  Future<bool> installApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final result = await OpenFile.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error installing APK: $e');
      return false;
    }
  }
}
