import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/settings_manager.dart';
import '../l10n/app_strings_scope.dart';
import '../l10n/locale_manager.dart';
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
    final locale = context.watch<LocaleManager>();
    final s = context.strings;

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
                        s.settings,
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
                        title: s.languageTitle,
                        subtitle: s.languageSubtitle,
                        child: Row(
                          children: [
                            Expanded(
                              child: _LanguageChip(
                                theme: theme,
                                label: s.languageJapanese,
                                selected: locale.language == AppLanguage.japanese,
                                onTap: () async {
                                  await locale.setLanguage(AppLanguage.japanese);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _LanguageChip(
                                theme: theme,
                                label: s.languageEnglish,
                                selected: locale.language == AppLanguage.english,
                                onTap: () async {
                                  await locale.setLanguage(AppLanguage.english);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SettingsCard(
                        theme: theme,
                        title: s.colorCountTitle,
                        subtitle: s.colorCountSubtitle,
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
                        title: s.sandSizeTitle,
                        subtitle: s.sandSizeSubtitle,
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
                        title: s.earthquakeTitle,
                        subtitle: s.earthquakeSubtitle,
                        child: _ToggleRow(
                          theme: theme,
                          value: settings.earthquake,
                          onLabel: s.on,
                          offLabel: s.off,
                          onChanged: settings.setEarthquake,
                        ),
                      ),
                      _SettingsCard(
                        theme: theme,
                        title: s.sandwormTitle,
                        subtitle: s.sandwormSubtitle,
                        child: _ToggleRow(
                          theme: theme,
                          value: settings.sandworm,
                          onLabel: s.on,
                          offLabel: s.off,
                          onChanged: settings.setSandworm,
                        ),
                      ),
                      _SettingsCard(
                        theme: theme,
                        title: s.sparkleTitle,
                        subtitle: s.sparkleSubtitle,
                        child: _ToggleRow(
                          theme: theme,
                          value: settings.sparkle,
                          onLabel: s.on,
                          offLabel: s.off,
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

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final GameThemeConfig theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.uiPanel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.frameAccent : theme.uiPanelBorder,
              width: selected ? 2.2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: theme.uiText,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
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
    required this.onLabel,
    required this.offLabel,
  });

  final GameThemeConfig theme;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String onLabel;
  final String offLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value ? onLabel : offLabel,
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
