import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_admin/pages/splash.dart';
import 'configs/app_config.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lms_admin/l10n/app_localizations.dart';
import 'package:lms_admin/providers/locale_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      home: const SplashScreen(),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      scrollBehavior: TouchAndMouseScrollBehavior(),
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Poppins',
        primaryColor: AppConfig.themeColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
      ],
    );
  }
}

class TouchAndMouseScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse};
}
