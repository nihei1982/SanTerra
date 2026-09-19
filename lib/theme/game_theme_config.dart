import 'package:flutter/material.dart';

enum GameThemeId { atelier, resort }

/// Swap-friendly visual + audio paths for one world skin.
class GameThemeConfig {
  const GameThemeConfig({
    required this.id,
    required this.displayName,
    required this.tagline,
    required this.worldGradient,
    required this.canvasColor,
    required this.canvasGradient,
    required this.frameOuter,
    required this.frameInner,
    required this.frameAccent,
    required this.uiPanel,
    required this.uiPanelBorder,
    required this.uiText,
    required this.uiMuted,
    required this.buttonFill,
    required this.buttonText,
    required this.paperLine,
    required this.woodGrain,
    this.canvasImageAsset,
    this.frameImageAsset,
    this.worldImageAsset,
    required this.bgmAsset,
    required this.seSandDrop,
    required this.seSandSlide,
    required this.seClear,
    required this.seChain,
  });

  final GameThemeId id;
  final String displayName;
  final String tagline;

  final List<Color> worldGradient;
  final Color canvasColor;
  final List<Color> canvasGradient;
  final Color frameOuter;
  final Color frameInner;
  final Color frameAccent;
  final Color uiPanel;
  final Color uiPanelBorder;
  final Color uiText;
  final Color uiMuted;
  final Color buttonFill;
  final Color buttonText;
  final Color paperLine;
  final Color woodGrain;

  /// Optional image replacements. Null / missing files fall back to colors.
  final String? canvasImageAsset;
  final String? frameImageAsset;
  final String? worldImageAsset;

  final String bgmAsset;
  final String seSandDrop;
  final String seSandSlide;
  final String seClear;
  final String seChain;

  static const atelier = GameThemeConfig(
    id: GameThemeId.atelier,
    displayName: '室内・アトリエ',
    tagline: '水彩紙と砂時計',
    worldGradient: [
      Color(0xFF2C1B12),
      Color(0xFF5A3824),
      Color(0xFF8A5A32),
      Color(0xFF6B4226),
    ],
    canvasColor: Color(0xFFF7F5EC),
    canvasGradient: [
      Color(0xFFFBF9F2),
      Color(0xFFF7F5EC),
      Color(0xFFEFE8D6),
    ],
    frameOuter: Color(0xFF3E2723),
    frameInner: Color(0xFFD7CCC8),
    frameAccent: Color(0xFFC9A227),
    uiPanel: Color(0xE6EFEBE9),
    uiPanelBorder: Color(0xFF8D6E63),
    uiText: Color(0xFF3E2723),
    uiMuted: Color(0xFF6D4C41),
    buttonFill: Color(0xFF5D4037),
    buttonText: Color(0xFFFFF8E1),
    paperLine: Color(0x66C9C0A8),
    woodGrain: Color(0x3321120A),
    canvasImageAsset: 'assets/images/atelier/canvas.png',
    frameImageAsset: 'assets/images/atelier/frame.png',
    worldImageAsset: 'assets/images/atelier/world.png',
    bgmAsset: 'assets/audio/atelier/bgm.wav',
    seSandDrop: 'assets/audio/se_sand_drop.wav',
    seSandSlide: 'assets/audio/se_sand_slide.wav',
    seClear: 'assets/audio/se_clear.wav',
    seChain: 'assets/audio/se_chain.wav',
  );

  static const resort = GameThemeConfig(
    id: GameThemeId.resort,
    displayName: '南国・リゾート',
    tagline: 'サンドアートの波際',
    worldGradient: [
      Color(0xFF013A63),
      Color(0xFF0277BD),
      Color(0xFF00ACC1),
      Color(0xFF26C6DA),
    ],
    canvasColor: Color(0xFFE8F6F3),
    canvasGradient: [
      Color(0xFF7EE8D8),
      Color(0xFFC9EDE0),
      Color(0xFFF3E2C2),
    ],
    frameOuter: Color(0xFF6D4C41),
    frameInner: Color(0xFFBCAAA4),
    frameAccent: Color(0xFFFF8A80),
    uiPanel: Color(0xE6E0F7FA),
    uiPanelBorder: Color(0xFF00838F),
    uiText: Color(0xFF004D40),
    uiMuted: Color(0xFF00695C),
    buttonFill: Color(0xFF00695C),
    buttonText: Color(0xFFE0F2F1),
    paperLine: Color(0x55FFFFFF),
    woodGrain: Color(0x22004D40),
    canvasImageAsset: 'assets/images/resort/canvas.png',
    frameImageAsset: 'assets/images/resort/frame.png',
    worldImageAsset: 'assets/images/resort/world.png',
    bgmAsset: 'assets/audio/resort/bgm.wav',
    seSandDrop: 'assets/audio/se_sand_drop.wav',
    seSandSlide: 'assets/audio/se_sand_slide.wav',
    seClear: 'assets/audio/se_clear.wav',
    seChain: 'assets/audio/se_chain.wav',
  );

  static GameThemeConfig of(GameThemeId id) {
    return switch (id) {
      GameThemeId.atelier => atelier,
      GameThemeId.resort => resort,
    };
  }
}
