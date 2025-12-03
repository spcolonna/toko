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
import 'my_app.dart';

// 📌 TUS IDS GLOBALES
const String globalAdMobAppId = 'ca-app-pub-9552343552775183~1356877916';
const String bannerAdUnitId = 'ca-app-pub-9552343552775183/8528790922';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📌 DIAGNOSTICO: Imprimir el ID de la App
  print('AdMob App ID (Global): $globalAdMobAppId');

  // 📌 CONFIGURACIÓN DE DISPOSITIVOS DE PRUEBA (Para ver anuncios de prueba fiables)
  // Revisa la documentación de Google Ads para obtener tu ID de dispositivo.
  // RequestConfiguration configuration = RequestConfiguration(
  //   testDeviceIds: ['YOUR_DEVICE_ID_HERE_FOR_TESTING'],
  // );
  // MobileAds.instance.updateRequestConfiguration(configuration);

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
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
