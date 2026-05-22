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
  final _formKey = GlobalKey<FormState>();
  final _lowStockCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  bool _loading = true;
  int _origLow = 100;
  int _origExpiry = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _origLow = await ThresholdService.getLowStockThreshold();
    _origExpiry = await ThresholdService.getExpiringSoonDays();
    _lowStockCtrl.text = _origLow.toString();
    _expiryCtrl.text = _origExpiry.toString();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resetDefaults() async {
    await ThresholdService.setLowStockThreshold(100);
    await ThresholdService.setExpiringSoonDays(30);
    _lowStockCtrl.text = '100';
    _expiryCtrl.text = '30';
    await ProductProvider.of(context, listen: false).loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.settingsSaved)),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final low = int.parse(_lowStockCtrl.text);
    final expiry = int.parse(_expiryCtrl.text);
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCard(
                        context,
                        icon: Icons.inventory_2_outlined,
                        title: tr.lowStockThreshold,
                        subtitle: tr.lowStockThresholdDesc,
                        child: TextFormField(
                          controller: _lowStockCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return tr.required;
                            final n = int.tryParse(v);
                            if (n == null || n < 1) return tr.positiveNumber;
                            return null;
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                        child: TextFormField(
                          controller: _expiryCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return tr.required;
                            final n = int.tryParse(v);
                            if (n == null || n < 1 || n > 365) {
                              return tr.isArabic
                                  ? 'أدخل رقماً بين 1 و 365'
                                  : 'Enter a number between 1 and 365';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _save,
                              icon: const Icon(Icons.save),
                              label: Text(tr.save),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.lightBlueAccent : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _resetDefaults,
                            icon: const Icon(Icons.restore),
                            label: Text(tr.isArabic ? 'إعادة الضبط' : 'Reset'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
