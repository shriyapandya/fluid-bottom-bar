import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// The colors used to paint the liquid indicator while a tab is selected.
///
/// The blob is filled with a four-layer radial gradient
/// ([fillCore] → [fillMiddle] → [fillOuter] → [fillEdge]) and outlined with a
/// three-stop gradient ([strokeStart] → [strokeMiddle] → [strokeEnd]).
/// [fillOuter] and [fillEdge] also tint the bar surface around the blob.
@immutable
class FluidPalette {
  /// Creates a palette.
  const FluidPalette({
    required this.fillCore,
    required this.fillMiddle,
    required this.fillOuter,
    required this.fillEdge,
    required this.strokeStart,
    required this.strokeMiddle,
    required this.strokeEnd,
  });

  /// The brightest, innermost fill color.
  final Color fillCore;

  /// The fill color between the core and the outer layer.
  final Color fillMiddle;

  /// The fill color near the blob's edge; also used for the surface glow.
  final Color fillOuter;

  /// The outermost fill color; also used for the blob's soft halo.
  final Color fillEdge;

  /// The outline color at the start (left) of the blob.
  final Color strokeStart;

  /// The outline color at the middle of the blob.
  final Color strokeMiddle;

  /// The outline color at the end (right) of the blob.
  final Color strokeEnd;

  /// Linearly interpolates between two palettes, used while the blob travels
  /// between tabs so their colors blend into each other.
  static FluidPalette lerp(FluidPalette a, FluidPalette b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return FluidPalette(
      fillCore: c(a.fillCore, b.fillCore),
      fillMiddle: c(a.fillMiddle, b.fillMiddle),
      fillOuter: c(a.fillOuter, b.fillOuter),
      fillEdge: c(a.fillEdge, b.fillEdge),
      strokeStart: c(a.strokeStart, b.strokeStart),
      strokeMiddle: c(a.strokeMiddle, b.strokeMiddle),
      strokeEnd: c(a.strokeEnd, b.strokeEnd),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FluidPalette &&
      other.fillCore == fillCore &&
      other.fillMiddle == fillMiddle &&
      other.fillOuter == fillOuter &&
      other.fillEdge == fillEdge &&
      other.strokeStart == strokeStart &&
      other.strokeMiddle == strokeMiddle &&
      other.strokeEnd == strokeEnd;

  @override
  int get hashCode => Object.hash(fillCore, fillMiddle, fillOuter, fillEdge,
      strokeStart, strokeMiddle, strokeEnd);
}

/// Ready-made palettes.
abstract final class FluidPalettes {
  /// Teal to indigo.
  static const FluidPalette aurora = FluidPalette(
    fillCore: Color(0xFF9DFBE0),
    fillMiddle: Color(0xFF34D8C0),
    fillOuter: Color(0xFF1FA2FF),
    fillEdge: Color(0xFF3A47D5),
    strokeStart: Color(0xFFB5FFF0),
    strokeMiddle: Color(0xFF5EE7DF),
    strokeEnd: Color(0xFF4C6FFF),
  );

  /// Pink to violet.
  static const FluidPalette orchid = FluidPalette(
    fillCore: Color(0xFFF9C4FF),
    fillMiddle: Color(0xFFD66BFF),
    fillOuter: Color(0xFF9B4DFF),
    fillEdge: Color(0xFF5B2EFF),
    strokeStart: Color(0xFFFFD6FF),
    strokeMiddle: Color(0xFFE08BFF),
    strokeEnd: Color(0xFF7B5CFF),
  );

  /// Peach to rose.
  static const FluidPalette sunset = FluidPalette(
    fillCore: Color(0xFFFFE29A),
    fillMiddle: Color(0xFFFFA96B),
    fillOuter: Color(0xFFFF6B6B),
    fillEdge: Color(0xFFD6456E),
    strokeStart: Color(0xFFFFF1C1),
    strokeMiddle: Color(0xFFFFB88A),
    strokeEnd: Color(0xFFFF5E7E),
  );

  /// Gold to deep red.
  static const FluidPalette ember = FluidPalette(
    fillCore: Color(0xFFFFD166),
    fillMiddle: Color(0xFFFF8C42),
    fillOuter: Color(0xFFF2542D),
    fillEdge: Color(0xFFA4161A),
    strokeStart: Color(0xFFFFE8A3),
    strokeMiddle: Color(0xFFFF9F5A),
    strokeEnd: Color(0xFFE23E1F),
  );

  /// All built-in palettes, in declaration order.
  static const List<FluidPalette> all = [aurora, orchid, sunset, ember];
}
