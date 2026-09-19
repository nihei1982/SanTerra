import 'package:flutter/material.dart';

import '../../theme/game_theme_config.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.theme,
    required this.onResume,
    required this.onRestart,
    required this.onTitle,
    this.onSettings,
  });

  final GameThemeConfig theme;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onTitle;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return _DialogCard(
      theme: theme,
      title: 'PAUSE',
      children: [
        _DialogButton(theme: theme, label: 'RESUME', onTap: onResume),
        _DialogButton(theme: theme, label: 'RESTART', onTap: onRestart),
        if (onSettings != null)
          _DialogButton(theme: theme, label: 'SETTINGS', onTap: onSettings!),
        _DialogButton(theme: theme, label: 'TITLE', outlined: true, onTap: onTitle),
      ],
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.theme,
    required this.score,
    required this.highScore,
    required this.onRetry,
    required this.onTitle,
  });

  final GameThemeConfig theme;
  final int score;
  final int highScore;
  final VoidCallback onRetry;
  final VoidCallback onTitle;

  @override
  Widget build(BuildContext context) {
    return _DialogCard(
      theme: theme,
      title: 'GAME OVER',
      children: [
        Text(
          'SCORE',
          style: TextStyle(color: theme.uiMuted, letterSpacing: 2, fontSize: 12),
        ),
        Text(
          '$score',
          style: TextStyle(
            color: theme.uiText,
            fontSize: 36,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'HIGH SCORE  $highScore',
          style: TextStyle(
            color: theme.uiMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 18),
        _DialogButton(theme: theme, label: 'RETRY', onTap: onRetry),
        _DialogButton(theme: theme, label: 'TITLE', outlined: true, onTap: onTitle),
      ],
    );
  }
}

class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.theme,
    required this.title,
    required this.children,
  });

  final GameThemeConfig theme;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Material(
            color: theme.uiPanel,
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.uiText,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.theme,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final GameThemeConfig theme;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: outlined
            ? OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.uiText,
                  side: BorderSide(color: theme.uiPanelBorder, width: 1.4),
                ),
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              )
            : FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.buttonFill,
                  foregroundColor: theme.buttonText,
                ),
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
      ),
    );
  }
}
