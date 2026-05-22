import 'package:flutter/material.dart';

OverlayEntry? _currentToast;

void showToast(BuildContext context, String message, {Color? backgroundColor}) {
  _currentToast?.remove();
  if (!context.mounted) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  _currentToast = OverlayEntry(
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: _ToastWidget(
        message: message,
        backgroundColor: backgroundColor ?? (isDark ? Colors.grey[800]! : Colors.white),
      ),
    ),
  );

  overlay.insert(_currentToast!);
  Future.delayed(const Duration(seconds: 3), () {
    _currentToast?.remove();
    _currentToast = null;
  });
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  const _ToastWidget({required this.message, required this.backgroundColor});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87;
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: widget.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[400], size: 20),
                  const SizedBox(width: 10),
                  Flexible(child: Text(widget.message, style: TextStyle(color: textColor, fontSize: 14))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
