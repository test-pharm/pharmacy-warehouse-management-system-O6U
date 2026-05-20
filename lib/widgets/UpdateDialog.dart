import 'package:flutter/material.dart';
import 'package:graduation_project/Models/app_version.dart';
import 'package:graduation_project/Services/download_service.dart';
import 'package:graduation_project/Services/update_service.dart';
import 'package:graduation_project/Models/app_localizations.dart';

class UpdateCheckScope extends StatefulWidget {
  final Widget child;

  const UpdateCheckScope({super.key, required this.child});

  @override
  State<UpdateCheckScope> createState() => _UpdateCheckScopeState();
}

class _UpdateCheckScopeState extends State<UpdateCheckScope> {
  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    await Future.delayed(const Duration(seconds: 2));

    final available = await UpdateService.isUpdateAvailable();
    if (!available || !mounted) return;

    final remote = await UpdateService.fetchLatestVersion();
    if (remote == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: !remote.mandatory,
      builder: (_) => UpdateDialog(version: remote),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class UpdateDialog extends StatefulWidget {
  final AppVersion version;

  const UpdateDialog({super.key, required this.version});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  DownloadProgress _progress = const DownloadProgress();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B2430) : Colors.white;

    return PopScope(
      canPop: !_downloading,
      child: Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(isDark),
              const SizedBox(height: 18),
              Text(
                _downloading
                    ? _progress.state == DownloadState.launching
                        ? context.tr.installingUpdate
                        : context.tr.downloadingUpdate
                    : context.tr.updateAvailable,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _downloading
                    ? _progress.state == DownloadState.extracting
                        ? 'Extracting update package...'
                        : _progress.state == DownloadState.launching
                            ? 'Launching installer...'
                            : _progress.state == DownloadState.error
                                ? _progress.error ?? 'Download failed'
                                : 'Version ${widget.version.latestVersion}'
                    : 'Version ${widget.version.latestVersion} is now available.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              if (!_downloading && widget.version.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildReleaseNotes(isDark),
              ],
              if (_downloading) ...[
                const SizedBox(height: 20),
                _buildProgressBar(isDark),
                const SizedBox(height: 8),
                Text(
                  _progress.progress > 0
                      ? '${(_progress.progress * 100).toStringAsFixed(0)}%'
                      : '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!_downloading)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _startDownload,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(context.tr.updateNow),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A6B6E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (!_downloading && !widget.version.mandatory) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr.maybeLater),
                  ),
                ),
              ],
              if (_downloading &&
                  _progress.state == DownloadState.error) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr.close),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReleaseNotes(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.whatsNew,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...widget.version.releaseNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('\u2022 ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: _progress.progress,
        minHeight: 8,
        backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A6B6E)),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0A6B6E).withOpacity(0.1),
      ),
      child: _downloading
          ? const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            )
          : const Icon(
              Icons.system_update_rounded,
              size: 36,
              color: Color(0xFF0A6B6E),
            ),
    );
  }

  Future<void> _startDownload() async {
    final url = widget.version.downloadUrl;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.downloadUrlNotConfigured)),
      );
      return;
    }

    setState(() => _downloading = true);

    await DownloadService.downloadAndInstall(
      url: url,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() => _progress = progress);
      },
    );
  }
}
