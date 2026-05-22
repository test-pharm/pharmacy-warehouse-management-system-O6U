import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Services/MaterialSerivce.dart';
import 'package:graduation_project/Services/ProductService.dart';
import 'package:graduation_project/Services/TransliterationService.dart';
import 'package:graduation_project/Services/alertService.dart';
import 'package:graduation_project/Services/thresholdService.dart';

class ProductProvider extends ChangeNotifier {
  List<MaterialModel> _products = [];
  bool _loading = false;
  String? _error;

  int _lowStockThreshold = 100;
  int _expiringSoonDays = 30;

  Future<void> loadThresholds() async {
    _lowStockThreshold = await ThresholdService.getLowStockThreshold();
    _expiringSoonDays = await ThresholdService.getExpiringSoonDays();
  }

  // Stores confirmed server-writes that the backend hasn't reflected yet in
  // its GET response (read-after-write lag).  Applied after every fetch —
  // including manual refresh — until the server itself returns the correct
  // value, at which point the override is automatically removed.
  final Map<String, Map<String, dynamic>> _pendingOverrides = {};

  List<MaterialModel> get products => UnmodifiableListView(_products);
  bool get loading => _loading;
  String? get error => _error;

  int get totalProducts => _products.length;

  int get expiredCount => _products.where((product) {
    final expiry = product.expiryDateValue;
    return expiry != null && expiry.isBefore(DateTime.now());
  }).length;

  int get expiringSoonCount => _products.where((product) {
    final expiry = product.expiryDateValue;
    if (expiry == null) {
      return false;
    }

    final days = expiry.difference(DateTime.now()).inDays;
    return days > 0 && days <= _expiringSoonDays;
  }).length;

  int getCriticalAlertsCount() => expiredCount + expiringSoonCount;

  int get lowStockCount =>
      _products.where((product) => product.quantity < _lowStockThreshold).length;

  Future<void> loadProducts() async {
    await loadThresholds();
    if (!AuthService.isAuthenticated) {
      clear(notify: true);
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _replaceProductsFromApi();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _loading = false;
    notifyListeners();
  }

  Future<String?> addProduct(Map<String, dynamic> body) async {
    try {
      await ProductService.addProduct(body);
      await _refreshProductsAfterMutation();
      return null;
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  Future<String?> updateProduct(String id, Map<String, dynamic> body) async {
    try {
      await ProductService.updateProduct(id, body);

      // Register a pending override so every subsequent fetch (including
      // manual refresh) keeps showing the correct values until the server
      // catches up and returns them itself.
      final expectedQty = body['quantity'] as int?;
      final expectedAvail = body['isAvailable'] as bool?;
      if (expectedQty != null || expectedAvail != null) {
        _pendingOverrides[id] = {
          if (expectedQty != null) 'quantity': expectedQty,
          if (expectedAvail != null) 'isAvailable': expectedAvail,
        };
      }

      await _replaceProductsFromApi();
      notifyListeners();
      return null;
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  Future<String?> deleteProduct(String id) async {
    try {
      final error = await ProductService.deleteProduct(id);
      if (error != null) {
        return error;
      }

      await _refreshProductsAfterMutation();
      return null;
    } catch (e) {
      return _handleMutationError(e);
    }
  }

  MaterialModel? findBySku(String sku) {
    try {
      return _products.firstWhere(
        (product) => product.sku.toLowerCase() == sku.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  MaterialModel? findById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  MaterialModel? findByNameOrSku(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return null;
    try {
      return _products.firstWhere(
        (product) =>
            product.sku.toLowerCase() == query ||
            product.name.toLowerCase() == query,
      );
    } catch (_) {
      return null;
    }
  }

  void clear({bool notify = false}) {
    _products = [];
    _loading = false;
    _error = null;
    _pendingOverrides.clear();
    _syncDerivedState();
    if (notify) {
      notifyListeners();
    }
  }

  void _syncDerivedState() {
    MaterialService.updateCache(_products);
    AlertService.initializeAlertsFromModels(_products);
  }

  Future<List<MaterialModel>> _fetchProductsFromApi() {
    return ProductService.getAllProducts();
  }

  Future<void> _replaceProductsFromApi() async {
    _products = await _fetchProductsFromApi();
    _applyPendingOverrides();
    await AlertService.reloadThresholds();
    await MaterialService.reloadThresholds();
    _syncDerivedState();
  }

  /// Transliterates product names and categories locally (no API, instant).
  /// No-op when language is English.
  Future<void> _translateProductNames() async {
    if (languageNotifier.value != AppLanguage.ar) return;
    if (_products.isEmpty) return;

    final allStrings = <String>{};
    for (final p in _products) {
      if (p.name.isNotEmpty) allStrings.add(p.name);
      if (p.category.isNotEmpty && p.category != 'Uncategorized') {
        allStrings.add(p.category);
      }
    }

    final map = TransliterationService.transliterateAll(allStrings.toList());

    _products = _products.map((p) {
      return p.copyWith(
        name: map[p.name] ?? p.name,
        category: map[p.category] ?? p.category,
      );
    }).toList();
  }

  // After every fetch, re-apply any writes the server hasn't committed yet.
  // Once the server returns the correct value we drop the override so it
  // doesn't interfere with legitimate future changes.
  void _applyPendingOverrides() {
    if (_pendingOverrides.isEmpty) return;
    for (int i = 0; i < _products.length; i++) {
      final overrides = _pendingOverrides[_products[i].id];
      if (overrides == null) continue;

      final expectedQty = overrides['quantity'] as int?;
      final expectedAvail = overrides['isAvailable'] as bool?;

      final serverMatchesWrite =
          (expectedQty == null || _products[i].quantity == expectedQty) &&
          (expectedAvail == null || _products[i].isAvailable == expectedAvail);

      if (serverMatchesWrite) {
        // Server caught up — remove the override.
        _pendingOverrides.remove(_products[i].id);
      } else {
        // Server still behind — keep overriding the local copy.
        _products[i] = _products[i].copyWith(
          quantity: expectedQty ?? _products[i].quantity,
          isAvailable: expectedAvail ?? _products[i].isAvailable,
        );
      }
    }
  }

  Future<void> _refreshProductsAfterMutation() async {
    _error = null;
    await _replaceProductsFromApi();
    notifyListeners();
  }

  String _handleMutationError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    _error = message;
    notifyListeners();
    return message;
  }

  static ProductProvider of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final inherited = context
          .dependOnInheritedWidgetOfExactType<_ProductProviderInherited>();
      assert(
        inherited != null,
        'ProductProviderScope is missing above this widget.',
      );
      return inherited!.provider;
    }

    final element = context
        .getElementForInheritedWidgetOfExactType<_ProductProviderInherited>();
    final widget = element?.widget;
    assert(
      widget != null,
      'ProductProviderScope is missing above this widget.',
    );
    return (widget as _ProductProviderInherited).provider;
  }
}

class ProductProviderScope extends StatefulWidget {
  final Widget child;

  const ProductProviderScope({super.key, required this.child});

  @override
  State<ProductProviderScope> createState() => _ProductProviderScopeState();
}

class _ProductProviderScopeState extends State<ProductProviderScope> {
  final ProductProvider _provider = ProductProvider();

  @override
  void initState() {
    super.initState();
    AuthService.sessionChanges.addListener(_handleSessionChange);
    languageNotifier.addListener(_handleLanguageChange);
    _handleSessionChange();
  }

  @override
  void dispose() {
    AuthService.sessionChanges.removeListener(_handleSessionChange);
    languageNotifier.removeListener(_handleLanguageChange);
    _provider.dispose();
    super.dispose();
  }

  void _handleSessionChange() {
    if (AuthService.isAuthenticated) {
      _provider.loadProducts();
    } else {
      _provider.clear(notify: true);
    }
  }

  /// Re-load products whenever the language toggles so names get translated
  /// (or reverted to English) immediately.
  void _handleLanguageChange() {
    if (AuthService.isAuthenticated) {
      TransliterationService.clearCache();
      _provider.loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _provider,
      builder: (context, _) {
        return _ProductProviderInherited(
          provider: _provider,
          child: widget.child,
        );
      },
    );
  }
}

class _ProductProviderInherited extends InheritedWidget {
  final ProductProvider provider;

  const _ProductProviderInherited({
    required this.provider,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ProductProviderInherited oldWidget) => true;
}