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
    tagline: '朝日が差し込む部屋',
    worldGradient: [
      Color(0xFFC5DCE8),
      Color(0xFFB7D4E6),
      Color(0xFFD7E8F2),
      Color(0xFFE8F2F8),
    ],
    canvasColor: Color(0xFFFFF8EE),
    canvasGradient: [
      Color(0xFFFFFDF8),
      Color(0xFFFFF6E8),
      Color(0xFFF3E6D0),
    ],
    frameOuter: Color(0xFFD9C4A4),
    frameInner: Color(0xFFF7F1E6),
    frameAccent: Color(0xFF7BA7C9),
    uiPanel: Color(0xE6FFF8F0),
    uiPanelBorder: Color(0xFFC4B49A),
    uiText: Color(0xFF4A3F36),
    uiMuted: Color(0xFF7A6A5A),
    buttonFill: Color(0xFF6A9BB8),
    buttonText: Color(0xFFFFFDF8),
    paperLine: Color(0x44C9D6E0),
    woodGrain: Color(0x33C4A882),
    canvasImageAsset: 'assets/images/atelier/canvas.png',
    frameImageAsset: 'assets/images/atelier/frame.png',
    worldImageAsset: null,
    bgmAsset: 'assets/audio/atelier/bgm.wav',
    seSandDrop: 'assets/audio/se_sand_drop.wav',
    seSandSlide: 'assets/audio/se_sand_slide.wav',
    seClear: 'assets/audio/se_clear.wav',
    seChain: 'assets/audio/se_chain.wav',
  );

  static const resort = GameThemeConfig(
    id: GameThemeId.resort,
    displayName: '夜空・砂漠',
    tagline: '満月と星の砂丘',
    worldGradient: [
      Color(0xFF06102E),
      Color(0xFF0C1E52),
      Color(0xFF163A78),
      Color(0xFFC9842E),
    ],
    canvasColor: Color(0xFF241C14),
    canvasGradient: [
      Color(0xFF1A2438),
      Color(0xFF2A2218),
      Color(0xFF3A2A18),
    ],
    frameOuter: Color(0xFF2A1C0E),
    frameInner: Color(0xFF8B6914),
    frameAccent: Color(0xFFE8D48A),
    uiPanel: Color(0xE6182238),
    uiPanelBorder: Color(0xFF8B6914),
    uiText: Color(0xFFF5E6C8),
    uiMuted: Color(0xFFC4B08A),
    buttonFill: Color(0xFF1E3A5F),
    buttonText: Color(0xFFFFF4D6),
    paperLine: Color(0x33E8D48A),
    woodGrain: Color(0x22000000),
    canvasImageAsset: 'assets/images/resort/canvas.png',
    frameImageAsset: 'assets/images/resort/frame.png',
    worldImageAsset: null,
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
