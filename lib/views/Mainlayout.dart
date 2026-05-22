import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/views/DashboardView.dart';
import 'package:graduation_project/views/InventoryView.dart';
import 'package:graduation_project/views/OrdersView.dart';
import 'package:graduation_project/views/ReportsPage.dart';
import 'package:graduation_project/views/ThresholdSettingsPage.dart';
import 'package:graduation_project/main.dart';
import 'package:graduation_project/Services/update_service.dart';
import 'package:graduation_project/views/StocktakePage.dart';
import 'package:graduation_project/widgets/toast.dart';
import 'package:graduation_project/widgets/UpdateDialog.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  late int _selectedIndex;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = AuthService.isSupervisor ? 0 : widget.initialIndex;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final w = WidgetsBinding.instance.window.physicalSize.shortestSide /
        WidgetsBinding.instance.window.devicePixelRatio;
    final shouldCollapse = w < 900;
    if (shouldCollapse != _sidebarCollapsed && mounted) {
      setState(() => _sidebarCollapsed = shouldCollapse);
    }
  }

  void _onSelect(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    final w = MediaQuery.of(context).size.width;
    if (w < 900 && !_sidebarCollapsed) {
      setState(() => _sidebarCollapsed = true);
    }
  }

  List<Widget> _getPages() {
    if (AuthService.isSupervisor) {
      return [
        OrdersPage(onGoToOrders: () => _onSelect(0)),
        ReportsPage(onGoToOrders: () => _onSelect(0)),
      ];
    }
    return const [
      DashboardPage(),
      InventoryPage(),
      StocktakePage(),
      ReportsPage(),
      OrdersPage(),
      ThresholdSettingsPage(),
    ];
  }

  List<_MenuItem> _getMenuItems(AppLocalizations tr) {
    if (AuthService.isSupervisor) {
      return [
        _MenuItem(Icons.list_alt, tr.orders, 0),
        _MenuItem(Icons.bar_chart, tr.reports, 1),
      ];
    }
    return [
      _MenuItem(Icons.dashboard, tr.dashboard, 0),
      _MenuItem(Icons.inventory_2, tr.inventory, 1),
      _MenuItem(Icons.assignment, 'Stocktake', 2),
      _MenuItem(Icons.bar_chart, tr.reports, 3),
      _MenuItem(Icons.list_alt, tr.orders, 4),
      _MenuItem(Icons.settings, tr.settings, 5),
    ];
  }

  Future<void> _logout() async => await AuthService.logout();

  Future<void> _checkForUpdates() async {
    final available = await UpdateService.isUpdateAvailable();
    if (!mounted) return;

    if (available) {
      final remote = await UpdateService.fetchLatestVersion();
      if (remote == null || !mounted) return;
      showDialog(
        context: context,
        builder: (_) => UpdateDialog(version: remote),
      );
    } else {
      showToast(context, context.tr.upToDate);
    }
  }

  Future<void> _toggleLanguage() async {
    final next = languageNotifier.value == AppLanguage.en ? AppLanguage.ar : AppLanguage.en;
    languageNotifier.value = next;
    await saveLanguage(next);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final tr = AppLocalizations.of(lang);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final provider = ProductProvider.of(context);
        final pages = _getPages();
        final menuItems = _getMenuItems(tr);
        final roleColor = AuthService.isWarehouseManager ? Colors.blue : Colors.green;
        final fullName = AuthService.currentUser?.fullName ?? '';

        final criticalCount = provider.getCriticalAlertsCount();
        final lowStockCount = provider.lowStockCount;
        final sidebarWidth = _sidebarCollapsed ? 60.0 : 220.0;

        return Scaffold(
          body: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: sidebarWidth,
                padding: const EdgeInsets.symmetric(vertical: 18),
                color: isDark ? const Color(0xFF071014) : const Color(0xFFEAF2F3),
                child: Column(
                  children: [
                    if (!_sidebarCollapsed) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 27,
                              backgroundColor: roleColor.withOpacity(0.16),
                              child: ClipOval(
                                child: Image.asset('assets/pharmacy faculty logo.png',
                                    width: 50, height: 50, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr.pharmaWarehouse,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                                          color: isDark ? Colors.white : Colors.black87)),
                                  Text(fullName,
                                      style: TextStyle(fontSize: 10,
                                          color: isDark ? Colors.white60 : Colors.black54),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AuthService.isWarehouseManager ? tr.manager : tr.supervisor,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: roleColor),
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: roleColor.withOpacity(0.16),
                          child: ClipOval(
                            child: Image.asset('assets/pharmacy faculty logo.png',
                                width: 36, height: 36, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        children: menuItems.map((item) {
                          return _sidebarItem(
                            item.icon, item.label, item.index, isDark,
                          );
                        }).toList(),
                      ),
                    ),
                    if (AuthService.isWarehouseManager && !_sidebarCollapsed && (criticalCount > 0 || lowStockCount > 0))
                      _alertSummaryPanel(tr: tr, criticalCount: criticalCount, lowStockCount: lowStockCount, isDark: isDark),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                            icon: Icon(_sidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                                size: 18, color: isDark ? Colors.white70 : Colors.black54),
                            tooltip: _sidebarCollapsed ? 'Expand' : 'Collapse',
                          ),
                          if (!_sidebarCollapsed) ...[
                            IconButton(
                              onPressed: () => themeNotifier.value = themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                                  color: isDark ? Colors.white70 : Colors.black54),
                              tooltip: tr.toggleTheme,
                            ),
                            IconButton(
                              onPressed: _toggleLanguage,
                              tooltip: tr.toggleLanguage,
                              icon: Text(lang == AppLanguage.ar ? 'EN' : 'عربي',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : Colors.black54)),
                            ),
                            IconButton(
                              onPressed: _logout,
                              icon: Icon(Icons.logout, color: isDark ? Colors.white70 : Colors.black54),
                              tooltip: tr.logout,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!_sidebarCollapsed)
                      FutureBuilder<String>(
                        future: UpdateService.currentVersion,
                        builder: (context, snapshot) {
                          final v = snapshot.data ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: _checkForUpdates,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(v.isNotEmpty ? 'v$v' : '',
                                    style: TextStyle(fontSize: 11,
                                        color: isDark ? Colors.white38 : Colors.black38)),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Expanded(child: pages[_selectedIndex]),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index, bool isDark) {
    final selected = index == _selectedIndex;
    final selectedColor = isDark ? Colors.lightBlueAccent : Colors.blueAccent;
    final defaultColor = isDark ? Colors.white70 : Colors.black54;

    return Tooltip(
      message: _sidebarCollapsed ? label : '',
      child: ListTile(
        dense: true,
            leading: Icon(icon, color: selected ? selectedColor : defaultColor),
        title: _sidebarCollapsed ? null : Text(label,
            style: TextStyle(color: selected ? selectedColor : (isDark ? Colors.white : Colors.black87),
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        selected: selected,
        selectedTileColor: selectedColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _onSelect(index),
      ),
    );
  }

  Widget _alertSummaryPanel({required AppLocalizations tr, required int criticalCount, required int lowStockCount, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 15),
            const SizedBox(width: 5),
            Text(tr.criticalAlerts(criticalCount),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
          if (criticalCount > 0) ...[
            const SizedBox(height: 5),
            _alertRow(Icons.error_outline, Colors.red, tr.expiredExpiringSoon(criticalCount)),
          ],
          if (lowStockCount > 0) ...[
            const SizedBox(height: 4),
            _alertRow(Icons.inventory_2_outlined, Colors.orange, tr.lowStockItems(lowStockCount)),
          ],
        ],
      ),
    );
  }

  Widget _alertRow(IconData icon, Color color, String text) {
    return Row(children: [
      Icon(icon, color: color, size: 12),
      const SizedBox(width: 5),
      Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 11))),
    ]);
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final int index;
  _MenuItem(this.icon, this.label, this.index);
}


