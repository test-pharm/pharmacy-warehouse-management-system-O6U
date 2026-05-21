import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Services/notificationService.dart';
import 'package:graduation_project/Services/alertService.dart';
import 'package:graduation_project/main.dart';
import 'package:graduation_project/views/UserInfo.dart';
import 'package:graduation_project/widgets/skeletons.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    NotificationService.changes.addListener(_handleNotificationChange);
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final provider = ProductProvider.of(context, listen: false);
      provider.loadProducts();
    });
  }

  @override
  void dispose() {
    NotificationService.changes.removeListener(_handleNotificationChange);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _handleNotificationChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final provider = ProductProvider.of(context);
    final expiringSoonCount = provider.expiringSoonCount;
    final lowStockCount = provider.lowStockCount;
    final criticalAlertsCount = provider.getCriticalAlertsCount();
    final criticalAlerts = AlertService.getCriticalAlerts();
    final unreadNotifications = NotificationService.getUnread();
    final bellCount = AuthService.isSupervisor
        ? unreadNotifications.length
        : criticalAlertsCount;
    final recentMaterials = _recentMaterials(provider.products);
    final roleColor =
        AuthService.isWarehouseManager ? Colors.blue : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: provider.loading
          ? const DashboardSkeleton()
          : SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Topbar
                        Row(
                          children: [
                            const Spacer(),
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: _showNotifications,
                                  icon: const Icon(Icons.notifications_none),
                                ),
                                if (bellCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        bellCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _showProfilePopup,
                              child: CircleAvatar(
                                backgroundColor: roleColor.withOpacity(0.16),
                                child: Text(
                                  _profileInitial(),
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Title
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr.warehouseOverview,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => provider.loadProducts(),
                              icon: const Icon(Icons.refresh),
                              label: Text(tr.refresh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // KPI row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _kpiCard(
                                context,
                                tr.totalMaterials,
                                provider.totalProducts.toString(),
                                icon: Icons.grid_view,
                              ),
                              if (AuthService.isWarehouseManager) ...[
                                const SizedBox(width: 12),
                                _kpiCard(
                                  context,
                                  tr.nearingExpiry,
                                  expiringSoonCount.toString(),
                                  icon: Icons.hourglass_bottom,
                                  color: expiringSoonCount > 0
                                      ? Colors.orange
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                _kpiCard(
                                  context,
                                  tr.lowStockItemsTitle,
                                  lowStockCount.toString(),
                                  icon: Icons.warning_amber_rounded,
                                  color: lowStockCount > 0
                                      ? Colors.yellow[700]
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                _kpiCard(
                                  context,
                                  tr.criticalAlertsTitle,
                                  criticalAlertsCount.toString(),
                                  icon: Icons.notifications_active,
                                  color: criticalAlertsCount > 0
                                      ? Colors.red
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category breakdown chart
                        Container(
                          height: 240,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).cardColor,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildCategoryChart(context, provider.products),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _chartLegend(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recent Activity
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).cardColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.recentMaterials,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              ...recentMaterials.map(
                                (m) => Column(
                                  children: [
                                    _materialRow(
                                      m.name,
                                      '${m.quantity} ${tr.unit.toLowerCase()}',
                                      m.expiryDate,
                                      m.category,
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (AuthService.isWarehouseManager) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tr.criticalAlertsTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              if (criticalAlertsCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    criticalAlertsCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (criticalAlerts.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context).cardColor,
                              ),
                              child: Center(
                                child: Text(tr.noCriticalAlerts),
                              ),
                            )
                          else
                            ...criticalAlerts.take(5).map((alert) {
                              final isExpired = alert.alertType == 'expired';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _alertCard(
                                  context,
                                  alert.material?.name ?? 'Alert',
                                  alert.message,
                                  isExpired
                                      ? Icons.error_outline
                                      : Icons.warning_amber_rounded,
                                  isExpired
                                      ? Colors.redAccent
                                      : Colors.orangeAccent,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  List<MapEntry<String, int>> _categoryData(List<MaterialModel> all) {
    final cats = <String, int>{};
    for (final m in all) {
      final c = m.category.isEmpty ? 'Uncategorized' : m.category;
      cats[c] = (cats[c] ?? 0) + 1;
    }
    final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).toList();
  }

  static const _chartColors = [
    Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
    Color(0xFF9C27B0), Color(0xFFF44336), Color(0xFF00BCD4),
    Color(0xFFFFEB3B), Color(0xFF795548),
  ];

  Widget _buildCategoryChart(BuildContext context, List<MaterialModel> all) {
    final data = _categoryData(all);
    if (data.isEmpty) {
      return Center(child: Text(context.tr.noData,
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black38)));
    }
    return PieChart(PieChartData(
      sections: List.generate(data.length, (i) {
        final pct = data[i].value / all.length * 100;
        return PieChartSectionData(
          value: data[i].value.toDouble(),
          color: _chartColors[i % _chartColors.length],
          radius: 48,
          title: '${pct.toStringAsFixed(0)}%',
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }),
      centerSpaceRadius: 28,
      sectionsSpace: 2,
    ));
  }

  List<Widget> _chartLegend(BuildContext context) {
    final data = _categoryData(ProductProvider.of(context).products);
    return data.map((e) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(
                  color: _chartColors[data.indexOf(e) % _chartColors.length],
                  shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('${e.key} (${e.value})',
              style: TextStyle(fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)),
        ],
      ),
    )).toList();
  }

  Widget _kpiCard(
    BuildContext context,
    String title,
    String value, {
    required IconData icon,
    Color? color,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        border:
            color != null ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(
    BuildContext context,
    String title,
    String body,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<MaterialModel> _recentMaterials(List<MaterialModel> products) {
    final materials = products.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return materials.take(5).toList();
  }

  Widget _materialRow(
    String name,
    String quantity,
    String expiryDate,
    String category,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name)),
          Expanded(flex: 2, child: Text(quantity)),
          Expanded(flex: 2, child: Text(expiryDate)),
          Expanded(flex: 2, child: Text(category)),
        ],
      ),
    );
  }

  String _profileInitial() {
    final name = AuthService.currentUser?.fullName.trim() ?? '';
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  void _showNotifications() {
    final tr = context.tr;
    if (AuthService.isSupervisor) {
      final notifications = NotificationService.getAll();
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  '${tr.notifications} (${NotificationService.getUnread().length})',
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: notifications.isEmpty
                  ? Text(tr.noNotifications)
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          leading: Icon(
                            item.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            color: item.isRead ? Colors.grey : Colors.green,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.body}\n${item.createdAt.toLocal().toString().substring(0, 16)}',
                          ),
                          isThreeLine: true,
                          trailing: item.isRead
                              ? null
                              : TextButton(
                                  onPressed: () {
                                    NotificationService.markRead(item.id);
                                    setState(() {});
                                    setDialogState(() {});
                                  },
                                  child: Text(tr.markRead),
                                ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  NotificationService.markAllRead();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: Text(tr.markAllRead),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr.close),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final alerts = AlertService.getCriticalAlerts();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.red),
            const SizedBox(width: 12),
            Text('${tr.notifications} (${alerts.length})'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: alerts.isEmpty
              ? Text(tr.noActiveNotifications)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return ListTile(
                      leading: Icon(
                        alert.alertType == 'expired'
                            ? Icons.error
                            : Icons.warning_amber_rounded,
                        color: alert.alertType == 'expired'
                            ? Colors.red
                            : alert.alertType == 'expiring_soon'
                            ? Colors.orange
                            : Colors.blue,
                      ),
                      title: Text(alert.material?.name ?? 'Alert'),
                      subtitle: Text(alert.message),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.close),
          ),
        ],
      ),
    );
  }

  void _showProfilePopup() {
    final tr = context.tr;
    final user = AuthService.currentUser;
    final isManager = AuthService.isWarehouseManager;
    final roleColor = isManager ? Colors.blue : Colors.green;
    final roleText = isManager ? tr.warehouseManager : tr.supervisor;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.only(top: 72, right: 36),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: roleColor.withOpacity(0.12),
                  child: Text(
                    _profileInitial(),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? tr.unknownUser,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    roleText,
                    style: TextStyle(
                        color: roleColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserInfoPage(showBackButton: true),
                        ),
                      );
                    },
                    child: Text(tr.more),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}