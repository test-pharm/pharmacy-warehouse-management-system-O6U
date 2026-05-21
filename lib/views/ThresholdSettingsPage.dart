import 'package:flutter/material.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Services/thresholdService.dart';

class ThresholdSettingsPage extends StatefulWidget {
  const ThresholdSettingsPage({super.key});

  @override
  State<ThresholdSettingsPage> createState() => _ThresholdSettingsPageState();
}

class _ThresholdSettingsPageState extends State<ThresholdSettingsPage> {
  final _lowStockCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final low = await ThresholdService.getLowStockThreshold();
    final expiry = await ThresholdService.getExpiringSoonDays();
    _lowStockCtrl.text = low.toString();
    _expiryCtrl.text = expiry.toString();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final low = int.tryParse(_lowStockCtrl.text) ?? 100;
    final expiry = int.tryParse(_expiryCtrl.text) ?? 30;
    await ThresholdService.setLowStockThreshold(low);
    await ThresholdService.setExpiringSoonDays(expiry);
    await ProductProvider.of(context, listen: false).loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.settingsSaved)),
      );
    }
  }

  @override
  void dispose() {
    _lowStockCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.thresholdSettings,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard(
                      context,
                      icon: Icons.inventory_2_outlined,
                      title: tr.lowStockThreshold,
                      subtitle: tr.lowStockThresholdDesc,
                      child: TextField(
                        controller: _lowStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      context,
                      icon: Icons.date_range,
                      title: tr.expiringSoonThreshold,
                      subtitle: tr.expiringSoonThresholdDesc,
                      child: TextField(
                        controller: _expiryCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save),
                        label: Text(tr.save),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.lightBlueAccent : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
