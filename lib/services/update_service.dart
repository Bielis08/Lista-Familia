
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class GithubRelease {
  final String version;
  final String? releaseNote;
  final String apkUrl;
  final String assetId;

  GithubRelease({
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
    defaultValue: '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',
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

      if (response.statusCode != 200) return null;

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

  static void showUpdateDialog(
    BuildContext context,
    GithubRelease release,
    UpdateService service,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _UpdateDialogWidget(release: release, service: service);
      },
    );
  }
}

class _UpdateDialogWidget extends StatefulWidget {
  final GithubRelease release;
  final UpdateService service;

  const _UpdateDialogWidget({required this.release, required this.service});

  @override
  State<_UpdateDialogWidget> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialogWidget> {
  bool _isDownloading = false;
  double _progress = 0.0;

  Future<void> _startDownloadAndInstall() async {
    setState(() => _isDownloading = true);

    final filePath = await widget.service.downloadApk(
      widget.release.assetId,
      (progress) {
        if (mounted) setState(() => _progress = progress);
      },
    );

    if (mounted) {
      if (filePath != null) {
        final installed = await widget.service.installApk(filePath);
        setState(() => _isDownloading = false);
        if (installed) {
          Navigator.of(context).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Actualización instalada. Reinicia la app.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al instalar la actualización')),
          );
        }
      } else {
        setState(() => _isDownloading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al descargar la actualización')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva actualización disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Versión ${widget.release.version} disponible.'),
          const SizedBox(height: 10),
          if (widget.release.releaseNote != null &&
              widget.release.releaseNote!.isNotEmpty) ...[
            const Text(
              'Cambios:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.maxFinite,
              child: Text(
                widget.release.releaseNote!,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_isDownloading) ...[
            const Text('Descargando...'),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 4),
            if (_progress > 0) Text('${(_progress * 100).toInt()}%'),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Más tarde'),
          ),
        if (!_isDownloading)
          ElevatedButton(
            onPressed: _startDownloadAndInstall,
            child: const Text('Actualizar ahora'),
          ),
      ],
    );
  }
}
