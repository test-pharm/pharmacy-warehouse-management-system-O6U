import 'package:flutter/material.dart';
import 'package:graduation_project/Models/orderModel.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/materialModel.dart';
import 'package:graduation_project/Services/notificationService.dart';
import 'package:graduation_project/Services/orderService.dart';
import 'package:graduation_project/widgets/AddMaterial.dart';
import 'package:graduation_project/widgets/ExpiryEditDialog.dart';
import 'package:graduation_project/widgets/ExportMaterial.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _availabilityFilter = 'All';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ProductProvider.of(context);
    final filtered = provider.products.where(_matchesFilters).toList();
    if (_sortColumnIndex != null) {
      filtered.sort((a, b) {
        final aVal = _sortValue(a);
        final bVal = _sortValue(b);
        final result = Comparable.compare(aVal, bVal);
        return _sortAscending ? result : -result;
      });
    }
    final products = filtered;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _buildToolbar(context, provider),
          const SizedBox(height: 16),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                ? _buildErrorState(context, provider)
                : _buildContent(context, provider, products),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ProductProvider provider) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by product name, SKU, or storage location...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _availabilityFilter,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(value: 'Available', child: Text('Available')),
                DropdownMenuItem(
                  value: 'Unavailable',
                  child: Text('Unavailable'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _availabilityFilter = value);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Refresh products',
          onPressed: provider.loadProducts,
          icon: const Icon(Icons.refresh),
        ),
        if (AuthService.isWarehouseManager) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openProductDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openExportDialog(context, provider),
            icon: const Icon(Icons.upload_outlined),
            label: const Text('Export Product'),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 52),
          const SizedBox(height: 12),
          Text(
            provider.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: provider.loadProducts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductProvider provider,
    List<MaterialModel> products,
  ) {
    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No products found for the current filters.'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowHeight: 54,
            dataRowMinHeight: 62,
            dataRowMaxHeight: 62,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            columns: [
              DataColumn(
                label: const Text('Name'),
                onSort: (colIndex, asc) => setState(() {
                  _sortColumnIndex = colIndex;
                  _sortAscending = asc;
                }),
              ),
              DataColumn(
                label: const Text('Quantity'),
                numeric: true,
                onSort: (colIndex, asc) => setState(() {
                  _sortColumnIndex = colIndex;
                  _sortAscending = asc;
                }),
              ),
              DataColumn(
                label: const Text('Unit'),
                onSort: (colIndex, asc) => setState(() {
                  _sortColumnIndex = colIndex;
                  _sortAscending = asc;
                }),
              ),
              DataColumn(
                label: const Text('Availability'),
                onSort: (colIndex, asc) => setState(() {
                  _sortColumnIndex = colIndex;
                  _sortAscending = asc;
                }),
              ),
              DataColumn(
                label: const Text('Expiry Date'),
                onSort: (colIndex, asc) => setState(() {
                  _sortColumnIndex = colIndex;
                  _sortAscending = asc;
                }),
              ),
              const DataColumn(label: Text('Actions')),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  DataCell(_productSummary(product)),
                  DataCell(Text(_databaseQuantityText(product))),
                  DataCell(Text(product.unit.isEmpty ? '-' : product.unit)),
                  DataCell(_availabilityChip(product.isAvailable)),
                  DataCell(Text(_formatDate(product.expiryDate))),
                  DataCell(_buildActions(context, provider, product)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _productSummary(MaterialModel product) {
    final textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'SKU: ${product.sku}',
          style: TextStyle(fontSize: 12, color: textColor),
        ),
      ],
    );
  }

  Widget _availabilityChip(bool isAvailable) {
    final color = isAvailable ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) {
    if (!AuthService.isWarehouseManager) {
      return IconButton(
        tooltip: 'View details',
        onPressed: () => _showDetails(context, product),
        icon: const Icon(Icons.visibility_outlined),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit product',
          onPressed: () =>
              _openProductDialog(context, provider, existingProduct: product),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete product',
          onPressed: () => _confirmDelete(context, provider, product),
          icon: const Icon(Icons.delete_outline),
          color: Colors.red,
        ),
      ],
    );
  }

  Future<void> _openProductDialog(
    BuildContext context,
    ProductProvider provider, {
    MaterialModel? existingProduct,
  }) async {
    if (existingProduct != null) {
      await _openExpiryEditDialog(context, existingProduct);
      return;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddMaterialDialog(provider: provider),
    );

    if (payload == null) {
      return;
    }

    final isExistingStockAdd = payload['_mode'] == 'existing';
    final String? error;
    if (isExistingStockAdd) {
      error = await provider.updateProduct(
        payload['_productId'].toString(),
        Map<String, dynamic>.from(payload['_body'] as Map),
      );
    } else {
      error = await provider.addProduct(payload);
    }

    if (!context.mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    OrderService.addOrder(
      OrderModel(
        productId: isExistingStockAdd ? payload['_productId'].toString() : null,
        productName: payload['materialName']?.toString() ?? '',
        productSku: payload['material_SKU']?.toString() ?? '',
        quantity: payload['quantity'] is int
            ? payload['quantity'] as int
            : int.tryParse(payload['quantity']?.toString() ?? '') ?? 0,
        unit: payload['unit']?.toString() ?? '',
        logNumber: payload['logNumber']?.toString() ?? '',
        categoryId: payload['categoryId'] is int
            ? payload['categoryId'] as int
            : int.tryParse(payload['categoryId']?.toString() ?? '') ?? 0,
        type: OrderType.add,
        status: OrderStatus.completed,
        createdBy: AuthService.currentUser?.fullName ?? 'Unknown user',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isExistingStockAdd
              ? 'Stock updated successfully.'
              : 'Product added successfully.',
        ),
      ),
    );
  }

  Future<void> _openExportDialog(
    BuildContext context,
    ProductProvider provider,
  ) async {
    final result = await showDialog<ExportMaterialResult>(
      context: context,
      builder: (_) => ExportMaterialDialog(provider: provider),
    );
    if (result == null) return;

    final error = await provider.updateProduct(result.product.id, result.body);
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    OrderService.addOrder(
      OrderModel(
        productId: result.product.id,
        productName: result.product.name,
        productSku: result.product.sku,
        quantity: result.quantity,
        unit: result.product.unit,
        logNumber: result.product.lot,
        categoryId: result.product.categoryId,
        type: OrderType.export,
        status: OrderStatus.completed,
        createdBy: AuthService.currentUser?.fullName ?? 'Unknown user',
      ),
    );

    // Determine the remaining quantity from the body that was sent to the API.
    final remainingQty = result.body['quantity'] as int? ?? -1;
    final outOfStock = remainingQty == 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outOfStock
              ? '${result.quantity} units of ${result.product.name} exported. Item is now out of stock and marked Unavailable.'
              : '${result.quantity} units of ${result.product.name} exported successfully.',
        ),
        backgroundColor: outOfStock ? Colors.orange : null,
      ),
    );
  }

  Future<void> _openExpiryEditDialog(
    BuildContext context,
    MaterialModel product,
  ) async {
    final newExpiry = await showDialog<String>(
      context: context,
      builder: (_) => ExpiryEditDialog(product: product),
    );
    if (newExpiry == null) return;

    final createdBy = AuthService.currentUser?.fullName ?? 'Unknown user';
    OrderService.addOrder(
      OrderModel(
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        quantity: product.quantity,
        unit: product.unit,
        logNumber: product.lot,
        categoryId: product.categoryId,
        type: OrderType.edit,
        status: OrderStatus.pending,
        createdBy: createdBy,
        notes: newExpiry,
      ),
    );

    NotificationService.addNotification(
      AppNotification(
        title: 'Edit Request',
        body:
            '$createdBy requested expiry change for ${product.name} (${product.sku})',
        materialName: product.name,
        productSku: product.sku,
        proposedExpiry: newExpiry,
        managerName: createdBy,
      ),
    );

    NotificationService.sendEditRequestEmail(
      productName: product.name,
      productSku: product.sku,
      managerName: createdBy,
      newExpiry: _formatDate(newExpiry),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit request submitted. Awaiting supervisor approval.'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final productName = product.name;
    final productId = product.id;
    bool _cancelled = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName will be deleted...'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _cancelled = true,
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    await Future.delayed(const Duration(seconds: 4));
    if (_cancelled || !context.mounted) return;

    final error = await provider.deleteProduct(productId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '$productName deleted successfully.'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  void _showDetails(BuildContext context, MaterialModel product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F7FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (product.isAvailable ? Colors.green : Colors.orange).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: product.isAvailable ? Colors.green : Colors.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                          const SizedBox(height: 2),
                          Text('SKU: ${product.sku}',
                            style: TextStyle(fontSize: 13, color: mutedColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _detailRow(Icons.category_outlined, 'Category', product.category.isNotEmpty ? product.category : product.categoryId.toString()),
                    const Divider(height: 20),
                    _detailRow(Icons.inventory_outlined, 'Quantity', '${product.quantity} ${product.unit}'),
                    const Divider(height: 20),
                    _detailRow(Icons.qr_code_outlined, 'Lot / Batch', product.lot.isEmpty ? '-' : product.lot),
                    const Divider(height: 20),
                    _detailRow(Icons.location_on_outlined, 'Storage', product.location.isEmpty ? '-' : product.location),
                    const Divider(height: 20),
                    _detailRow(Icons.calendar_today_outlined, 'Expiry Date', _formatDate(product.expiryDate)),
                    const Divider(height: 20),
                    _detailRow(
                      Icons.check_circle_outlined,
                      'Status',
                      product.isAvailable ? 'Available' : 'Unavailable',
                      valueColor: product.isAvailable ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('Close', style: TextStyle(color: mutedColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    final muted = Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54;
    return Row(
      children: [
        Icon(icon, size: 18, color: muted),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text('$label:', style: TextStyle(fontSize: 13, color: muted)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor),
          ),
        ),
      ],
    );
  }

  String _databaseQuantityText(MaterialModel product) {
    return product.quantity.toString();
  }

  bool _matchesFilters(MaterialModel product) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final matchesSearch =
        query.isEmpty ||
        product.name.toLowerCase().contains(query) ||
        product.sku.toLowerCase().contains(query) ||
        product.location.toLowerCase().contains(query);

    final matchesAvailability = switch (_availabilityFilter) {
      'Available' => product.isAvailable,
      'Unavailable' => !product.isAvailable,
      _ => true,
    };

    return matchesSearch && matchesAvailability;
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    } catch (_) {
      return raw.isEmpty ? '-' : raw;
    }
  }

  Comparable _sortValue(MaterialModel p) {
    switch (_sortColumnIndex) {
      case 0: return p.name.toLowerCase();
      case 1: return p.quantity;
      case 2: return p.unit.toLowerCase();
      case 3: return p.isAvailable ? 1 : 0;
      case 4:
        final dt = DateTime.tryParse(p.expiryDate);
        return dt ?? DateTime(9999);
      default: return 0;
    }
  }
}