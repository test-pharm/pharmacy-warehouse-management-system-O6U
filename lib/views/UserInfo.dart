import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/Services/notificationService.dart';
import 'package:http/http.dart' as http;

class UserInfoPage extends StatefulWidget {
  final bool showBackButton;

  const UserInfoPage({super.key, this.showBackButton = false});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  static const String _baseUrl = 'http://chemistore.runasp.net/api';
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = AuthService.currentUser;
    _nameController.text = user?.fullName ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final current = AuthService.currentUser;
    if (current == null) return;

    setState(() => _saving = true);
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/Auth/update-profile'),
            headers: AuthService.authHeaders,
            body: jsonEncode({
              'fullName': _nameController.text.trim(),
              'phoneNumber': _phoneController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _showSnack('Unable to update profile.', isError: true);
        return;
      }

      await AuthService.updateCurrentUser(
        current.copyWith(
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      _showSnack('Profile updated successfully');
    } catch (e) {
      if (mounted) _showSnack('Unable to update profile.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A1A1F) : const Color(0xFFF5F9FA);
    final cardColor = isDark ? const Color(0xFF1A2F35) : Colors.white;
    final isManager = AuthService.isWarehouseManager;
    final roleColor = isManager ? Colors.blue : Colors.green;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.showBackButton) ...[
                  IconButton(
                    tooltip: context.tr.back,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  context.tr.accountSettings,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (!_isEditing)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit),
                    label: Text(context.tr.editProfile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CA0A5),
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _profileHeader(cardColor, roleColor, isManager, isDark),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: _cardDecoration(cardColor),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.personalInfo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _field(
                      controller: _nameController,
                      label: context.tr.fullName,
                      icon: Icons.person_outline,
                      enabled: _isEditing,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      controller: _phoneController,
                      label: context.tr.phoneNumber,
                      icon: Icons.phone_outlined,
                      enabled: _isEditing,
                      isDark: isDark,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    _loadUserData();
                                    setState(() => _isEditing = false);
                                  },
                            child: Text(context.tr.cancel),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saving ? null : _saveChanges,
                            child: Text(_saving ? context.tr.saving : context.tr.saveChanges),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: _cardDecoration(cardColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.accountSettings,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF1CA0A5),
                    ),
                    title: Text(context.tr.changePassword),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF1CA0A5),
                    ),
                    title: Text(context.tr.notifications),
                    trailing: _notificationBadge(),
                    onTap: _showNotificationsDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.security_outlined,
                      color: Color(0xFF1CA0A5),
                    ),
                    title: Text(context.tr.privacySecurity),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(context.tr.privacySecurity),
                        content: const Text('Privacy settings coming soon.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(
    Color cardColor,
    Color roleColor,
    bool isManager,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(cardColor),
      child: Row(
        children: [
          CircleAvatar(
  radius: 42,
  backgroundColor: roleColor.withOpacity(0.14),
  child: ClipOval(
    child: Image.asset(
      'assets/pharmacy faculty logo.png',
      width: 84,
      height: 84,
      fit: BoxFit.cover,
    ),
  ),
),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty
                      ? context.tr.unknownUser
                      : _nameController.text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _phoneController.text.isEmpty ? '-' : _phoneController.text,
                ),
                const SizedBox(height: 10),
                _roleBadge(isManager, roleColor),
                const SizedBox(height: 8),
                Text(
                  isManager
                      ? 'Scope: Dashboard, Inventory, Reports, Orders, Settings'
                      : 'Scope: Orders and Reports',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(bool isManager, Color roleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor.withOpacity(0.3)),
      ),
      child: Text(
        isManager ? context.tr.warehouseManager : context.tr.supervisor,
        style: TextStyle(color: roleColor, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _profileInitial() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  Widget _notificationBadge() {
    final count = NotificationService.getUnread().length;
    if (count == 0) return const Icon(Icons.chevron_right);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  BoxDecoration _cardDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1CA0A5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: !enabled,
        fillColor: enabled
            ? null
            : (isDark ? Colors.grey[850] : Colors.grey[100]),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return context.tr.required;
        return null;
      },
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr.notifications),
          content: SizedBox(
            width: 460,
            child: NotificationService.getAll().isEmpty
                ? Text(context.tr.noNotifications)
                : ListView(
                    shrinkWrap: true,
                    children: NotificationService.getAll().map((item) {
                      return ListTile(
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
                                child: Text(context.tr.markRead),
                              ),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                NotificationService.markAllRead();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: Text(context.tr.markAllRead),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr.close),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(context: context, builder: (_) => const _ChangePasswordDialog());
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  static const String _baseUrl = 'http://chemistore.runasp.net/api';
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  int _step = 0;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr.changePassword),
      content: SizedBox(
        width: 520,
        child: Stepper(
          currentStep: _step,
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            Step(
              title: const Text('Send Code'),
              isActive: _step >= 0,
              state: _stepState(0),
              content: _stepContent(
                children: [
                  const Text(
                    'Send a password reset verification code to your registered email address.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _sendCode,
                    child: const Text('Send Verification Code'),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Verify Code'),
              isActive: _step >= 1,
              state: _stepState(1),
              content: _stepContent(
                children: [
                  TextField(
                    controller: _codeCtrl,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '6-digit code',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _verifyCode,
                    child: const Text('Verify Code'),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('New Password'),
              isActive: _step >= 2,
              state: _stepState(2),
              content: _stepContent(
                children: [
                  TextField(
                    controller: _newPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                  ),
                  TextField(
                    controller: _confirmPasswordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: context.tr.confirmPassword,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _changePassword,
                    child: Text(context.tr.changePassword),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr.close),
        ),
      ],
    );
  }

  Widget _stepContent({required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children,
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        if (_success != null) ...[
          const SizedBox(height: 8),
          Text(_success!, style: const TextStyle(color: Colors.green)),
        ],
      ],
    );
  }

  StepState _stepState(int index) {
    if (_step > index) return StepState.complete;
    if (_step == index) return StepState.editing;
    return StepState.indexed;
  }

  Future<void> _sendCode() async {
    final email = _registeredEmail;
    if (email.isEmpty) {
      setState(() => _error = 'No registered email address was found.');
      return;
    }
    await _post(
      '/Auth/send-reset-code',
      {'email': email},
      onSuccess: () => setState(() {
        _step = 1;
        _success =
            'A verification code has been sent to your registered email address.';
      }),
    );
  }

  Future<void> _verifyCode() async {
    await _post('/Auth/verify-reset-code', {
      'email': _registeredEmail,
      'code': _codeCtrl.text.trim(),
    }, onSuccess: () => setState(() => _step = 2));
  }

  Future<void> _changePassword() async {
    if (_newPasswordCtrl.text.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() => _error = context.tr.passwordsDoNotMatch);
      return;
    }
    await _post(
      '/Auth/change-password',
      {
        'email': _registeredEmail,
        'code': _codeCtrl.text.trim(),
        'newPassword': _newPasswordCtrl.text,
      },
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
        setState(() {
          _step = 0;
          _codeCtrl.clear();
          _newPasswordCtrl.clear();
          _confirmPasswordCtrl.clear();
        });
      },
    );
  }

  String get _registeredEmail => AuthService.currentUser?.email.trim() ?? '';

  Future<void> _post(
    String path,
    Map<String, dynamic> body, {
    required VoidCallback onSuccess,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: AuthService.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        onSuccess();
      } else {
        setState(() => _error = _extractError(response));
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Request failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _extractError(http.Response response) {
    if (response.body.trim().isEmpty) {
      return 'Request failed (${response.statusCode}).';
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final messages = errors.values
              .expand((value) => value is List ? value : [value])
              .map((value) => value.toString())
              .where((value) => value.trim().isNotEmpty)
              .toList();
          if (messages.isNotEmpty) return messages.join('\n');
        }
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['title'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      if (decoded is String && decoded.trim().isNotEmpty) return decoded;
    } catch (_) {
      if (response.body.trim().isNotEmpty) return response.body;
    }

    return 'Request failed (${response.statusCode}).';
  }
}
