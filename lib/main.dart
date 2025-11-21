import 'package:provider/provider.dart';
import 'package:toko/providers/locale_provider.dart';
import 'package:toko/providers/session_provider.dart';
import 'package:toko/providers/theme_provider.dart';
import 'package:toko/services/notification_service.dart';
import 'package:toko/services/remote_config_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:toko/widgets/ad_banner_widget.dart';
import 'package:toko/screens/WelcomeScreen.dart';

import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  MobileAds.instance.initialize();
  await NotificationService().initialize();
  final remoteConfigService = await RemoteConfigService.getInstance();
  await remoteConfigService.fetchAndActivate();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => SessionProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteConfigService = RemoteConfigService.instance;
    final bool showBannerAd = remoteConfigService.getBool('show_banner_ad');

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Consumer<LocaleProvider>(
          builder: (context, localeProvider, child) {
            return MaterialApp(
              title: 'Toko',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                primaryColor: themeProvider.theme.primaryColor,
                appBarTheme: AppBarTheme(
                  backgroundColor: themeProvider.theme.primaryColor,
                  foregroundColor: Colors.white,
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: themeProvider.theme.accentColor,
                ),
              ),

              // --- CAMBIO: Conectamos MaterialApp con el sistema de i18n ---
              locale: localeProvider.locale, // 1. Usa el locale del provider
              localizationsDelegates: AppLocalizations.localizationsDelegates, // 2. Usa los delegados generados
              supportedLocales: AppLocalizations.supportedLocales, // 3. Usa los locales generados

              home: const WelcomeScreen(),
              builder: (context, navigator) {
                return Column(
                  children: [
                    Expanded(child: navigator!),
                    if (showBannerAd)
                      const AdBannerWidget(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
