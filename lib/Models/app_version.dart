class AppVersion {
  final String latestVersion;
  final int latestBuildNumber;
  final String downloadUrl;
  final bool mandatory;
  final List<String> releaseNotes;

  AppVersion({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.downloadUrl,
    this.mandatory = false,
    this.releaseNotes = const [],
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      latestVersion: json['latestVersion'] as String? ?? '0.0.0',
      latestBuildNumber: json['latestBuildNumber'] as int? ?? 0,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      mandatory: json['mandatory'] as bool? ?? false,
      releaseNotes: (json['releaseNotes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool isNewerThan(String localVersion, int localBuild) {
    final remoteParts = latestVersion.split('.').map(int.parse).toList();
    final localParts = localVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final r = remoteParts.length > i ? remoteParts[i] : 0;
      final l = localParts.length > i ? localParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }

    return latestBuildNumber > localBuild;
  }

  Map<String, dynamic> toJson() => {
        'latestVersion': latestVersion,
        'latestBuildNumber': latestBuildNumber,
        'downloadUrl': downloadUrl,
        'mandatory': mandatory,
        'releaseNotes': releaseNotes,
      };
}
