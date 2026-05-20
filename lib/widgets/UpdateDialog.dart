import 'package:flutter/material.dart';
import 'package:graduation_project/Models/app_version.dart';
import 'package:graduation_project/Services/download_service.dart';
import 'package:graduation_project/Services/update_service.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    final remote = await UpdateService.fetchLatestVersion();
    if (remote == null || !mounted) return;

    final localVersion = await UpdateService.currentVersion;
    final localBuild = await UpdateService.currentBuildNumber;

    if (!remote.isNewerThan(localVersion, localBuild)) return;

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
  DownloadProgress _progress = const DownloadProgress();
  bool _isDone = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final accent = isDark ? Colors.lightBlueAccent : const Color(0xFF0A6B6E);

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      content: SizedBox(
        width: 400,
        child: _isDone ? _buildDone(accent) : _buildUpdate(accent),
      ),
    );
  }

  Widget _buildUpdate(Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.system_update, color: accent, size: 28),
            const SizedBox(width: 10),
            Text(
              'Update Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Version ${widget.version.latestVersion} is now available.',
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54),
        ),
        if (widget.version.releaseNotes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('What\'s new:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          ...widget.version.releaseNotes.map((note) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: accent, fontSize: 13)),
                    Expanded(child: Text(note, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54))),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 16),
        if (_progress.state == DownloadState.idle) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.version.mandatory ? null : () => Navigator.pop(context),
                child: Text(widget.version.mandatory ? '' : 'Later', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Update Now'),
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
              ),
            ],
          ),
        ] else ...[
          if (_progress.state == DownloadState.downloading) ...[
            LinearProgressIndicator(value: _progress.progress, backgroundColor: isDark ? Colors.white12 : Colors.black12, color: accent),
            const SizedBox(height: 6),
            Text('Downloading... ${(_progress.progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
          ] else if (_progress.state == DownloadState.extracting) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 6),
            Text('Extracting...', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
          ] else if (_progress.state == DownloadState.launching) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 6),
            Text('Launching installer...', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
          ] else if (_progress.state == DownloadState.error) ...[
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 8),
            Text(_progress.error ?? 'Update failed', style: TextStyle(color: Colors.red.shade400, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildDone(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 56),
          const SizedBox(height: 12),
          Text('Update Complete', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('The app has been updated to version ${widget.version.latestVersion}.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
            style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _startDownload() {
    DownloadService.downloadAndInstall(
      url: widget.version.downloadUrl,
      onProgress: (p) {
        if (!mounted) return;
        setState(() => _progress = p);
      },
    ).then((result) {
      if (!mounted) return;
      if (result.state == DownloadState.error) {
        setState(() => _progress = result);
      }
    });
  }

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
}
