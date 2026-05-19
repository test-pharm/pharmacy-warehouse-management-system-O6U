import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:graduation_project/Models/ProductProvider.dart';
import 'package:graduation_project/Models/UserRoleModel.dart';
import 'package:graduation_project/Models/app_localizations.dart';
import 'package:graduation_project/views/LoginView.dart';
import 'package:graduation_project/widgets/UpdateDialog.dart';

const String backgroundImagePath =
    'assets/Gemini_Generated_Image_4jaq2t4jaq2t4jaq.png';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  await initLanguage();
  runApp(const PharmacyLoginApp());
}

class PharmacyLoginApp extends StatelessWidget {
  const PharmacyLoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return ValueListenableBuilder<AppLanguage>(
          valueListenable: languageNotifier,
          builder: (context, lang, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: themeMode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              // ✅ الإصلاح الأساسي
              locale: lang == AppLanguage.ar
                  ? const Locale('ar')
                  : const Locale('en'),
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: UpdateCheckScope(child: ProductProviderScope(child: const Loginview())),
            );
          },
        );
      },
    );
  }
}