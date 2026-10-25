import 'package:flutter/material.dart';
import 'core/api.dart';
import 'core/local_tls.dart';
import 'core/preferences.dart';
import 'core/theme.dart';
import 'features/auth/login.dart';
import 'features/workspace/presentation/workspace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureLocalTls();
  final api = Api();
  await api.init();
  final preferences = AppPreferences();
  await preferences.load();
  final session = Session(api);
  await session.restore();
  runApp(GmApp(session, preferences: preferences));
}

class GmApp extends StatelessWidget {
  final Session session;
  final AppPreferences preferences;
  GmApp(this.session, {super.key, AppPreferences? preferences})
    : preferences = preferences ?? AppPreferences();
  @override
  Widget build(BuildContext context) => PreferencesScope(
    preferences: preferences,
    child: ListenableBuilder(
      listenable: preferences,
      builder: (c, _) => MaterialApp(
        title: 'G&M Campo',
        debugShowCheckedModeBanner: false,
        theme: gmTheme(seed: preferences.seed),
        darkTheme: gmTheme(brightness: Brightness.dark, seed: preferences.seed),
        themeMode: preferences.mode,
        themeAnimationDuration: Duration(
          milliseconds: preferences.reduceMotion ? 0 : 220,
        ),
        themeAnimationCurve: gmEase,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(
            disableAnimations:
                preferences.reduceMotion || MediaQuery.disableAnimationsOf(c),
          ),
          child: child!,
        ),
        home: ListenableBuilder(
          listenable: session,
          builder: (c, _) => session.user == null
              ? LoginPage(session)
              : Workspace(
                  session,
                  key: ValueKey('${session.demo}:${session.user?['email']}'),
                ),
        ),
      ),
    ),
  );
}
