import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santerra/app.dart';
import 'package:santerra/audio/sound_manager.dart';
import 'package:santerra/game/score_manager.dart';
import 'package:santerra/game/settings_manager.dart';
import 'package:santerra/l10n/locale_manager.dart';
import 'package:santerra/theme/theme_manager.dart';
import 'package:santerra/util/asset_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<
    ({
      SoundManager sound,
      ScoreManager score,
      LocaleManager locale,
    })> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Locale deviceLocale = const Locale('ja'),
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await AssetGuard.load();
  final store = await SharedPreferences.getInstance();
  final theme = ThemeManager(store);
  final sound = SoundManager(store, enableAudio: false);
  await sound.init();
  final score = ScoreManager(store);
  await score.load();
  final settings = SettingsManager(store);
  final locale = LocaleManager(store, deviceLocale: deviceLocale);
  await tester.pumpWidget(
    SanTerraApp(
      themeManager: theme,
      sound: sound,
      score: score,
      settings: settings,
      localeManager: locale,
    ),
  );
  await tester.pump();
  return (sound: sound, score: score, locale: locale);
}

void main() {
  testWidgets('title screen shows start and theme controls', (tester) async {
    final boot = await _pumpApp(tester);

    expect(find.text('SanTerra'), findsNWidgets(2));
    expect(find.text('START'), findsOneWidget);
    expect(find.text('NORMAL'), findsOneWidget);
    expect(find.text('INFINITY'), findsOneWidget);
    expect(find.text('室内・アトリエ'), findsOneWidget);
    expect(find.text('夜空・砂漠'), findsOneWidget);
    expect(find.text('BGM'), findsOneWidget);
    expect(find.byTooltip('SETTINGS'), findsOneWidget);

    await boot.sound.disposePlayers();
  });

  testWidgets('first launch follows OS language', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final ja = LocaleManager(prefs, deviceLocale: const Locale('ja', 'JP'));
    expect(ja.language, AppLanguage.japanese);

    final en = LocaleManager(prefs, deviceLocale: const Locale('en', 'US'));
    expect(en.language, AppLanguage.english);

    final fr = LocaleManager(prefs, deviceLocale: const Locale('fr'));
    expect(fr.language, AppLanguage.english);
  });

  testWidgets('settings language switch updates theme names', (tester) async {
    final boot = await _pumpApp(tester);

    await tester.tap(find.byTooltip('SETTINGS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('言語'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(boot.locale.language, AppLanguage.english);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Colors'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Indoor Atelier'), findsOneWidget);
    expect(find.text('Night Desert'), findsOneWidget);
    expect(find.text('Sand Physics Puzzle'), findsNWidgets(2));

    await boot.sound.disposePlayers();
  });

  testWidgets('selected language is restored on next launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AssetGuard.load();
    final prefs = await SharedPreferences.getInstance();
    final first = LocaleManager(prefs);
    await first.setLanguage(AppLanguage.english);
    expect(prefs.getString('santerra_language'), 'en');

    final restored = LocaleManager(prefs);
    expect(restored.language, AppLanguage.english);

    final sound = SoundManager(prefs, enableAudio: false);
    await sound.init();
    final score = ScoreManager(prefs);
    await score.load();

    await tester.pumpWidget(
      SanTerraApp(
        themeManager: ThemeManager(prefs),
        sound: sound,
        score: score,
        settings: SettingsManager(prefs),
        localeManager: restored,
      ),
    );
    await tester.pump();
    expect(find.text('Sand Physics Puzzle'), findsNWidgets(2));
    await sound.disposePlayers();
  });

  testWidgets('START opens the playfield without notifying during build', (tester) async {
    final boot = await _pumpApp(tester);
    boot.score.current = 12;

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(boot.score.current, 0);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('START').hitTestable(), findsNothing);

    await boot.sound.disposePlayers();
  });

  testWidgets('system back during play opens the pause overlay', (tester) async {
    final boot = await _pumpApp(tester);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();

    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.text('START').hitTestable(), findsNothing);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('START').hitTestable(), findsNothing);

    await boot.sound.disposePlayers();
  });

  testWidgets('backgrounding a run pauses play and stays paused on resume', (tester) async {
    final boot = await _pumpApp(tester);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text('PAUSE'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('START').hitTestable(), findsNothing);

    await boot.sound.disposePlayers();
  });
}
