import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Language codes ───────────────────────────────────────────────────────────
enum AppLanguage { en, ar }

// ─── Global notifier (mirrors themeNotifier pattern already in the project) ──
final ValueNotifier<AppLanguage> languageNotifier =
    ValueNotifier(AppLanguage.en);

// ─── Persist / restore language ──────────────────────────────────────────────
const _kLangKey = 'app_language';

Future<void> initLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_kLangKey);
  if (saved == 'ar') {
    languageNotifier.value = AppLanguage.ar;
  }
}

Future<void> saveLanguage(AppLanguage lang) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLangKey, lang.name);
}

// ─── Extension so any widget can do: context.tr.dashboard ────────────────────
extension LocalizationContext on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(languageNotifier.value);
}

// ─── Main translations class ─────────────────────────────────────────────────
class AppLocalizations {
  final AppLanguage language;
  const AppLocalizations._(this.language);

  static AppLocalizations of(AppLanguage lang) =>
      AppLocalizations._(lang);

  bool get isArabic => language == AppLanguage.ar;
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  // ── General ────────────────────────────────────────────────────────────────
  String get appTitle => isArabic ? 'نظام إدارة المستودعات' : 'Pharmacy Logistics';
  String get appSubtitle => isArabic ? 'نظام إدارة المستودعات الصيدلانية' : 'WAREHOUSE MANAGEMENT SYSTEM';
  String get loading => isArabic ? 'جارٍ التحميل...' : 'Loading...';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get close => isArabic ? 'إغلاق' : 'Close';
  String get submit => isArabic ? 'إرسال' : 'Submit';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get add => isArabic ? 'إضافة' : 'Add';
  String get search => isArabic ? 'بحث' : 'Search';
  String get refresh => isArabic ? 'تحديث' : 'Refresh';
  String get required => isArabic ? 'مطلوب' : 'Required';
  String get yes => isArabic ? 'نعم' : 'Yes';
  String get no => isArabic ? 'لا' : 'No';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  String get error => isArabic ? 'خطأ' : 'Error';
  String get success => isArabic ? 'نجاح' : 'Success';
  String get clear => isArabic ? 'مسح' : 'Clear';
  String get back => isArabic ? 'رجوع' : 'Back';
  String get print => isArabic ? 'طباعة' : 'Print';
  String get export => isArabic ? 'تصدير' : 'Export';
  String get noData => isArabic ? 'لا توجد بيانات' : 'No data';
  String get unknownUser => isArabic ? 'مستخدم غير معروف' : 'Unknown user';
  String get more => isArabic ? 'المزيد ->' : 'More ->';

  // ── Sidebar / Navigation ────────────────────────────────────────────────────
  String get dashboard => isArabic ? 'لوحة التحكم' : 'Dashboard';
  String get inventory => isArabic ? 'المخزون' : 'Inventory';
  String get reports => isArabic ? 'التقارير' : 'Reports';
  String get orders => isArabic ? 'الطلبات' : 'Orders';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get toggleTheme => isArabic ? 'تبديل السمة' : 'Toggle theme';
  String get toggleLanguage => isArabic ? 'تبديل اللغة' : 'Toggle language';
  String get pharmaWarehouse => isArabic ? 'مستودع الصيدلية' : 'PharmaWarehouse';

  // ── Roles ──────────────────────────────────────────────────────────────────
  String get manager => isArabic ? 'مدير' : 'Manager';
  String get supervisor => isArabic ? 'مشرف' : 'Supervisor';
  String get warehouseManager => isArabic ? 'مدير المستودع' : 'Warehouse Manager';
  String get supervisorView => isArabic
      ? 'عرض المشرف — للقراءة فقط.'
      : 'Supervisor view — read-only.';

  // ── Alerts sidebar panel ───────────────────────────────────────────────────
  String criticalAlerts(int count) => isArabic
      ? '$count تنبيه${count == 1 ? '' : 'ات'} حرجة'
      : '$count Critical Alert${count == 1 ? '' : 's'}';
  String expiredExpiringSoon(int count) => isArabic
      ? '$count منتهي / قارب على الانتهاء'
      : '$count expired / expiring soon';
  String lowStockItems(int count) => isArabic
      ? '$count صنف${count == 1 ? '' : 'أصناف'} منخفض المخزون'
      : '$count low-stock item${count == 1 ? '' : 's'}';

  // ── Login ──────────────────────────────────────────────────────────────────
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get enterEmail => isArabic ? 'أدخل بريدك الإلكتروني' : 'Enter your email';
  String get enterPassword => isArabic ? 'أدخل كلمة مرورك' : 'Enter your password';
  String get signIn => isArabic ? 'تسجيل الدخول' : 'SIGN IN';
  String get createAccount => isArabic ? 'إنشاء حساب' : 'CREATE ACCOUNT';
  String get registerNewUser => isArabic ? 'تسجيل مستخدم جديد' : 'Register New User';
  String get alreadyHaveAccount => isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?';
  String get loginFailed => isArabic ? 'فشل تسجيل الدخول' : 'Login failed';
  String get invalidEmail => isArabic ? 'أدخل بريدًا إلكترونيًا صالحًا' : 'Enter a valid email';
  String get enterYourEmail => isArabic ? 'من فضلك أدخل بريدك الإلكتروني' : 'Please enter your email';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get confirmPassword => isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get passwordsDoNotMatch => isArabic ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get atLeast6Chars => isArabic ? 'على الأقل 6 أحرف' : 'At least 6 characters';
  String get minSixChars => isArabic ? 'الحد الأدنى 6 أحرف' : 'Min. 6 characters';
  String get repeatPassword => isArabic ? 'أعد كتابة كلمتك المرور' : 'Repeat your password';
  String get validPhone => isArabic ? 'أدخل رقم هاتف صالحًا' : 'Enter a valid phone number';
  String get roleLabel => isArabic ? 'الدور' : 'Role';
  String get backToLogin => isArabic ? 'العودة لتسجيل الدخول' : 'Back to Login';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  String get warehouseOverview => isArabic ? 'نظرة عامة على المستودع' : 'Warehouse Overview';
  String get totalMaterials => isArabic ? 'إجمالي المواد' : 'Total Materials';
  String get nearingExpiry => isArabic ? 'قاربت على الانتهاء' : 'Nearing Expiry';
  String get lowStockItemsTitle => isArabic ? 'أصناف منخفضة المخزون' : 'Low Stock Items';
  String get criticalAlertsTitle => isArabic ? 'التنبيهات الحرجة' : 'Critical Alerts';
  String get recentMaterials => isArabic ? 'المواد الأخيرة' : 'Recent Materials';
  String get chartPlaceholder => isArabic ? 'مخطط بياني' : 'Chart Visualization Placeholder';
  String get noCriticalAlerts => isArabic ? 'لا توجد تنبيهات حرجة' : 'No critical alerts';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get noNotifications => isArabic ? 'لا توجد إشعارات' : 'No notifications';
  String get noActiveNotifications => isArabic ? 'لا توجد إشعارات نشطة' : 'No active notifications';
  String get markRead => isArabic ? 'تعيين كمقروء' : 'Mark Read';
  String get markAllRead => isArabic ? 'تعيين الكل كمقروء' : 'Mark All Read';
  String get searchHint => isArabic
      ? 'ابحث عن مواد أو طلبات أو تقارير'
      : 'Search for materials, orders, or reports';

  // ── Inventory ──────────────────────────────────────────────────────────────
  String get inventoryTitle => isArabic ? 'قائمة المخزون' : 'Inventory List';
  String get addMaterial => isArabic ? 'إضافة مادة' : 'Add Material';
  String get exportMaterial => isArabic ? 'صرف مادة' : 'Dispatch Material';
  String get materialName => isArabic ? 'اسم المادة' : 'Material Name';
  String get materialSku => isArabic ? 'رمز المادة (SKU)' : 'Material SKU';
  String get quantity => isArabic ? 'الكمية' : 'Quantity';
  String get unit => isArabic ? 'الوحدة' : 'Unit';
  String get logNumber => isArabic ? 'رقم السجل' : 'Log Number';
  String get expiryDate => isArabic ? 'تاريخ الانتهاء' : 'Expiry Date';
  String get storageLocation => isArabic ? 'موقع التخزين' : 'Storage Location';
  String get category => isArabic ? 'الفئة' : 'Category';
  String get categoryId => isArabic ? 'معرف الفئة' : 'Category ID';
  String get status => isArabic ? 'الحالة' : 'Status';
  String get available => isArabic ? 'متاح' : 'Available';
  String get unavailable => isArabic ? 'غير متاح' : 'Unavailable';
  String get actions => isArabic ? 'الإجراءات' : 'Actions';
  String get filterByCategory => isArabic ? 'تصفية حسب الفئة' : 'Filter by category';
  String get allCategories => isArabic ? 'كل الفئات' : 'All Categories';
  String get confirmDelete => isArabic ? 'تأكيد الحذف' : 'Confirm Delete';
  String get deleteConfirmMsg => isArabic
      ? 'هل أنت متأكد أنك تريد حذف هذه المادة؟'
      : 'Are you sure you want to delete this material?';
  String get editProduct => isArabic ? 'تعديل المنتج' : 'Edit Product';
  String get noProductsFound => isArabic ? 'لا توجد منتجات' : 'No products found';
  String get searchByNameOrSku => isArabic ? 'ابحث بالاسم أو الرمز' : 'Search by Name or SKU';

  // ── Status labels ──────────────────────────────────────────────────────────
  String get statusGood => isArabic ? 'جيد' : 'Good';
  String get statusExpired => isArabic ? 'منتهي الصلاحية' : 'Expired';
  String get statusExpiringSoon => isArabic ? 'ينتهي قريبًا' : 'Expiring Soon';
  String get statusLowStock => isArabic ? 'مخزون منخفض' : 'Low Stock';
  String get statusUnknown => isArabic ? 'غير معروف' : 'Unknown';

  // ── Add Material dialog ────────────────────────────────────────────────────
  String get addMaterialTitle => isArabic ? 'إضافة مادة جديدة' : 'Add New Material';
  String get addMaterialSubtitle => isArabic
      ? 'أضف مادة جديدة إلى مخزون المستودع.'
      : 'Add a new material to the warehouse inventory.';
  String get isAvailable => isArabic ? 'متاح' : 'Is Available';
  String get positiveNumber => isArabic ? 'أدخل رقمًا موجبًا' : 'Enter a positive number';
  String get skuHint => isArabic ? 'مثال: MED-1001' : 'e.g. MED-1001';
  String get quantityHint => isArabic ? 'مثال: 100' : 'e.g. 100';
  String get unitHint => isArabic ? 'علبة / زجاجة / شريط' : 'box / bottle / strip';
  String get logHint => isArabic ? 'LOT-2026-01' : 'LOT-2026-01';
  String get locationHint => isArabic ? 'مثال: الرف A1' : 'e.g. Shelf A1';
  String get categoryIdHint => isArabic ? '1' : '1';
  String get selectDate => isArabic ? 'اختر تاريخًا' : 'Select date';
  String get pleaseSelectDate => isArabic ? 'من فضلك اختر تاريخًا' : 'Please select an expiry date';
  String get addingProduct => isArabic ? 'جارٍ الإضافة...' : 'Adding...';
  String get productAdded => isArabic ? 'تمت إضافة المنتج بنجاح' : 'Product added successfully';

  // ── Export dialog ──────────────────────────────────────────────────────────
  String get exportProductTitle => isArabic ? 'صرف منتج' : 'Dispatch Product';
  String get exportProductSubtitle => isArabic
      ? 'سجّل مغادرة المنتج من مخزون المستودع.'
      : 'Record product leaving warehouse inventory.';
  String get exportProductBtn => isArabic ? 'صرف' : 'Dispatch';
  String get productNotFound => isArabic ? 'المنتج غير موجود في المخزون' : 'Product not found in inventory';
  String get outOfStock => isArabic ? 'هذا الصنف نفد من المخزون' : 'This item is already out of stock';
  String get exceedsStock => isArabic ? 'الكمية المُصدَّرة تتجاوز المخزون المتاح' : 'Export quantity exceeds available stock';
  String get typeHintSearch => isArabic ? 'اكتب اسم المادة أو الرمز' : 'Type material name or SKU';

  // ── Expiry edit dialog ─────────────────────────────────────────────────────
  String get requestExpiryEdit => isArabic ? 'طلب تعديل تاريخ الانتهاء' : 'Request Expiry Edit';
  String get product => isArabic ? 'المنتج' : 'Product';
  String get sku => isArabic ? 'الرمز' : 'SKU';
  String get newExpiryDate => isArabic ? 'تاريخ الانتهاء الجديد' : 'New Expiry Date';
  String get requestEdit => isArabic ? 'طلب التعديل' : 'Request Edit';

  // ── Orders ─────────────────────────────────────────────────────────────────
  String get ordersTitle => isArabic ? 'سجل الطلبات' : 'Orders Log';
  String get pendingOrders => isArabic ? 'الطلبات المعلقة' : 'Pending Orders';
  String get noOrders => isArabic ? 'لا توجد طلبات' : 'No orders';
  String get orderType => isArabic ? 'نوع الطلب' : 'Order Type';
  String get orderStatus => isArabic ? 'حالة الطلب' : 'Order Status';
  String get createdBy => isArabic ? 'أنشئ بواسطة' : 'Created By';
  String get createdAt => isArabic ? 'تاريخ الإنشاء' : 'Created At';
  String get notes => isArabic ? 'ملاحظات' : 'Notes';
  String get approve => isArabic ? 'قبول' : 'Approve';
  String get reject => isArabic ? 'رفض' : 'Reject';
  String get orderTypeAdd => isArabic ? 'إضافة' : 'Add';
  String get orderTypeExport => isArabic ? 'تصدير' : 'Export';
  String get orderTypeEdit => isArabic ? 'تعديل' : 'Edit';
  String get orderStatusCompleted => isArabic ? 'مكتمل' : 'Completed';
  String get orderStatusPending => isArabic ? 'معلق' : 'Pending';
  String get orderStatusCanceled => isArabic ? 'ملغى' : 'Canceled';
  String get printOrders => isArabic ? 'طباعة الطلبات' : 'Print Orders';
  String get supervisorReadOnly => isArabic
      ? 'عرض المشرف — للقراءة فقط. يمكنك طباعة الطلبات.'
      : 'Supervisor view — read-only. You may print orders.';

  // ── Reports ────────────────────────────────────────────────────────────────
  String get reportsTitle => isArabic ? 'التقارير' : 'Reports';
  String get printReport => isArabic ? 'طباعة التقرير' : 'Print Report';
  String get supervisorReportReadOnly => isArabic
      ? 'عرض المشرف — للقراءة فقط. يمكنك طباعة التقارير.'
      : 'Supervisor view — read-only. You may print reports.';
  String get totalStock => isArabic ? 'إجمالي المخزون' : 'Total Stock';
  String get expiredItems => isArabic ? 'أصناف منتهية الصلاحية' : 'Expired Items';
  String get expiringSoonItems => isArabic ? 'أصناف تنتهي قريبًا' : 'Expiring Soon Items';
  String get categoryBreakdown => isArabic ? 'توزيع الفئات' : 'Category Breakdown';
  String get stockByCategory => isArabic ? 'المخزون حسب الفئة' : 'Stock by Category';

  // ── User info / Settings ───────────────────────────────────────────────────
  String get userInfo => isArabic ? 'معلومات المستخدم' : 'User Info';
  String get profileSettings => isArabic ? 'إعدادات الملف الشخصي' : 'Profile Settings';
  String get accountDetails => isArabic ? 'تفاصيل الحساب' : 'Account Details';
  String get changePassword => isArabic ? 'تغيير كلمة المرور' : 'Change Password';
  String get updateProfile => isArabic ? 'تحديث الملف الشخصي' : 'Update Profile';
  String get registerUser => isArabic ? 'تسجيل مستخدم' : 'Register User';
  String get registerAdmin => isArabic ? 'تسجيل مدير' : 'Register Admin';
  String get userList => isArabic ? 'قائمة المستخدمين' : 'User List';

  // ── Stocktake ──────────────────────────────────────────────────────────────
  String get stocktake => isArabic ? 'الجرد' : 'Stocktake';
  String get stocktakeDesc => isArabic
      ? 'توليد كشف الجرد للعد الفعلي للمخزون في المستودع.'
      : 'Generate a stocktake sheet to physically count warehouse inventory.';
  String get totalItems => isArabic ? 'إجمالي الأصناف' : 'total items';
  String get storageLocationsLabel => isArabic ? 'مواقع تخزين' : 'storage locations';
  String get generateStocktake => isArabic ? 'توليد كشف الجرد' : 'Generate Stocktake Sheet';
  String get unspecified => isArabic ? 'غير محدد' : 'Unspecified';
  String get itemsLabel => isArabic ? 'أصناف' : 'items';
  String get skuPrefix => isArabic ? 'رمز: ' : 'SKU: ';
  String get qtyPrefix => isArabic ? 'الكمية: ' : 'Qty: ';
  String get stocktakeSheet => isArabic ? 'كشف الجرد' : 'Stocktake Sheet';
  String get pdfInstructions => isArabic
      ? 'تعليمات: تجول في كل موقع، واحسب الكمية الفعلية، واكتبها في عمود "العدد الفعلي". سجل أي اختلافات.'
      : 'Instructions: Walk through each location, count the actual quantity, and write it in the "Actual Count" column. Note any discrepancies.';
  String get locationPrefix => isArabic ? 'الموقع: ' : 'Location: ';
  String get pdfColumnNum => isArabic ? '#' : '#';
  String get pdfColumnProductName => isArabic ? 'اسم المنتج' : 'Product Name';
  String get pdfColumnActualCount => isArabic ? 'العدد الفعلي' : 'Actual Count';
  String get chooseExportMethod => isArabic ? 'اختر طريقة التصدير:' : 'Choose how to export:';
  String get saveOrShare => isArabic ? 'حفظ / مشاركة' : 'Save / Share';
  String get generatedPrefix => isArabic ? 'تم الإنشاء: ' : 'Generated: ';
  String get errorGeneratingPdf => isArabic ? 'خطأ في إنشاء ملف PDF' : 'Error generating PDF';

  // ── Additional Inventory ───────────────────────────────────────────────────
  String get refreshTooltip => isArabic ? 'تحديث' : 'Refresh';
  String get addProduct => isArabic ? 'إضافة منتج' : 'Add Product';
  String get dispatchBtn => isArabic ? 'صرف' : 'Dispatch';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get noProductsFiltered => isArabic
      ? 'لا توجد منتجات تطابق الفلاتر الحالية.'
      : 'No products found for the current filters.';
  String get availabilityColumn => isArabic ? 'التوفر' : 'Availability';
  String get viewDetailsTooltip => isArabic ? 'عرض التفاصيل' : 'View details';
  String get deleteProductTooltip => isArabic ? 'حذف المنتج' : 'Delete product';
  String get stockUpdated => isArabic ? 'تم تحديث المخزون بنجاح.' : 'Stock updated successfully.';
  String unitsDispatched(int units, String product) => isArabic
      ? '$units وحدة من $product تم صرفها.'
      : '$units units of $product dispatched.';
  String outOfStockWarning(int units, String product) => isArabic
      ? '$units وحدة من $product تم صرفها. الصنف نفد من المخزون وتم تعليمه كـ "غير متاح".'
      : '$units units of $product dispatched. Item is now out of stock and marked Unavailable.';
  String get editRequestSubmitted => isArabic
      ? 'تم تقديم طلب تعديل تاريخ الانتهاء.'
      : 'Edit request submitted.';
  String get awaitingApproval => isArabic ? 'بإنتظار موافقة المشرف.' : 'Awaiting supervisor approval.';
  String get deleteTitle => isArabic ? 'حذف المنتج' : 'Delete Product';
  String deleteConfirmNamed(String name) => isArabic
      ? 'هل أنت متأكد أنك تريد حذف "$name"؟'
      : 'Are you sure you want to delete "$name"?';
  String productDeleted(String name) => isArabic
      ? 'تم حذف $name بنجاح.'
      : '$name deleted successfully.';
  String get undo => isArabic ? 'تراجع' : 'Undo';
  String get all => isArabic ? 'الكل' : 'All';
  String get ordersHistory => isArabic ? 'سجل الطلبات' : 'Orders History';
  String get filterByDate => isArabic ? 'تصفية حسب التاريخ' : 'Filter by Date';
  String get filterByStatus => isArabic ? 'تصفية حسب الحالة' : 'Filter by Status';
  String get editRequests => isArabic ? 'طلبات التعديل' : 'Edit Requests';
  String get noEditRequests => isArabic ? 'لا توجد طلبات تعديل' : 'No edit request notifications';
  String get goToOrders => isArabic ? 'انتقل إلى الطلبات' : 'Go to Orders';
  String get searchOrdersHint => isArabic
      ? 'ابحث برقم الطلب أو المنتج أو الرمز...'
      : 'Search by order ID, product, SKU, or user...';
  String get productNotInInventory => isArabic
      ? 'المنتج غير موجود في المخزون.'
      : 'Product not found in inventory.';
  String get reportsAndAnalytics => isArabic ? 'التقارير والتحليلات' : 'Reports & Analytics';
  String get exportReport => isArabic ? 'تصدير التقرير' : 'Export Report';
  String get alertsLabel => isArabic ? 'التنبيهات' : 'Alerts';
  String get accountSettings => isArabic ? 'إعدادات الحساب' : 'Account Settings';
  String get editProfile => isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile';
  String get personalInfo => isArabic ? 'المعلومات الشخصية' : 'Personal Information';
  String get saving => isArabic ? 'جارٍ الحفظ...' : 'Saving...';
  String get saveChanges => isArabic ? 'حفظ التغييرات' : 'Save Changes';
  String get privacySecurity => isArabic ? 'الخصوصية والأمان' : 'Privacy & Security';
  String get updateAvailable => isArabic ? 'يوجد تحديث متاح' : 'Update Available';
  String get installingUpdate => isArabic ? 'جارٍ تثبيت التحديث...' : 'Installing Update...';
  String get downloadingUpdate => isArabic ? 'جارٍ تنزيل التحديث...' : 'Downloading Update...';
  String get updateNow => isArabic ? 'تحديث الآن' : 'Update Now';
  String get maybeLater => isArabic ? 'ربما لاحقًا' : 'Maybe Later';
  String get whatsNew => isArabic ? 'ما الجديد:' : "What's new:";
  String get downloadUrlNotConfigured => isArabic
      ? 'رابط التنزيل غير مهيأ.'
      : 'Download URL not configured.';

  // ── Printing snackbars ─────────────────────────────────────────────────────
  String get printingOrders => isArabic ? 'جارٍ طباعة الطلبات...' : 'Printing orders…';
  String get printingReport => isArabic ? 'جارٍ طباعة التقرير...' : 'Printing report…';
}
