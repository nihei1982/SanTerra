import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/settings_manager.dart';
import '../models/sand_kind.dart';
import '../theme/game_theme_config.dart';
import '../theme/theme_manager.dart';
import 'painters/frame_painter.dart';

class SettingsScene extends StatelessWidget {
  const SettingsScene({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeManager>().config;
    final settings = context.watch<SettingsManager>();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          WorldBackdrop(theme: theme),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        color: theme.uiText,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Text(
                        'SETTINGS',
                        style: TextStyle(
                          color: theme.uiText,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _SettingsCard(
                        theme: theme,
                        title: '色数',
                        subtitle: '3〜8色。デフォルトは4色',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StepperRow(
                              theme: theme,
                              value: '${settings.colorCount}',
                              onMinus: settings.colorCount > SettingsManager.minColorCount
                                  ? () => settings.setColorCount(settings.colorCount - 1)
                                  : null,
                              onPlus: settings.colorCount < SettingsManager.maxColorCount
                                  ? () => settings.setColorCount(settings.colorCount + 1)
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final kind in SandKind.palette(settings.colorCount))
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: kind.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _SettingsCard(
                        theme: theme,
                        title: '砂サイズ',
                        subtitle: '1〜4種類。少ないほど小さいサイズだけ',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StepperRow(
                              theme: theme,
                              value: '${settings.sizeTypes}',
                              onMinus: settings.sizeTypes > SettingsManager.minSizeTypes
                                  ? () => settings.setSizeTypes(settings.sizeTypes - 1)
                                  : null,
                              onPlus: settings.sizeTypes < SettingsManager.maxSizeTypes
                                  ? () => settings.setSizeTypes(settings.sizeTypes + 1)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              settings.sizeSummary,
                              style: TextStyle(
                                color: theme.uiText,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingsCard(
                        theme: theme,
                        title: '地震',
                        subtitle: 'ONで10回落とすたびに山が平らになる',
                        child: _ToggleRow(
                          theme: theme,
                          value: settings.earthquake,
                          onChanged: settings.setEarthquake,
                        ),
                      ),
                      _SettingsCard(
                        theme: theme,
                        title: 'サンドワーム',
                        subtitle: 'ONで20回落とすたびに砂壺をかき回す',
                        child: _ToggleRow(
                          theme: theme,
                          value: settings.sandworm,
                          onChanged: settings.setSandworm,
                        ),
                      ),
                      _SettingsCard(
                        theme: theme,
                        title: '砂のキラキラ',
                        subtitle: 'OFFで砂粒を単色表示にする',
                        child: _ToggleRow(
                          theme: theme,
                          value: settings.sparkle,
                          onChanged: settings.setSparkle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.theme,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final GameThemeConfig theme;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: theme.uiPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.uiPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.uiText,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: theme.uiMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.theme,
    required this.value,
    required this.onChanged,
  });

  final GameThemeConfig theme;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value ? 'ON' : 'OFF',
          style: TextStyle(
            color: theme.uiText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.all(theme.frameAccent),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.theme,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final GameThemeConfig theme;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIcon(icon: Icons.remove, enabled: onMinus != null, theme: theme, onTap: onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            value,
            style: TextStyle(
              color: theme.uiText,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _RoundIcon(icon: Icons.add, enabled: onPlus != null, theme: theme, onTap: onPlus),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.enabled,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final GameThemeConfig theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: enabled ? onTap : null,
      style: IconButton.styleFrom(
        backgroundColor: theme.buttonFill,
        foregroundColor: theme.buttonText,
        disabledBackgroundColor: theme.buttonFill.withValues(alpha: 0.35),
      ),
      icon: Icon(icon),
    );
  }
}
