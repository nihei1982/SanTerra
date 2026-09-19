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

    expect(find.text('SanTerra'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
    expect(find.text('NORMAL'), findsOneWidget);
    expect(find.text('INFINITY'), findsOneWidget);
    expect(find.text('室内・アトリエ'), findsOneWidget);
    expect(find.text('南国・リゾート'), findsOneWidget);
    expect(find.text('BGM'), findsOneWidget);
    expect(find.byTooltip('SETTINGS'), findsOneWidget);

    await sound.disposePlayers();
  });
}
