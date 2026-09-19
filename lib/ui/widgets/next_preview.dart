import 'package:flutter/material.dart';

import '../../models/sand_model.dart';
import '../../theme/game_theme_config.dart';

class NextPreview extends StatelessWidget {
  const NextPreview({super.key, required this.piece, required this.theme});

  final SandModel piece;
  final GameThemeConfig theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 72,
      decoration: BoxDecoration(
        color: theme.uiPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.uiPanelBorder, width: 1.4),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'NEXT',
              style: TextStyle(
                color: theme.uiMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _NextBlobPainter(piece),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              piece.amount.label,
              style: TextStyle(
                color: theme.uiText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextBlobPainter extends CustomPainter {
  _NextBlobPainter(this.piece);

  final SandModel piece;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = piece.kind.color;
    final cx = size.width / 2;
    final cy = size.height / 2 + 2;
    final scale = 1.6 * piece.amount.previewScale;
    for (final offset in piece.offsets.take(80)) {
      canvas.drawCircle(
        Offset(cx + offset.x * scale, cy + offset.y * scale),
        1.35,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NextBlobPainter oldDelegate) {
    return oldDelegate.piece != piece;
  }
}
