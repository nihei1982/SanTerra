import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import 'painters/field_painter.dart';

/// Touch surface: drag to aim, release to drop, wheel/scrollbar to pan Infinity depth.
class GameCanvasWidget extends StatelessWidget {
  const GameCanvasWidget({
    super.key,
    required this.controller,
    required this.cancelThresholdGlobalY,
    this.canvasImage,
  });

  final GameController controller;
  final double cancelThresholdGlobalY;
  final ui.Image? canvasImage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final cellH = size.height / controller.visibleRows;
        return Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent && controller.canScroll) {
                  controller.scrollByCells(event.scrollDelta.dy / cellH);
                }
              },
              onPointerDown: (event) {
                if (!controller.acceptsInput) {
                  return;
                }
                controller.beginAim(
                  event.localPosition,
                  size,
                  inCancelZone: event.position.dy <= cancelThresholdGlobalY,
                );
              },
              onPointerMove: (event) {
                controller.updateAim(
                  event.localPosition,
                  size,
                  inCancelZone: event.position.dy <= cancelThresholdGlobalY,
                );
              },
              onPointerUp: (_) => controller.releaseAim(),
              onPointerCancel: (_) => controller.cancelAim(),
              child: CustomPaint(
                size: size,
                painter: FieldPainter(
                  controller: controller,
                  canvasImage: canvasImage,
                ),
              ),
            ),
            if (controller.canScroll)
              Align(
                alignment: Alignment.centerRight,
                child: _DepthScrollBar(
                  value: controller.maxScrollY == 0
                      ? 0
                      : controller.scrollY / controller.maxScrollY,
                  onChanged: (t) => controller.setScrollY(t * controller.maxScrollY),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DepthScrollBar extends StatelessWidget {
  const _DepthScrollBar({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || box.size.height <= 0) {
          return;
        }
        final local = box.globalToLocal(details.globalPosition);
        onChanged((local.dy / box.size.height).clamp(0.0, 1.0));
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || box.size.height <= 0) {
          return;
        }
        onChanged((details.localPosition.dy / box.size.height).clamp(0.0, 1.0));
      },
      child: SizedBox(
        width: 22,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackH = constraints.maxHeight;
              final thumbH = (trackH * 0.22).clamp(28.0, 72.0);
              final top = (trackH - thumbH) * value.clamp(0.0, 1.0);
              return Stack(
                children: [
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Positioned(
                    top: top,
                    child: Container(
                      width: 8,
                      height: thumbH,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
