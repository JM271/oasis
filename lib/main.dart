import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_style.dart';
import 'authentication.dart';
import 'oasis_home.dart';
import 'firebase_options.dart';
import 'firebase_startup.dart';
import 'language.dart';
import 'texts.dart';
import 'water_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      appFontFamily,
    ], await rootBundle.loadString('assets/fonts/licenses/Saira-OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      appDisplayFontFamily,
    ], await rootBundle.loadString('assets/fonts/licenses/Michroma-OFL.txt'));
  });
  // Texts for anything shown before MaterialApp picks the locale.
  await loadAppLanguage();
  tr = lookupAppLocalizations(
    appLanguage.value ??
        basicLocaleListResolution(
          WidgetsBinding.instance.platformDispatcher.locales,
          appLocales,
        ),
  );
  try {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(OasisApp(auth: FirebaseAuth.instanceFor(app: app)));
  } on FirebaseException catch (error, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
    runApp(
      FirebaseStartupError(
        error: error,
        onRetry: main,
        preview: const OasisApp(),
      ),
    );
  }
}

class OasisApp extends StatelessWidget {
  const OasisApp({super.key, this.repository, this.auth});
  final FirebaseAuth? auth;
  final WaterRepository? repository;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: appLanguage,
    builder: (context, language, _) => _app(language),
  );

  Widget _app(Locale? language) => MaterialApp(
    title: 'Oasis',
    debugShowCheckedModeBanner: false,
    theme: waterTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: appLocales,
    locale: language,
    builder: (context, child) {
      tr = AppLocalizations.of(context);
      // Rebuilds every screen with the new texts when the language changes.
      return KeyedSubtree(key: ValueKey(tr.localeName), child: child!);
    },
    home: auth == null
        ? OasisHome(repository: repository)
        : AuthenticationGate(
            auth: auth!,
            builder: (repository) =>
                OasisHome(repository: repository, auth: auth),
          ),
  );
}
