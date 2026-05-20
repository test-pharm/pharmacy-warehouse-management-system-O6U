import 'package:flutter/material.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Models/app_localizations.dart';

class AddMaterialDialog extends StatefulWidget {
  final MaterialModel? initialProduct;
  final ProductProvider provider;

  const AddMaterialDialog({super.key, this.initialProduct, required this.provider});

  bool get isEditing => initialProduct != null;

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _logNumberController = TextEditingController();
  final _storageLocationController = TextEditingController();
  final _categoryIdController = TextEditingController();
  final _existingSearchController = TextEditingController();

  DateTime? _expiryDate;
  bool _isAvailable = true;
  bool _submitted = false;
  int _mode = 0;
  String _existingQuery = '';
  MaterialModel? _selectedExistingProduct;
  String? _existingError;
  bool _popIntercepted = false;

  bool get _hasUnsavedChanges {
    final product = widget.initialProduct;
    if (product != null) {
      return _nameController.text != product.name ||
          _quantityController.text != product.quantity.toString() ||
          _expiryDate != product.expiryDateValue ||
          _isAvailable != product.isAvailable;
    }
    if (_mode == 1) return _selectedExistingProduct != null && int.tryParse(_quantityController.text.trim()) != null;
    return _nameController.text.trim().isNotEmpty ||
        _skuController.text.trim().isNotEmpty ||
        _quantityController.text.trim().isNotEmpty ||
        _unitController.text.trim().isNotEmpty ||
        _logNumberController.text.trim().isNotEmpty ||
        _storageLocationController.text.trim().isNotEmpty ||
        _categoryIdController.text.trim().isNotEmpty ||
        _expiryDate != null;
  }

  Future<bool> _maybeDiscard() async {
    if (!_hasUnsavedChanges || _popIntercepted) return true;
    _popIntercepted = true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    if (product != null) {
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _quantityController.text = product.quantity.toString();
      _unitController.text = product.unit;
      _logNumberController.text = product.lot;
      _storageLocationController.text = product.location;
      _categoryIdController.text = product.categoryId.toString();
      _expiryDate = product.expiryDateValue;
      _isAvailable = product.isAvailable;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _logNumberController.dispose();
    _storageLocationController.dispose();
    _categoryIdController.dispose();
    _existingSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _submit() {
    setState(() {
      _submitted = true;
      _existingError = null;
    });

    if (_mode == 1) {
      _submitExisting();
      return;
    }

    if (!_formKey.currentState!.validate() || _expiryDate == null) {
      return;
    }

    Navigator.pop(context, {
      'materialName': _nameController.text.trim(),
      'material_SKU': _skuController.text.trim(),
      'quantity': int.parse(_quantityController.text.trim()),
      'unit': _unitController.text.trim(),
      'logNumber': _logNumberController.text.trim(),
      'expiryDate': _expiryDate!.toUtc().toIso8601String(),
      'storageLocation': _storageLocationController.text.trim(),
      'isAvailable': _isAvailable,
      'categoryId': int.parse(_categoryIdController.text.trim()),
    });
  }

  void _submitExisting() {
    final selectedProduct = _selectedExistingProduct;
    if (selectedProduct == null) {
      setState(() => _existingError = 'Select a material from the list');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = widget.provider;
    final product = provider.findById(selectedProduct.id) ?? selectedProduct;
    final addedQuantity = int.parse(_quantityController.text.trim());
    final body = product.toApiBody();
    body['quantity'] = product.quantity + addedQuantity;

    Navigator.pop(context, {
      '_mode': 'existing',
      '_productId': product.id,
      '_addedQuantity': addedQuantity,
      '_body': body,
      'materialName': product.name,
      'material_SKU': product.sku,
      'quantity': addedQuantity,
      'unit': product.unit,
      'logNumber': product.lot,
      'categoryId': product.categoryId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = widget.provider;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _maybeDiscard();
          if (shouldPop && context.mounted) Navigator.of(context).pop();
        },
        child: Container(
        width: 680,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing ? context.tr.editProduct : context.tr.addProduct,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr.addMaterialSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final shouldPop = await _maybeDiscard();
                        if (shouldPop && context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.add_box_outlined),
                      label: Text('New Material'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.playlist_add_outlined),
                      label: Text('Existing Material'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _mode = selection.first;
                      _submitted = false;
                      _existingError = null;
                      _clearFields();
                    });
                  },
                ),
                const SizedBox(height: 20),
                _mode == 0
                    ? _buildNewMaterialForm(isDark)
                    : _buildExistingMaterialForm(isDark, provider),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final shouldPop = await _maybeDiscard();
                        if (shouldPop && context.mounted) Navigator.pop(context);
                      },
                      child: Text(context.tr.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(_mode == 0 ? Icons.add : Icons.playlist_add),
                      label: Text(_mode == 0 ? context.tr.addProduct : context.tr.add),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1CA0A5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNewMaterialForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildField(
              controller: _nameController,
              label: context.tr.materialName,
              hintText: 'e.g. Paracetamol',
              icon: Icons.medication_outlined,
              isDark: isDark,
            ),
            _buildField(
              controller: _skuController,
              label: context.tr.materialSku,
              hintText: context.tr.skuHint,
              icon: Icons.qr_code_2_outlined,
              isDark: isDark,
            ),
            _buildField(
              controller: _quantityController,
              label: context.tr.quantity,
              hintText: context.tr.quantityHint,
              icon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
              isDark: isDark,
              validator: _validateNonNegativeInteger,
            ),
            _buildField(
              controller: _unitController,
              label: context.tr.unit,
              hintText: context.tr.unitHint,
              icon: Icons.straighten_outlined,
              isDark: isDark,
            ),
            _buildField(
              controller: _logNumberController,
              label: context.tr.logNumber,
              hintText: context.tr.logHint,
              icon: Icons.badge_outlined,
              isDark: isDark,
            ),
            _buildField(
              controller: _storageLocationController,
              label: context.tr.storageLocation,
              hintText: context.tr.locationHint,
              icon: Icons.location_on_outlined,
              isDark: isDark,
            ),
            _buildField(
              controller: _categoryIdController,
              label: context.tr.categoryId,
              hintText: context.tr.categoryIdHint,
              icon: Icons.category_outlined,
              keyboardType: TextInputType.number,
              isDark: isDark,
              validator: _validateNonNegativeInteger,
            ),
            _expiryPicker(isDark),
          ],
        ),
        const SizedBox(height: 20),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            context.tr.isAvailable,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            'Toggle product availability in stock views.',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
          value: _isAvailable,
          onChanged: (value) => setState(() => _isAvailable = value),
        ),
      ],
    );
  }

  Widget _buildExistingMaterialForm(bool isDark, ProductProvider provider) {
    final results = _matchingProducts(provider);
    final selected = _selectedExistingProduct != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          controller: _existingSearchController,
          label: context.tr.searchByNameOrSku,
          hintText: context.tr.typeHintSearch,
          icon: Icons.search,
          isDark: isDark,
          validator: (_) => null,
          readOnly: selected,
          onChanged: (value) => setState(() => _existingQuery = value),
          width: 576,
        ),
        if (!selected && results.isNotEmpty) _resultsList(results, isDark),
        if (selected)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearExistingSelection,
              icon: const Icon(Icons.clear),
              label: Text(context.tr.clear),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildField(
              controller: _nameController,
              label: context.tr.materialName,
              hintText: 'Select material',
              icon: Icons.medication_outlined,
              isDark: isDark,
              readOnly: selected,
              onChanged: (value) => _syncExistingQuery(value),
            ),
            _buildField(
              controller: _skuController,
              label: context.tr.materialSku,
              hintText: 'Select SKU',
              icon: Icons.qr_code_2_outlined,
              isDark: isDark,
              readOnly: selected,
              onChanged: (value) => _syncExistingQuery(value),
            ),
            _buildField(
              controller: _quantityController,
              label: context.tr.quantity,
              hintText: '1',
              icon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
              isDark: isDark,
              validator: _validatePositiveInteger,
            ),
            _buildField(
              controller: _unitController,
              label: context.tr.unit,
              hintText: context.tr.unit,
              icon: Icons.straighten_outlined,
              isDark: isDark,
              readOnly: selected,
            ),
            _buildField(
              controller: _categoryIdController,
              label: context.tr.categoryId,
              hintText: context.tr.category,
              icon: Icons.category_outlined,
              keyboardType: TextInputType.number,
              isDark: isDark,
              readOnly: selected,
              validator: _validatePositiveInteger,
            ),
          ],
        ),
        if (_existingError != null) ...[
          const SizedBox(height: 12),
          Text(_existingError!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    );
  }

  Widget _resultsList(List<MaterialModel> results, bool isDark) {
    return Container(
      width: 576,
      constraints: const BoxConstraints(maxHeight: 190),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = results[index];
          return ListTile(
            dense: true,
            title: Text(product.name),
            subtitle: Text('${context.tr.skuPrefix}${product.sku} | Stock: ${product.quantity}'),
            onTap: () => _selectExistingProduct(product),
          );
        },
      ),
    );
  }

  Widget _expiryPicker(bool isDark) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.expiryDate,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorText: _submitted && _expiryDate == null
                    ? context.tr.pleaseSelectDate
                    : null,
              ),
              child: Text(
                _expiryDate == null ? context.tr.selectDate : _formatDate(_expiryDate!),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool isDark,
    double width = 280,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onChanged: onChanged,
            validator: readOnly
                ? (_) => null
                : validator ??
                      (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr.required;
                        }
                        return null;
                      },
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon),
              suffixIcon: readOnly ? const Icon(Icons.lock_outline) : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MaterialModel> _matchingProducts(ProductProvider provider) {
    final query = _existingQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return provider.products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.sku.toLowerCase().contains(query),
        )
        .take(6)
        .toList();
  }

  void _selectExistingProduct(MaterialModel product) {
    setState(() {
      _selectedExistingProduct = product;
      _existingSearchController.text = '${product.name} (${product.sku})';
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _quantityController.clear();
      _unitController.text = product.unit;
      _logNumberController.text = product.lot;
      _storageLocationController.text = product.location;
      _categoryIdController.text = product.categoryId.toString();
      _existingQuery = '';
      _existingError = null;
    });
  }

  void _syncExistingQuery(String value) {
    if (_selectedExistingProduct != null) return;
    setState(() {
      _existingQuery = value;
      _existingSearchController.text = value;
    });
  }

  void _clearExistingSelection() {
    setState(() {
      _selectedExistingProduct = null;
      _existingError = null;
      _clearFields();
      _existingSearchController.clear();
      _existingQuery = '';
    });
  }

  void _clearFields() {
    _nameController.clear();
    _skuController.clear();
    _quantityController.clear();
    _unitController.clear();
    _logNumberController.clear();
    _storageLocationController.clear();
    _categoryIdController.clear();
    _expiryDate = null;
    _isAvailable = true;
    _selectedExistingProduct = null;
    _existingSearchController.clear();
    _existingQuery = '';
  }

  String? _validateNonNegativeInteger(String? value) {
    if (value == null || value.trim().isEmpty) return context.tr.required;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'Enter a valid number';
    return null;
  }

  String? _validatePositiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) return context.tr.required;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return context.tr.positiveNumber;
    return null;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
