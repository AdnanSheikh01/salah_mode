import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:salah_mode/controllers/lang_change.dart';
import 'package:salah_mode/firebase_options.dart';
import 'package:salah_mode/l10n/app_localizations.dart';
import 'package:salah_mode/screens/auth/splash.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LangChangeController()),
      ],
      child: Consumer<LangChangeController>(
        builder: (context, value, child) {
          return GetMaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            title: 'Salah Mode',
            locale: value.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('es'),
              Locale('hi'),
              Locale('ur'),
              Locale('id'),
              Locale('tr'),
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}


// 3 full page pura bacha hai
// dusra check krna hai ki agar verse 1 hai aur agar 2 verse bole to bhi valid dikha rha hai check karnahai dono screen me