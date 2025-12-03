// MyApp.dart (Se mantiene la estructura que me proporcionaste)
import 'package:provider/provider.dart';
import 'package:toko/providers/locale_provider.dart';
import 'package:toko/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:toko/screens/Toko/Entities/global_banner_ad.dart'; // Importación correcta
import 'package:toko/screens/WelcomeScreen.dart';
import 'package:toko/services/remote_config_service.dart';

import 'l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final remoteConfigService = RemoteConfigService.instance;
    // final bool showBannerAd = remoteConfigService.getBool('show_banner_ad');
    final bool showBannerAd = true;

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

              locale: localeProvider.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,

              home: const WelcomeScreen(),

              builder: (context, navigator) {
                return Column(
                  children: [
                    Expanded(child: navigator!),

                    // 📌 Usando el widget GlobalBannerAdWidget que ahora existe
                    if (showBannerAd)
                      const GlobalBannerAdWidget(),
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
