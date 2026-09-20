import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santerra/app.dart';
import 'package:santerra/audio/sound_manager.dart';
import 'package:santerra/game/score_manager.dart';
import 'package:santerra/game/settings_manager.dart';
import 'package:santerra/theme/theme_manager.dart';
import 'package:santerra/util/asset_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('title screen shows start and theme controls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AssetGuard.load();
    final prefs = await SharedPreferences.getInstance();
    final theme = ThemeManager(prefs);
    final sound = SoundManager(prefs, enableAudio: false);
    await sound.init();
    final score = ScoreManager(prefs);
    await score.load();
    final settings = SettingsManager(prefs);

    await tester.pumpWidget(
      SanTerraApp(
        themeManager: theme,
        sound: sound,
        score: score,
        settings: settings,
      ),
    );
    await tester.pump();

    expect(find.text('SanTerra'), findsNWidgets(2));
    expect(find.text('START'), findsOneWidget);
    expect(find.text('NORMAL'), findsOneWidget);
    expect(find.text('INFINITY'), findsOneWidget);
    expect(find.text('室内・アトリエ'), findsOneWidget);
    expect(find.text('夜空・砂漠'), findsOneWidget);
    expect(find.text('BGM'), findsOneWidget);
    expect(find.byTooltip('SETTINGS'), findsOneWidget);

    await sound.disposePlayers();
  });

  testWidgets('START opens the playfield without notifying during build', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AssetGuard.load();
    final prefs = await SharedPreferences.getInstance();
    final theme = ThemeManager(prefs);
    final sound = SoundManager(prefs, enableAudio: false);
    await sound.init();
    final score = ScoreManager(prefs);
    await score.load();
    score.current = 12;
    final settings = SettingsManager(prefs);

    await tester.pumpWidget(
      SanTerraApp(
        themeManager: theme,
        sound: sound,
        score: score,
        settings: settings,
      ),
    );
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(score.current, 0);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('START').hitTestable(), findsNothing);

    await sound.disposePlayers();
  });

  testWidgets('system back during play opens the pause overlay', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AssetGuard.load();
    final prefs = await SharedPreferences.getInstance();
    final theme = ThemeManager(prefs);
    final sound = SoundManager(prefs, enableAudio: false);
    await sound.init();
    final score = ScoreManager(prefs);
    await score.load();
    final settings = SettingsManager(prefs);

    await tester.pumpWidget(
      SanTerraApp(
        themeManager: theme,
        sound: sound,
        score: score,
        settings: settings,
      ),
    );
    await tester.pump();
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

    await sound.disposePlayers();
  });

  testWidgets('backgrounding a run pauses play and stays paused on resume', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AssetGuard.load();
    final prefs = await SharedPreferences.getInstance();
    final theme = ThemeManager(prefs);
    final sound = SoundManager(prefs, enableAudio: false);
    await sound.init();
    final score = ScoreManager(prefs);
    await score.load();
    final settings = SettingsManager(prefs);

    await tester.pumpWidget(
      SanTerraApp(
        themeManager: theme,
        sound: sound,
        score: score,
        settings: settings,
      ),
    );
    await tester.pump();
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

    await sound.disposePlayers();
  });
}
