import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'fluid_bottom_bar_colors.dart';
import 'fluid_palette.dart';

/// Paints the bar surface and the liquid blob.
///
/// The blob has two ends that are driven by separate springs: [head] leads
/// the motion and [tail] trails behind it. The distance between them stretches
/// the blob into a capsule with a pinched waist, and its thickness shrinks so
/// the "volume" stays roughly constant. When the tail overshoots and catches
/// up, the blob wobbles.
class FluidBarPainter extends CustomPainter {
  /// Creates the painter. Positions are in tab-index units.
  FluidBarPainter({
    required this.itemCount,
    required this.head,
    required this.tail,
    required this.press,
    required this.palette,
    required this.colors,
    required this.horizontalPadding,
    required this.verticalInset,
    required this.borderRadius,
  });

  /// Number of tabs.
  final int itemCount;

  /// Position of the leading end of the blob.
  final double head;

  /// Position of the trailing end of the blob.
  final double tail;

  /// Press scale; 1 when idle, larger while the user holds the blob.
  final double press;

  /// The blended palette at the blob's current position.
  final FluidPalette palette;

  /// Surface colors.
  final FluidBottomBarColors colors;

  /// Horizontal space between the bar edge and the first / last tab.
  final double horizontalPadding;

  /// Vertical space between the bar edge and the blob.
  final double verticalInset;

  /// Corner radius of the bar.
  final double borderRadius;

  /// Keeps overshoot past the first / last tab small so the blob squashes
  /// against the bar's end instead of sliding out of view.
  double _contain(double p) {
    const limit = 0.1;
    final last = itemCount - 1.0;
    if (p < 0) return -limit * (1 - math.exp(p / limit));
    if (p > last) return last + limit * (1 - math.exp(-(p - last) / limit));
    return p;
  }

  /// Converts a tab-index position into an x coordinate.
  static double xFor(double position, double width, int count, double pad) {
    final tabWidth = (width - 2 * pad) / count;
    return pad + tabWidth * (position + 0.5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barRect = Offset.zero & size;
    final barRRect =
        RRect.fromRectAndRadius(barRect, Radius.circular(borderRadius));

    // Surface + shadow.
    canvas.drawRRect(
      barRRect.shift(const Offset(0, 6)),
      Paint()
        ..color = colors.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawRRect(barRRect, Paint()..color = colors.surface);

    canvas.save();
    canvas.clipRRect(barRRect);

    final blob = _blobPath(size);
    final bounds = blob.path.getBounds();
    final center = bounds.center;

    // Palette spreading across the surface.
    final spreadRadius = size.width * 0.55;
    canvas.drawRect(
      barRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.fillOuter.withValues(alpha: 0.28),
            palette.fillEdge.withValues(alpha: 0.10),
            palette.fillEdge.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: center, radius: spreadRadius)),
    );

    // Soft halo.
    canvas.drawPath(
      blob.path,
      Paint()
        ..color = palette.fillEdge.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // Four-layer liquid fill, brightest near the leading end.
    final coreCenter = Offset(
      xFor(_contain(head), size.width, itemCount, horizontalPadding),
      center.dy - blob.radius * 0.35,
    );
    final fillRadius = math.max(bounds.width, bounds.height) * 0.8;
    canvas.drawPath(
      blob.path,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.fillCore,
            palette.fillMiddle,
            palette.fillOuter,
            palette.fillEdge,
          ],
          stops: const [0, 0.35, 0.75, 1],
        ).createShader(Rect.fromCircle(center: coreCenter, radius: fillRadius)),
    );

    // Glossy highlight along the top.
    canvas.save();
    canvas.clipPath(blob.path);
    final highlight = Rect.fromCenter(
      center: Offset(center.dx, bounds.top + blob.radius * 0.45),
      width: bounds.width * 0.72,
      height: blob.radius * 0.8,
    );
    canvas.drawOval(
      highlight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFFFFF).withValues(alpha: 0.45),
            const Color(0xFFFFFFFF).withValues(alpha: 0),
          ],
        ).createShader(highlight),
    );
    canvas.restore();

    // Gradient outline.
    canvas.drawPath(
      blob.path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = LinearGradient(
          colors: [
            palette.strokeStart,
            palette.strokeMiddle,
            palette.strokeEnd,
          ],
        ).createShader(bounds),
    );

    canvas.restore();

    // Hairline border.
    canvas.drawRRect(
      barRRect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colors.border,
    );
  }

  ({Path path, double radius}) _blobPath(Size size) {
    final pad = horizontalPadding;
    final tabWidth = (size.width - 2 * pad) / itemCount;
    final cy = size.height / 2;

    final hx = xFor(_contain(head), size.width, itemCount, pad);
    final tx = xFor(_contain(tail), size.width, itemCount, pad);
    final stretch = (hx - tx).abs();

    final height = size.height - 2 * verticalInset;
    final halfWidth = math.min(tabWidth / 2 - 4, height * 0.8) * press;
    final baseRadius = math.min(height / 2 * press, halfWidth);

    // Preserve volume: the longer the blob, the thinner it gets.
    final baseLength = 2 * halfWidth;
    final thin =
        math.sqrt(baseLength / (baseLength + stretch)).clamp(0.62, 1.0);
    final headRadius = baseRadius * thin;
    final tailRadius =
        baseRadius * thin * (1 - 0.3 * (stretch / tabWidth).clamp(0.0, 1.0));

    final headIsRight = hx >= tx;
    final leftX = math.min(hx, tx) - halfWidth;
    final rightX = math.max(hx, tx) + halfWidth;
    final leftR = headIsRight ? tailRadius : headRadius;
    final rightR = headIsRight ? headRadius : tailRadius;
    final cl = leftX + leftR;
    final cr = math.max(cl, rightX - rightR);
    final span = cr - cl;

    // Waist pinch grows with stretch.
    final minR = math.min(leftR, rightR);
    final pinch = math.min(stretch * 0.16, minR * 0.38);
    final waist = (leftR + rightR) / 2 - pinch;

    final path = Path()
      ..moveTo(cl, cy - leftR)
      ..cubicTo(cl + span * 0.35, cy - waist, cr - span * 0.35, cy - waist, cr,
          cy - rightR)
      ..arcToPoint(Offset(cr, cy + rightR), radius: Radius.circular(rightR))
      ..cubicTo(cr - span * 0.35, cy + waist, cl + span * 0.35, cy + waist, cl,
          cy + leftR)
      ..arcToPoint(Offset(cl, cy - leftR), radius: Radius.circular(leftR))
      ..close();
    return (path: path, radius: math.max(leftR, rightR));
  }

  @override
  bool shouldRepaint(FluidBarPainter old) =>
      old.head != head ||
      old.tail != tail ||
      old.press != press ||
      old.palette != palette ||
      old.colors != colors ||
      old.itemCount != itemCount ||
      old.horizontalPadding != horizontalPadding ||
      old.verticalInset != verticalInset ||
      old.borderRadius != borderRadius;
}
