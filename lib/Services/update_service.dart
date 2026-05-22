import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:graduation_project/Models/app_version.dart';

class UpdateService {
  static const String _versionUrl =
      'https://raw.githubusercontent.com/MohamedShalaby24/pharmacy-warehouse-management-system-O6U/main/version.json';

  static AppVersion? _cachedRemote;
  static PackageInfo? _packageInfo;

  static Future<PackageInfo> get packageInfo async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  static Future<String> get currentVersion async {
    final info = await packageInfo;
    return info.version;
  }

  static Future<int> get currentBuildNumber async {
    final info = await packageInfo;
    return int.tryParse(info.buildNumber) ?? 0;
  }

  static Future<AppVersion?> fetchLatestVersion() async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      _cachedRemote = AppVersion.fromJson(decoded);
      return _cachedRemote;
    } catch (e) {
      debugPrint('[UpdateService] Failed to fetch latest version: $e');
      return _cachedRemote;
    }
  }

  static Future<bool> isUpdateAvailable() async {
    try {
      final remote = await fetchLatestVersion();
      if (remote == null) return false;

      final localVersion = await currentVersion;
      final localBuild = await currentBuildNumber;

      return remote.isNewerThan(localVersion, localBuild);
    } catch (_) {
      return false;
    }
  }

}
