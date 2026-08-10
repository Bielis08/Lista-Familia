import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final GithubRelease release;
  final UpdateService service;

  const UpdateDialog({
    super.key,
    required this.release,
    required this.service,
  });

  static void show(BuildContext context, GithubRelease release, UpdateService service) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(release: release, service: service),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;

  Future<void> _startDownloadAndInstall() async {
    if (!mounted) return;
    setState(() => _isDownloading = true);

    final filePath = await widget.service.downloadApk(
      widget.release.assetId,
      (progress) {
        if (mounted) setState(() => _progress = progress);
      },
    );

    if (!mounted) return;

    if (filePath != null) {
      final installed = await widget.service.installApk(filePath);
      if (!mounted) return;
      setState(() => _isDownloading = false);
      if (installed) {
        Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Actualizacion instalada. Reinicia la app.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al instalar la actualizacion')),
        );
      }
    } else {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al descargar la actualizacion')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva actualizacion disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version ${widget.release.version} disponible.'),
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
            child: const Text('Mas tarde'),
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
