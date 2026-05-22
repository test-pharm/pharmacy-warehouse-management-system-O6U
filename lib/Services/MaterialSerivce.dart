import 'dart:collection';

// MaterialService is a read-only compatibility shim.
// ProductProvider owns mutations and passes the same live list reference here
// so older status/filter helpers do not keep a separate product copy.

import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Services/thresholdService.dart';

class MaterialService {
  // The provider sets this after every load/mutation.
  static List<MaterialModel> _cache = [];
  static int _lowStockThreshold = 100;
  static int _expiringSoonDays = 30;

  /// Called by ProductProvider every time _products changes.
  static void updateCache(List<MaterialModel> products) {
    _cache = products;
  }

  static Future<void> reloadThresholds() async {
    _lowStockThreshold = await ThresholdService.getLowStockThreshold();
    _expiringSoonDays = await ThresholdService.getExpiringSoonDays();
  }

  // ── Read-only helpers (UI compatibility) ──────────────────────────────────

  static List<MaterialModel> getAllMaterials() => UnmodifiableListView(_cache);

  static MaterialModel? getMaterialById(String id) {
    try {
      return _cache.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static String getMaterialStatus(MaterialModel material) {
    try {
      final expiry = DateTime.parse(material.expiryDate);
      final now = DateTime.now();
      if (expiry.isBefore(now)) return 'Expired';
      if (expiry.difference(now).inDays <= _expiringSoonDays) return 'Expiring Soon';
      if (material.quantity < _lowStockThreshold) return 'Low Stock';
      return 'Good';
    } catch (_) {
      return 'Unknown';
    }
  }

  static List<MaterialModel> getLowStockMaterials() =>
      _cache.where((m) => m.quantity < _lowStockThreshold).toList();

  static List<MaterialModel> getExpiredMaterials() => _cache.where((m) {
    try {
      return DateTime.parse(m.expiryDate).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }).toList();

  static List<MaterialModel> getExpiringSoonMaterials() => _cache.where((m) {
    try {
      final diff = DateTime.parse(
        m.expiryDate,
      ).difference(DateTime.now()).inDays;
      return diff > 0 && diff <= _expiringSoonDays;
    } catch (_) {
      return false;
    }
  }).toList();

  static List<Map<String, dynamic>> getMaterialsAsMap() =>
      _cache.map((m) => m.toJson()).toList();
}


