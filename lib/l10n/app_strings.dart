import '../game/game_mode.dart';
import '../theme/game_theme_config.dart';
import 'locale_manager.dart';

/// Lightweight JA/EN string table for SanTerra UI.
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isJa => language == AppLanguage.japanese;

  String get tagline => isJa ? '砂の物理パズル' : 'Sand Physics Puzzle';

  String get settings => 'SETTINGS';
  String get start => 'START';
  String get mode => 'MODE';
  String get theme => 'THEME';
  String get bgm => 'BGM';
  String get se => 'SE';
  String get score => 'SCORE';
  String get highScore => 'HIGH SCORE';
  String get hi => 'HI';
  String get depth => 'DEPTH';
  String get next => 'NEXT';
  String get pause => 'PAUSE';
  String get resume => 'RESUME';
  String get restart => 'RESTART';
  String get title => 'TITLE';
  String get retry => 'RETRY';
  String get gameOver => 'GAME OVER';
  String get quake => 'QUAKE';
  String get worm => 'WORM';
  String get on => 'ON';
  String get off => 'OFF';

  String get languageTitle => isJa ? '言語' : 'Language';
  String get languageSubtitle =>
      isJa ? '表示言語を切り替えます' : 'Switch the display language';
  String get languageJapanese => '日本語';
  String get languageEnglish => 'English';

  String get colorCountTitle => isJa ? '色数' : 'Colors';
  String get colorCountSubtitle =>
      isJa ? '3〜8色。デフォルトは4色' : '3–8 colors. Default is 4';

  String get sandSizeTitle => isJa ? '砂サイズ' : 'Sand size';
  String get sandSizeSubtitle => isJa
      ? '1〜4種類。少ないほど小さいサイズだけ'
      : '1–4 sizes. Fewer means only smaller sand';

  String get earthquakeTitle => isJa ? '地震' : 'Earthquake';
  String get earthquakeSubtitle => isJa
      ? 'ONで10回落とすたびに山が平らになる'
      : 'When ON, flattens the pile every 10 drops';

  String get sandwormTitle => isJa ? 'サンドワーム' : 'Sandworm';
  String get sandwormSubtitle => isJa
      ? 'ONで20回落とすたびに砂壺をかき回す'
      : 'When ON, stirs the pot every 20 drops';

  String get sparkleTitle => isJa ? '砂のキラキラ' : 'Sand sparkle';
  String get sparkleSubtitle => isJa
      ? 'OFFで砂粒を単色表示にする'
      : 'When OFF, sand grains are solid color';

  String modeDescription(GameMode mode) => switch (mode) {
        GameMode.normal =>
          isJa ? '上限到達でゲームオーバー' : 'Game over when sand hits the top',
        GameMode.infinity => isJa
            ? '壺が深くなり続け、スクロール可'
            : 'The pot deepens forever; scroll to explore',
      };

  String themeName(GameThemeId id) => switch (id) {
        GameThemeId.atelier => isJa ? '室内・アトリエ' : 'Indoor Atelier',
        GameThemeId.resort => isJa ? '夜空・砂漠' : 'Night Desert',
      };

  String themeTagline(GameThemeId id) => switch (id) {
        GameThemeId.atelier =>
          isJa ? '朝日が差し込む部屋' : 'A sunlit morning room',
        GameThemeId.resort => isJa ? '満月と星の砂丘' : 'Moonlit dunes and stars',
      };

  String highScoreLine(String modeLabel, int score) =>
      '$modeLabel  $highScore  $score';

  String hiLine(int score) => '$hi  $score';

  String depthLine(int extra) => '$depth +$extra';

  String highScoreOnly(int score) => '$highScore  $score';
}
