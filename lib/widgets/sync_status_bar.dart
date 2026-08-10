import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/sync_service.dart';

class SyncStatusBar extends StatelessWidget {
  final bool isConnected;
  final SyncStatus syncStatus;
  final int pendingCount;

  const SyncStatusBar({
    super.key,
    required this.isConnected,
    required this.syncStatus,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (!isConnected) {
      bgColor = AppColors.orangeBg;
      textColor = AppColors.orangeText;
      icon = Icons.wifi_off_rounded;
      text = 'Sin conexion - se sincronizara al reconectar';
    } else if (syncStatus == SyncStatus.syncing) {
      bgColor = AppColors.blueBg;
      textColor = AppColors.blueText;
      icon = Icons.sync_rounded;
      text = 'Sincronizando...';
    } else if (syncStatus == SyncStatus.error) {
      bgColor = AppColors.errorBg;
      textColor = AppColors.errorText;
      icon = Icons.cloud_off_outlined;
      text = 'Error de sincronizacion';
    } else if (pendingCount > 0) {
      bgColor = AppColors.yellowBg;
      textColor = AppColors.yellowText;
      icon = Icons.cloud_upload_outlined;
      text = '$pendingCount cambios pendientes de subir';
    } else {
      bgColor = AppColors.greenBg;
      textColor = AppColors.greenText;
      icon = Icons.cloud_done_outlined;
      text = 'Todo sincronizado';
    }

    return Container(
      width: double.infinity,
      height: 32,
      color: bgColor,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncStatus == SyncStatus.syncing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
              )
            else
              Icon(icon, size: 14, color: textColor),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
