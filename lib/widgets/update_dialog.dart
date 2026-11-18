import 'package:flutter/material.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

void showBitifyUpdateDialog(BuildContext context, UpdateInfo info) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.system_update_rounded, color: AppTheme.secondary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info.hasUpdate ? 'Update Available!' : 'Bitify is Up to Date',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info.hasUpdate) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Current: ${info.currentVersion}  →  New: ${info.latestVersion}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "What's New:",
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child: Text(
                  info.releaseNotes,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                ),
              ),
            ),
          ] else ...[
            Text(
              'You are running the latest version (${info.currentVersion}) of Bitify.',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            info.hasUpdate ? 'Later' : 'Close',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ),
        if (info.hasUpdate)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download & Install', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () {
              Navigator.pop(context);
              UpdateService.launchDownload(info.downloadUrl);
            },
          ),
      ],
    ),
  );
}
