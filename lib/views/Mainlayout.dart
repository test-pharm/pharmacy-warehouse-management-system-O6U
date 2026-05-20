import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/views/DashboardView.dart';
import 'package:graduation_project/views/InventoryView.dart';
import 'package:graduation_project/views/OrdersView.dart';
import 'package:graduation_project/views/ReportsPage.dart';
import 'package:graduation_project/views/UserInfo.dart';
import 'package:graduation_project/main.dart';
import 'package:graduation_project/Services/update_service.dart';
import 'package:graduation_project/views/StocktakePage.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = AuthService.isSupervisor ? 0 : widget.initialIndex;
  }

  void _onSelect(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
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
      UserInfoPage(),
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

  Future<void> _logout() async {
    await AuthService.logout();
  }

  /// Toggle language between English and Arabic, persist choice.
  Future<void> _toggleLanguage() async {
    final next = languageNotifier.value == AppLanguage.en
        ? AppLanguage.ar
        : AppLanguage.en;
    languageNotifier.value = next;
    await saveLanguage(next);
  }

  @override
  Widget build(BuildContext context) {
    // Re-build sidebar whenever the language changes
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final tr = AppLocalizations.of(lang);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final provider = ProductProvider.of(context);
        final pages = _getPages();
        final menuItems = _getMenuItems(tr);
        final roleColor =
            AuthService.isWarehouseManager ? Colors.blue : Colors.green;
        final fullName = AuthService.currentUser?.fullName ?? '';

        final criticalCount = provider.getCriticalAlertsCount();
        final lowStockCount = provider.lowStockCount;
        final hasAnyAlerts = criticalCount > 0 || lowStockCount > 0;

        return Scaffold(
          body: Row(
            children: [
              // ── Sidebar ────────────────────────────────────────────────────
              Container(
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 18),
                color: isDark
                    ? const Color(0xFF071014)
                    : const Color(0xFFEAF2F3),
                child: Column(
                  children: [
                    // App brand + user name
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor: roleColor.withOpacity(0.16),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/pharmacy faculty logo.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr.pharmaWarehouse,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  fullName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Role badge
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AuthService.isWarehouseManager
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AuthService.isWarehouseManager
                            ? tr.manager
                            : tr.supervisor,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AuthService.isWarehouseManager
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Nav items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: menuItems.map((item) {
                          return _sidebarItem(
                              item.icon, item.label, item.index, isDark);
                        }).toList(),
                      ),
                    ),

                    if (AuthService.isWarehouseManager && hasAnyAlerts)
                      _alertSummaryPanel(
                        tr: tr,
                        criticalCount: criticalCount,
                        lowStockCount: lowStockCount,
                        isDark: isDark,
                      ),

                    const Divider(height: 1),

                    // ── Bottom toolbar ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // Dark/light mode toggle
                          IconButton(
                            onPressed: () {
                              themeNotifier.value =
                                  themeNotifier.value == ThemeMode.dark
                                      ? ThemeMode.light
                                      : ThemeMode.dark;
                            },
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            tooltip: tr.toggleTheme,
                          ),

                          // ── Language toggle ────────────────────────────────
                          IconButton(
                            onPressed: _toggleLanguage,
                            tooltip: tr.toggleLanguage,
                            icon: Text(
                              lang == AppLanguage.ar ? 'EN' : 'عربي',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Logout
                          IconButton(
                            onPressed: _logout,
                            icon: Icon(
                              Icons.logout,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            tooltip: tr.logout,
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<String>(
                      future: UpdateService.currentVersion,
                      builder: (context, snapshot) {
                        final v = snapshot.data ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            v.isNotEmpty ? 'v$v' : '',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Page content ───────────────────────────────────────────────
              Expanded(child: pages[_selectedIndex]),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebarItem(
      IconData icon, String label, int index, bool isDark) {
    final selected = index == _selectedIndex;
    final selectedColor =
        isDark ? Colors.lightBlueAccent : Colors.blueAccent;
    final defaultColor = isDark ? Colors.white70 : Colors.black54;
    final textColor = selected
        ? selectedColor
        : (isDark ? Colors.white : Colors.black87);

    return ListTile(
      dense: true,
      leading: Icon(icon, color: selected ? selectedColor : defaultColor),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: selectedColor.withOpacity(0.1),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () => _onSelect(index),
    );
  }

  Widget _alertSummaryPanel({
    required AppLocalizations tr,
    required int criticalCount,
    required int lowStockCount,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 15),
              const SizedBox(width: 5),
              Text(
                tr.criticalAlerts(criticalCount),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (criticalCount > 0) ...[
            const SizedBox(height: 5),
            _alertSummaryRow(
              Icons.error_outline,
              Colors.red,
              tr.expiredExpiringSoon(criticalCount),
            ),
          ],
          if (lowStockCount > 0) ...[
            const SizedBox(height: 4),
            _alertSummaryRow(
              Icons.inventory_2_outlined,
              Colors.orange,
              tr.lowStockItems(lowStockCount),
            ),
          ],
        ],
      ),
    );
  }

  Widget _alertSummaryRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              style: TextStyle(color: color, fontSize: 11)),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final int index;
  _MenuItem(this.icon, this.label, this.index);
}

// ─── Orders wrapper ───────────────────────────────────────────────────────────

class OrdersPageWithPrint extends StatelessWidget {
  const OrdersPageWithPrint({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      children: [
        if (AuthService.isSupervisor)
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.blue.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr.supervisorReadOnly,
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              const OrdersPage(),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _printOrders(context, tr),
                  icon: const Icon(Icons.print),
                  label: Text(tr.printOrders),
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _printOrders(BuildContext context, AppLocalizations tr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.printingOrders)),
    );
  }
}

// ─── Reports wrapper ──────────────────────────────────────────────────────────

class ReportsPageWithPrint extends StatelessWidget {
  const ReportsPageWithPrint({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      children: [
        if (AuthService.isSupervisor)
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.blue.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr.supervisorReportReadOnly,
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              const ReportsPage(),
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _printReports(context, tr),
                  icon: const Icon(Icons.print),
                  label: Text(tr.printReport),
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _printReports(BuildContext context, AppLocalizations tr) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr.printingReport)),
    );
  }
}