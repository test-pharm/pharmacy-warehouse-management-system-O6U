import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StocktakePage extends StatelessWidget {
  const StocktakePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = ProductProvider.of(context);
    final products = provider.products.toList();
    final grouped = _groupByLocation(products);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stocktake',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Generate a stocktake sheet to physically count warehouse inventory.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white60
                  : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildContent(context, products, grouped),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<MaterialModel> products,
    Map<String, List<MaterialModel>> grouped,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2F35) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory, color: Colors.blue, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${products.length} total items',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${grouped.length} storage locations',
                        style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _generateStocktakePdf(context, products),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate Stocktake Sheet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A6B6E),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: grouped.entries.map((entry) {
              return _locationGroup(context, entry.key, entry.value, isDark);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _locationGroup(
    BuildContext context,
    String location,
    List<MaterialModel> items,
    bool isDark,
  ) {
    final label = location.isEmpty ? 'Unspecified' : location;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? const Color(0xFF1A2F35) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white10 : Colors.black)
                  .withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18, color: isDark ? Colors.white54 : Colors.black54),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} items',
                  style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          ...items.map((item) => ListTile(
                dense: true,
                title: Text(item.name,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text('SKU: ${item.sku}',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.black54)),
                trailing: Text('Qty: ${item.quantity}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87)),
              )),
        ],
      ),
    );
  }

  Future<void> _generateStocktakePdf(
    BuildContext context,
    List<MaterialModel> products,
  ) async {
    try {
      final pdf = pw.Document();
      final grouped = _groupByLocation(products);
      final sortedLocations = grouped.keys.toList()..sort();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context ctx) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Stocktake Sheet',
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'Generated: ${DateTime.now().toString().substring(0, 16)}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Instructions: Walk through each location, count the actual quantity, '
                'and write it in the "Actual Count" column. Note any discrepancies.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 16),
              ...sortedLocations.map((location) {
                final items = grouped[location]!;
                final label = location.isEmpty ? 'Unspecified' : location;
                return [
                  pw.Header(
                    level: 1,
                    child: pw.Text('Location: $label  (${items.length} items)',
                        style: const pw.TextStyle(fontSize: 14)),
                  ),
                  pw.Table.fromTextArray(
                    headerStyle: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 8),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.grey300),
                    border: pw.TableBorder.all(
                        color: PdfColors.grey400, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(30),
                      1: const pw.FixedColumnWidth(80),
                      2: const pw.FixedColumnWidth(140),
                      3: const pw.FixedColumnWidth(50),
                      4: const pw.FixedColumnWidth(40),
                      5: const pw.FixedColumnWidth(70),
                      6: const pw.FixedColumnWidth(100),
                      7: const pw.FixedColumnWidth(80),
                    },
                    headers: [
                      '#',
                      'SKU',
                      'Product Name',
                      'Qty',
                      'Unit',
                      'Expiry',
                      'Location',
                      'Actual Count',
                    ],
                    data: List.generate(items.length, (i) {
                      final m = items[i];
                      return [
                        (i + 1).toString(),
                        m.sku,
                        m.name,
                        m.quantity.toString(),
                        m.unit.isEmpty ? '-' : m.unit,
                        _formatExpiry(m.expiryDate),
                        m.location.isEmpty ? '-' : m.location,
                        '', // blank for manual count
                      ];
                    }),
                  ),
                  pw.SizedBox(height: 20),
                ];
              }),
            ];
          },
        ),
      );

      if (!context.mounted) return;
      _showPrintOptions(context, pdf);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  void _showPrintOptions(BuildContext context, pw.Document pdf) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stocktake Sheet'),
        content: const Text('Choose how to export:'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Printing.layoutPdf(
                  onLayout: (fmt) async => pdf.save());
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Printing.sharePdf(
                bytes: pdf.save(),
                filename:
                    'stocktake_${DateTime.now().millisecondsSinceEpoch}.pdf',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Save / Share'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Map<String, List<MaterialModel>> _groupByLocation(
      List<MaterialModel> products) {
    final map = <String, List<MaterialModel>>{};
    for (final p in products) {
      final loc = p.location.isEmpty ? 'Unspecified' : p.location;
      map.putIfAbsent(loc, () => []);
      map[loc]!.add(p);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    return map;
  }

  String _formatExpiry(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.isEmpty ? '-' : raw;
    }
  }
}
