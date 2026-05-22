import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Services/alertService.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Services/MaterialSerivce.dart';
import 'package:graduation_project/Services/notificationService.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/widgets/skeletons.dart';

const _pieColors = [
  Colors.blue, Colors.teal, Colors.orange, Colors.purple,
  Colors.red, Colors.green, Colors.indigo, Colors.amber,
];

class ReportsPage extends StatefulWidget {
  final VoidCallback? onGoToOrders;
  const ReportsPage({super.key, this.onGoToOrders});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Statuses';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Sorting
  int _sortCol = -1;
  bool _sortAsc = true;

  int _touchedPieIndex = -1;

  // Pagination
  int _pageSize = 25;
  int _pageIndex = 0;

  bool get isSupervisor => AuthService.isSupervisor;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() { if (mounted) setState(() {}); });
    NotificationService.changes.addListener(_handleNotificationChange);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    NotificationService.changes.removeListener(_handleNotificationChange);
    super.dispose();
  }

  void _handleNotificationChange() {
    if (mounted) setState(() {});
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _trStatus(String status) {
    switch (status) {
      case 'Good': return context.tr.statusGood;
      case 'Expiring Soon': return context.tr.statusExpiringSoon;
      case 'Expired': return context.tr.statusExpired;
      case 'Low Stock': return context.tr.statusLowStock;
      default: return status;
    }
  }

  List<MaterialModel> _filteredList(ProductProvider provider) {
    final all = provider.products;
    final cats = all.map((m) => m.category).toSet().toList()..sort();
    final catItems = [context.tr.allCategories, ...cats];
    final effectiveCat = catItems.contains(_selectedCategory)
        ? _selectedCategory
        : context.tr.allCategories;
    final effectiveStatus =
        ['All Statuses', context.tr.statusGood, context.tr.statusExpiringSoon,
         context.tr.statusExpired, context.tr.statusLowStock]
            .contains(_selectedStatus)
        ? _selectedStatus
        : 'All Statuses';

    return all.where((m) {
      final matchSearch = m.name.toLowerCase()
          .contains(_searchCtrl.text.toLowerCase());
      final matchCat = effectiveCat == context.tr.allCategories
          || m.category == effectiveCat;
      final status = MaterialService.getMaterialStatus(m);
      final matchStatus = effectiveStatus == 'All Statuses'
          || status == effectiveStatus
          || _trStatus(status) == effectiveStatus;
      bool matchDate = true;
      if (_dateFrom != null && _dateTo != null && m.expiryDate.isNotEmpty) {
        try {
          final expiry = DateTime.parse(m.expiryDate).toLocal();
          matchDate = !expiry.isBefore(_dateFrom!)
              && !expiry.isAfter(_dateTo!);
        } catch (_) {}
      }
      return matchSearch && matchCat && matchStatus && matchDate;
    }).toList();
  }

  void _sort<T>(int col, Comparable<T> Function(MaterialModel) getter) {
    setState(() {
      if (_sortCol == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortCol = col;
        _sortAsc = true;
      }
    });
  }

  // ─── Chart data ──────────────────────────────────────────────────────────────

  List<PieChartSectionData> _categoryPieData(List<MaterialModel> list) {
    if (list.isEmpty) return [];
    final Map<String, int> counts = {};
    for (final m in list) {
      final cat = m.category.isEmpty ? 'Uncategorized' : m.category;
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    final colors = _pieColors;
    return counts.entries.toList().asMap().entries.map((e) {
      final i = e.key;
      final entry = e.value;
      final pct = (entry.value / list.length * 100).toStringAsFixed(0);
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: entry.value.toDouble(),
        title: '$pct%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<BarChartGroupData> _statusBarData(List<MaterialModel> list) {
    int good = 0, expiring = 0, expired = 0, low = 0;
    for (final m in list) {
      switch (MaterialService.getMaterialStatus(m)) {
        case 'Good': good++; break;
        case 'Expiring Soon': expiring++; break;
        case 'Expired': expired++; break;
        case 'Low Stock': low++; break;
      }
    }
    return [
      BarChartGroupData(x: 0, barRods: [_barRod(good, Colors.green)]),
      BarChartGroupData(x: 1, barRods: [_barRod(expiring, Colors.orange)]),
      BarChartGroupData(x: 2, barRods: [_barRod(expired, Colors.red)]),
      BarChartGroupData(x: 3, barRods: [_barRod(low, Colors.amber)]),
    ];
  }

  BarChartRodData _barRod(int y, Color color) => BarChartRodData(
    toY: y.toDouble(), color: color, width: 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );

  List<BarChartGroupData> _expiryTimelineData(List<MaterialModel> list) {
    final now = DateTime.now();
    final Map<int, int> months = {};
    for (int i = 0; i < 12; i++) months[i] = 0;
    for (final m in list) {
      final exp = m.expiryDateValue;
      if (exp == null) continue;
      final diff = exp.difference(now).inDays;
      if (diff < -30) continue;
      final idx = (diff / 30).floor().clamp(0, 11);
      months[idx] = (months[idx] ?? 0) + 1;
    }
    return months.entries.map((e) => BarChartGroupData(
      x: e.key, barRods: [_barRod(e.value, _pieColors[e.key % _pieColors.length])],
    )).toList();
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = ProductProvider.of(context);
    final all = provider.products;
    final filtered = _filteredList(provider);

    // Sort
    if (_sortCol >= 0) {
      filtered.sort((a, b) {
        int cmp;
        switch (_sortCol) {
          case 0: cmp = a.name.compareTo(b.name); break;
          case 1: cmp = a.category.compareTo(b.category); break;
          case 2: cmp = a.quantity.compareTo(b.quantity); break;
          case 3: cmp = a.expiryDate.compareTo(b.expiryDate); break;
          case 4: cmp = MaterialService.getMaterialStatus(a)
              .compareTo(MaterialService.getMaterialStatus(b)); break;
          default: cmp = 0;
        }
        return _sortAsc ? cmp : -cmp;
      });
    }

    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 999);
    _pageIndex = _pageIndex.clamp(0, totalPages - 1);
    final pageStart = _pageIndex * _pageSize;
    final paged = filtered.skip(pageStart).take(_pageSize).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      color: isDark ? const Color(0xFF0E1621) : const Color(0xFFF5F5F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.reportsAndAnalytics,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (isSupervisor) _notificationBell(),
                ElevatedButton.icon(
                  onPressed: () => _printReport(provider),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(context.tr.exportReport),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _exportToExcel(provider),
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: Text(context.tr.export),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF198754),
                    foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.loading)
            const Expanded(child: ReportsSkeleton())
          else
            Expanded(
              child: Column(
                children: [
                  _buildTabBar(isDark),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _overviewTab(isDark, provider, all),
                        _inventoryTab(isDark, provider, filtered, paged, totalPages),
                        _expiryTab(isDark, provider, all),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: const Color(0xFF0D6EFD),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: context.tr.overview, icon: const Icon(Icons.dashboard, size: 18)),
          Tab(text: context.tr.inventoryTitle, icon: const Icon(Icons.inventory_2, size: 18)),
          Tab(text: context.tr.expiryAnalysis, icon: const Icon(Icons.date_range, size: 18)),
        ],
      ),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────────────────

  Widget _overviewTab(bool isDark, ProductProvider provider, List<MaterialModel> all) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow(isDark, provider),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _chartCard(isDark, context.tr.categoryBreakdown,
                  _buildPieChart(isDark, all))),
              const SizedBox(width: 16),
              Expanded(child: _chartCard(isDark, context.tr.statusDistribution,
                  _buildStatusChart(isDark, all))),
            ],
          ),
          const SizedBox(height: 20),
          _analyticsSection(isDark, provider, all),
        ],
      ),
    );
  }

  Widget _buildKpiRow(bool isDark, ProductProvider provider) {
    return Row(
      children: [
        _kpiCard(isDark, Icons.inventory_2, context.tr.totalMaterials,
            provider.totalProducts.toString(), const Color(0xFF0D6EFD), null),
        const SizedBox(width: 14),
        _kpiCard(isDark, Icons.warning_amber_rounded, context.tr.statusExpiringSoon,
            provider.expiringSoonCount.toString(), const Color(0xFFFFA500), null),
        const SizedBox(width: 14),
        _kpiCard(isDark, Icons.inbox, context.tr.statusLowStock,
            provider.lowStockCount.toString(), const Color(0xFFDC3545), null),
        const SizedBox(width: 14),
        _kpiCard(isDark, Icons.error_outline, context.tr.criticalAlertsTitle,
            provider.getCriticalAlertsCount().toString(), const Color(0xFFDC3545),
            provider.getCriticalAlertsCount() > 0),
      ],
    );
  }

  Widget _kpiCard(bool isDark, IconData icon, String title, String value,
      Color accent, bool? highlight) {
    final useHighlight = highlight ?? false;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: useHighlight ? LinearGradient(
            colors: [accent.withOpacity(0.15), accent.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ) : null,
          color: useHighlight ? null : (isDark ? const Color(0xFF1A2332) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(bool isDark, String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildPieChart(bool isDark, List<MaterialModel> all) {
    if (all.isEmpty) return Center(child: Text(context.tr.noData,
        style: TextStyle(color: isDark ? Colors.white60 : Colors.black38)));
    final Map<String, int> counts = {};
    for (final m in all) {
      final cat = m.category.isEmpty ? 'Uncategorized' : m.category;
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    final entries = counts.entries.toList();
    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(PieChartData(
          sections: List.generate(entries.length, (i) {
            final entry = entries[i];
            final pct = entry.value / all.length * 100;
            final isTouched = i == _touchedPieIndex;
            return PieChartSectionData(
              value: entry.value.toDouble(),
              color: _pieColors[i % _pieColors.length],
              radius: isTouched ? 58 : 48,
              title: '${pct.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              badgeWidget: isTouched ? Text(entry.key,
                  style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : Colors.black54)) : null,
              badgePositionPercentageOffset: 1.3,
            );
          }),
          centerSpaceRadius: 36,
          sectionsSpace: 2,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions || response == null ||
                  response.touchedSection == null) {
                if (_touchedPieIndex != -1) setState(() => _touchedPieIndex = -1);
                return;
              }
              final idx = response.touchedSection!.touchedSectionIndex;
              if (idx != _touchedPieIndex) setState(() => _touchedPieIndex = idx);
            },
          ),
        )),
        Text('${all.length}', style: TextStyle(fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }

  Widget _buildStatusChart(bool isDark, List<MaterialModel> all) {
    final data = _statusBarData(all);
    final maxY = data.fold(0.0, (p, g) => p > g.barRods.first.toY ? p : g.barRods.first.toY);
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY == 0 ? 10 : maxY * 1.2,
      barGroups: data,
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, getTitlesWidget: (v, meta) {
            final labels = [
              context.tr.statusGood,
              context.tr.statusExpiringSoon,
              context.tr.statusExpired,
              context.tr.statusLowStock,
            ];
            return SideTitleWidget(
              meta: meta,
              child: Text(labels[v.toInt()],
                  style: TextStyle(fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54)),
            );
          },
        )),
      ),
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _analyticsSection(bool isDark, ProductProvider provider, List<MaterialModel> all) {
    final totalUnits = all.fold<int>(0, (s, m) => s + m.quantity);
    final cats = <String, int>{};
    for (final m in all) {
      final c = m.category.isEmpty ? 'Uncategorized' : m.category;
      cats[c] = (cats[c] ?? 0) + 1;
    }
    final sortedCats = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr.analytics, style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statTile(isDark, context.tr.totalStock, '$totalUnits ${context.tr.unit}'),
              const SizedBox(width: 24),
              _statTile(isDark, context.tr.totalMaterials, '${all.length}'),
              const SizedBox(width: 24),
              _statTile(isDark, context.tr.categoryBreakdown, '${cats.length} ${context.tr.categoriesLabel}'),
            ],
          ),
          const SizedBox(height: 16),
          Text(context.tr.stockByCategory, style: TextStyle(fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 8),
          ...sortedCats.take(10).map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 120, child: Text(e.key,
                    style: TextStyle(fontSize: 12,
                        color: isDark ? Colors.white : Colors.black))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: all.isEmpty ? 0 : e.value / all.length,
                      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      color: Colors.blue,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 50, child: Text(
                  '${(e.value / (all.isEmpty ? 1 : all.length) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _statTile(bool isDark, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black)),
      ],
    );
  }

  // ── Inventory Tab ────────────────────────────────────────────────────────────

  Widget _inventoryTab(bool isDark, ProductProvider provider,
      List<MaterialModel> filtered, List<MaterialModel> paged, int totalPages) {
    return Column(
      children: [
        _filterRow(isDark, provider),
        const SizedBox(height: 12),
        Expanded(child: _dataTable(isDark, provider, paged, filtered.length)),
        if (totalPages > 1) _pagination(isDark, totalPages, filtered.length),
      ],
    );
  }

  Widget _filterRow(bool isDark, ProductProvider provider) {
    final all = provider.products;
    final cats = all.map((m) => m.category).toSet().toList()..sort();
    final catItems = [context.tr.allCategories, ...cats];
    final effectiveCat = catItems.contains(_selectedCategory)
        ? _selectedCategory : context.tr.allCategories;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2332) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) { setState(() { _pageIndex = 0; }); },
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
              decoration: InputDecoration(
                hintText: context.tr.searchByNameOrSku,
                hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _dropdown(isDark, effectiveCat, catItems, (v) {
          setState(() { _selectedCategory = v!; _pageIndex = 0; });
        }),
        const SizedBox(width: 10),
        _dropdown(isDark, _selectedStatus, [
          'All Statuses', context.tr.statusGood, context.tr.statusExpiringSoon,
          context.tr.statusExpired, context.tr.statusLowStock,
        ], (v) { setState(() { _selectedStatus = v!; _pageIndex = 0; }); }),
        const SizedBox(width: 10),
        _dateFilter(isDark),
      ],
    );
  }

  Widget _dropdown(bool isDark, String value, List<String> items,
      void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          dropdownColor: isDark ? const Color(0xFF1A2332) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.white70 : Colors.black54, size: 20),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateFilter(bool isDark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _dateBtn(isDark, _dateFrom, context.tr.filterByDate, () async {
        final p = await showDatePicker(context: context,
            initialDate: _dateFrom ?? DateTime.now(),
            firstDate: DateTime(2020), lastDate: DateTime(2035));
        if (p != null) setState(() => _dateFrom = p);
      }),
      const SizedBox(width: 4),
      _dateBtn(isDark, _dateTo, context.tr.filterByDate, () async {
        final p = await showDatePicker(context: context,
            initialDate: _dateTo ?? DateTime.now(),
            firstDate: DateTime(2020), lastDate: DateTime(2035));
        if (p != null) setState(() => _dateTo = p);
      }),
      if (_dateFrom != null || _dateTo != null)
        IconButton(
          icon: Icon(Icons.clear, size: 18,
              color: isDark ? Colors.white38 : Colors.black38),
          onPressed: () => setState(() { _dateFrom = null; _dateTo = null; }),
          visualDensity: VisualDensity.compact,
        ),
    ]);
  }

  Widget _dateBtn(bool isDark, DateTime? date, String hint, VoidCallback onTap) {
    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.white38 : Colors.black38;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today, size: 14, color: hintColor),
          const SizedBox(width: 4),
          Text(
            date == null ? hint : '${date.day}/${date.month}/${date.year}',
            style: TextStyle(fontSize: 12, color: date == null ? hintColor : textColor),
          ),
        ]),
      ),
    );
  }

  Widget _dataTable(bool isDark, ProductProvider provider,
      List<MaterialModel> paged, int totalCount) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text(
              '${context.tr.inventoryTitle}  ($totalCount)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _tableHeader(isDark),
                if (paged.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(child: Text(context.tr.noProductsFiltered,
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54))),
                  )
                else
                  ...paged.asMap().entries.map((e) =>
                    _tableRow(isDark, e.value, e.key % 2 == 0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(bool isDark) {
    final cols = [
      (context.tr.materialName, 0),
      (context.tr.category, 1),
      (context.tr.quantity, 2),
      (context.tr.expiryDate, 3),
      (context.tr.status, 4),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF233044) : const Color(0xFFF8F9FA),
        border: Border(bottom: BorderSide(
            color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200)),
      ),
      child: Row(
        children: cols.map((c) {
          final (label, idx) = c;
          final active = _sortCol == idx;
          return Expanded(
            flex: idx == 0 ? 3 : (idx == 2 ? 1 : 2),
            child: InkWell(
              onTap: () {
                switch (idx) {
                  case 0: _sort<String>(0, (m) => m.name); break;
                  case 1: _sort<String>(1, (m) => m.category); break;
                  case 2: _sort<num>(2, (m) => m.quantity); break;
                  case 3: _sort<String>(3, (m) => m.expiryDate); break;
                  case 4: _sort<String>(4, (m) => MaterialService.getMaterialStatus(m)); break;
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? const Color(0xFF0D6EFD)
                          : (isDark ? Colors.white70 : Colors.black87))),
                  if (active)
                    Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14, color: const Color(0xFF0D6EFD)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tableRow(bool isDark, MaterialModel m, bool even) {
    final status = MaterialService.getMaterialStatus(m);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: even
          ? (isDark ? const Color(0xFF151E2C) : const Color(0xFFFAFBFC))
          : null,
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(m.name,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black))),
          Expanded(flex: 2, child: Text(m.category,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54))),
          Expanded(flex: 1, child: Text(m.quantity.toString(),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black))),
          Expanded(flex: 2, child: Text(m.expiryDate,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54))),
          Expanded(flex: 2, child: _statusBadge(status, isDark)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, bool isDark) {
    Color bg, text;
    String display;
    switch (status) {
      case 'Good':
        display = context.tr.statusGood;
        bg = const Color(0xFF28A745).withOpacity(0.15);
        text = const Color(0xFF28A745);
        break;
      case 'Expiring Soon':
        display = context.tr.statusExpiringSoon;
        bg = const Color(0xFFFFA500).withOpacity(0.15);
        text = const Color(0xFFFFA500);
        break;
      case 'Expired':
        display = context.tr.statusExpired;
        bg = const Color(0xFFDC3545).withOpacity(0.15);
        text = const Color(0xFFDC3545);
        break;
      case 'Low Stock':
        display = context.tr.statusLowStock;
        bg = Colors.orange.withOpacity(0.15);
        text = Colors.orange;
        break;
      default:
        display = status;
        bg = Colors.grey.withOpacity(0.15);
        text = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(display, style: TextStyle(color: text,
          fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }

  Widget _pagination(bool isDark, int totalPages, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 20),
            onPressed: _pageIndex == 0 ? null : () => setState(() => _pageIndex = 0),
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: _pageIndex == 0 ? null : () => setState(() => _pageIndex--),
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          Text('${_pageIndex + 1} / $totalPages',
              style: TextStyle(fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54)),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: _pageIndex >= totalPages - 1 ? null
                : () => setState(() => _pageIndex++),
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, size: 20),
            onPressed: _pageIndex >= totalPages - 1 ? null
                : () => setState(() => _pageIndex = totalPages - 1),
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          const SizedBox(width: 12),
          Text('$totalCount ${context.tr.itemsLabel}',
              style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }

  // ── Expiry Analysis Tab ──────────────────────────────────────────────────────

  Widget _expiryTab(bool isDark, ProductProvider provider, List<MaterialModel> all) {
    final now = DateTime.now();
    final expiringSoon = all.where((m) {
      final exp = m.expiryDateValue;
      if (exp == null) return false;
      final days = exp.difference(now).inDays;
      return days >= 0 && days <= 90;
    }).toList()..sort((a, b) => (a.expiryDateValue ?? now)
        .compareTo(b.expiryDateValue ?? now));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartCard(isDark, context.tr.expiryTimeline,
              _buildExpiryChart(isDark, all)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2332) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr.expiringSoonItems,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black)),
                    Text('${expiringSoon.length} ${context.tr.itemsLabel}',
                        style: TextStyle(fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                if (expiringSoon.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text(context.tr.noData,
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54))),
                  )
                else
                  ...expiringSoon.take(20).map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(m.name,
                              style: TextStyle(fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black)),
                        ),
                        Text(m.expiryDate,
                            style: TextStyle(fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54)),
                        const SizedBox(width: 12),
                        _statusBadge(MaterialService.getMaterialStatus(m), isDark),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryChart(bool isDark, List<MaterialModel> all) {
    final data = _expiryTimelineData(all);
    final maxY = data.fold(0.0, (p, g) => p > g.barRods.first.toY
        ? p : g.barRods.first.toY);
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY == 0 ? 10 : maxY * 1.2,
      barGroups: data,
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        horizontalInterval: maxY == 0 ? 2 : (maxY * 1.2 / 4).clamp(1, 999),
        getDrawingHorizontalLine: (_) => FlLine(
          color: isDark ? Colors.white10 : Colors.grey.shade200, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (v, _) => Text('${v.toInt()}',
                style: TextStyle(fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.black54)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, meta) {
            final labels = ['Now','1m','2m','3m','4m','5m','6m','7m','8m','9m','10m','11m'];
            return SideTitleWidget(
              meta: meta,
              child: Text(labels[v.toInt()],
                  style: TextStyle(fontSize: 9,
                      color: isDark ? Colors.white60 : Colors.black54)),
            );
          },
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: true),
    ));
  }

  // ─── Notification Bell ────────────────────────────────────────────────────────

  Widget _notificationBell() {
    final unreadCount = NotificationService.getUnread().length;
    return Stack(clipBehavior: Clip.none, children: [
      IconButton(
        tooltip: context.tr.editRequests,
        onPressed: _showOrderNotifications,
        icon: const Icon(Icons.notifications_none),
      ),
      if (unreadCount > 0)
        Positioned(
          right: 4, top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(10),
            ),
            child: Text(unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ),
    ]);
  }

  void _showOrderNotifications() {
    final t = context.tr;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final notifications = NotificationService.getAll();
          return AlertDialog(
            title: Text('${t.editRequests} '
                '(${NotificationService.getUnread().length})'),
            content: SizedBox(
              width: 520,
              child: notifications.isEmpty
                  ? Text(t.noEditRequests)
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          leading: Icon(
                            item.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            color: item.isRead ? Colors.grey : Colors.green,
                          ),
                          title: Text(item.materialName ?? item.title),
                          subtitle: Text(
                            '${t.sku}: ${item.productSku ?? '-'}\n'
                            'Proposed expiry: ${_formatRawDate(item.proposedExpiry ?? '')}\n'
                            '${t.manager}: ${item.managerName ?? '-'}',
                          ),
                          isThreeLine: true,
                          trailing: TextButton(
                            onPressed: () {
                              NotificationService.markRead(item.id);
                              setState(() {});
                              setDialogState(() {});
                              Navigator.pop(ctx);
                              widget.onGoToOrders?.call();
                            },
                            child: Text(t.goToOrders),
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
                child: Text(t.markAllRead),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.close),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatRawDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '-' : raw;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }

  // ─── PDF Export ───────────────────────────────────────────────────────────────

  Future<void> _printReport(ProductProvider provider) async {
    try {
      final t = context.tr;
      final pdf = pw.Document();
      final materials = provider.products;

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final headers = [
            t.materialName, t.category, t.quantity, t.expiryDate, t.status,
          ];
          final statusMap = <String, String>{
            'Good': t.statusGood,
            'Expiring Soon': t.statusExpiringSoon,
            'Expired': t.statusExpired,
            'Low Stock': t.statusLowStock,
          };
          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(t.reportsTitle,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('${t.generatedPrefix}${DateTime.now().toString().substring(0, 16)}',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              _pdfKpi(t.totalMaterials, materials.length.toString()),
              _pdfKpi(t.statusExpiringSoon, provider.expiringSoonCount.toString()),
              _pdfKpi(t.statusLowStock, provider.lowStockCount.toString()),
              _pdfKpi(t.criticalAlertsTitle,
                  provider.getCriticalAlertsCount().toString()),
            ]),
            pw.SizedBox(height: 30),
            pw.Text(t.inventoryTitle,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: headers,
              data: materials.map((m) {
                final rawStatus = MaterialService.getMaterialStatus(m);
                return [m.name, m.category, m.quantity.toString(),
                    m.expiryDate, statusMap[rawStatus] ?? rawStatus];
              }).toList(),
              headerStyle: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ]);
        },
      ));

      if (mounted) _showPrintOptionsDialog(pdf);
    } catch (e) {
      if (mounted) _showErrorDialog('${context.tr.errorGeneratingPdf}: $e');
    }
  }

  pw.Widget _pdfKpi(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 5),
        pw.Text(value, style: pw.TextStyle(
            fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  void _showPrintOptionsDialog(pw.Document pdf) {
    final t = context.tr;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.exportReport),
        content: Text(t.chooseExportMethod),
        actions: [
          TextButton.icon(
            onPressed: () async { Navigator.pop(context); await _printPdf(pdf); },
            icon: const Icon(Icons.print), label: Text(t.print),
          ),
          TextButton.icon(
            onPressed: () async { Navigator.pop(context); await _sharePdf(pdf); },
            icon: const Icon(Icons.share), label: Text(t.saveOrShare),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        ],
      ),
    );
  }

  Future<void> _printPdf(pw.Document pdf) async {
    try { await Printing.layoutPdf(onLayout: (PdfPageFormat fmt) async => pdf.save()); }
    catch (e) { if (mounted) _showErrorDialog('${context.tr.error}: $e'); }
  }

  Future<void> _sharePdf(pw.Document pdf) async {
    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) { if (mounted) _showErrorDialog('${context.tr.error}: $e'); }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr.error),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: Text(context.tr.close))],
      ),
    );
  }

  // ─── Excel Export ───────────────────────────────────────────────────────────

  Future<void> _exportToExcel(ProductProvider provider) async {
    try {
      final all = provider.products;
      final filtered = _filteredList(provider);
      final excel = Excel.createExcel();
      final sheet = excel['Reports'];

      final headerStyle = CellStyle(
        bold: true, backgroundColorHex: ExcelColor.fromInt(0xFF0D6EFD),
        fontColorHex: ExcelColor.fromInt(0xFFFFFFFF),
      );

      final headers = ['Name', 'SKU', 'Category', 'Quantity', 'Unit',
          'Expiry Date', 'Status', 'Storage Location'];
      final headerRow = headers.map((h) => TextCellValue(h) as CellValue).toList();
      sheet.appendRow(headerRow);
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      final statusColors = <String, String>{
        'Good': '28A745', 'Expiring Soon': 'FFA500',
        'Expired': 'DC3545', 'Low Stock': 'FF8C00',
      };

      for (final m in filtered) {
        final status = MaterialService.getMaterialStatus(m);
        final colorHex = statusColors[status] ?? '000000';
        final rowIdx = sheet.maxRows;
        sheet.appendRow([
          TextCellValue(m.name),
          TextCellValue(m.sku),
          TextCellValue(m.category),
          TextCellValue(m.quantity.toString()),
          TextCellValue(m.unit.isEmpty ? '-' : m.unit),
          TextCellValue(_formatDate(m.expiryDate)),
          TextCellValue(status),
          TextCellValue(m.location.isEmpty ? '-' : m.location),
        ]);
        final fg = ExcelColor.fromInt(int.parse(colorHex, radix: 16) | 0xFF000000);
        final bg = ExcelColor.fromInt((int.parse(colorHex, radix: 16) & 0xFFFFFF) | 0x20000000);
        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: 6, rowIndex: rowIdx)).cellStyle = CellStyle(
          fontColorHex: fg, backgroundColorHex: bg,
        );
      }

      _autoWidth(sheet, headers.length, filtered);

      // Summary row
      final totalQty = filtered.fold<int>(0, (s, m) => s + m.quantity);
      sheet.appendRow([
        TextCellValue(''), TextCellValue(''),
        TextCellValue(''), TextCellValue(''),
        TextCellValue(''), TextCellValue(''),
        TextCellValue('TOTAL'),
        TextCellValue(totalQty.toString()),
      ]);
      final sumRowIdx = sheet.maxRows - 1;
      for (int i = 0; i < 8; i++) {
        sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: i, rowIndex: sumRowIdx)).cellStyle = CellStyle(
          bold: true, backgroundColorHex: ExcelColor.fromInt(0xFFF0F0F0),
        );
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/pharmacy_report_'
          '${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel');
      await File(path).writeAsBytes(bytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr.exportReport}: $path'),
            duration: const Duration(seconds: 6)),
      );
      await Clipboard.setData(ClipboardData(text: path));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr.exportReport}: $path'),
              duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr.errorGeneratingPdf}: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _autoWidth(Sheet sheet, int cols, List<MaterialModel> data) {
    for (int c = 0; c < cols; c++) {
      int maxW = 10;
      for (int r = 0; r <= data.length; r++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: c, rowIndex: r));
        final v = cell.value?.toString() ?? '';
        if (v.length > maxW) maxW = v.length;
      }
      sheet.setColumnWidth(c, (maxW + 3).toDouble());
    }
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}'
          '-${date.day.toString().padLeft(2, '0')}';
    } catch (_) { return raw.isEmpty ? '-' : raw; }
  }
}
