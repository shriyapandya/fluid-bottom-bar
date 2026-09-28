import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'fluid_bar_item.dart';
import 'fluid_bottom_bar_colors.dart';
import 'fluid_painter.dart';
import 'fluid_palette.dart';
import 'spring.dart';

/// A bottom navigation bar whose selection indicator is a liquid blob.
///
/// The blob glides between tabs with spring physics, stretching and wobbling
/// as it moves, and blends the [FluidBarItem.palette] of neighbouring tabs.
/// Users can tap a tab, or press and drag the blob and release it over the
/// tab they want.
///
/// This is a controlled widget: it reports taps and drags through
/// [onItemSelected] and animates when [selectedIndex] changes.
class FluidBottomBar extends StatefulWidget {
  /// Creates a fluid bottom bar.
  const FluidBottomBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.colors,
    this.height = 72,
    this.horizontalPadding = 8,
    this.verticalInset = 10,
    this.borderRadius,
    this.iconSize = 26,
    this.enableDrag = true,
    this.enableHaptics = true,
  })  : assert(items.length > 0, 'FluidBottomBar needs at least one item'),
        assert(selectedIndex >= 0 && selectedIndex < items.length);

  /// The tabs, from left to right.
  final List<FluidBarItem> items;

  /// The index of the selected tab.
  final int selectedIndex;

  /// Called with the tab index the user tapped or dropped the blob on.
  final ValueChanged<int> onItemSelected;

  /// Surface and icon colors. Defaults to [FluidBottomBarColors.of].
  final FluidBottomBarColors? colors;

  /// The height of the bar.
  final double height;

  /// Space between the bar's edge and the outermost tabs.
  final double horizontalPadding;

  /// Space between the bar's top / bottom edge and the blob.
  final double verticalInset;

  /// Corner radius of the bar; defaults to a full pill.
  final double? borderRadius;

  /// The size of the tab icons.
  final double iconSize;

  /// Whether the blob can be dragged between tabs.
  final bool enableDrag;

  /// Whether to emit a selection click when the blob crosses a tab.
  final bool enableHaptics;

  @override
  State<FluidBottomBar> createState() => _FluidBottomBarState();
}

class _FluidBottomBarState extends State<FluidBottomBar>
    with SingleTickerProviderStateMixin {
  // Leading end: snappy, a little bouncy.
  static const double _headStiffness = 340;
  static const double _headDamping = 0.62;
  // Leading end while following a finger: tight, no overshoot.
  static const double _dragStiffness = 2200;
  static const double _dragDamping = 1;
  // Trailing end: softer, so it lags and then wobbles into place.
  static const double _tailStiffness = 150;
  static const double _tailDamping = 0.55;

  static const double _pressedScale = 1.08;
  static const double _stepSeconds = 1 / 240;

  late final FluidSpring _head;
  late final FluidSpring _tail;
  final FluidSpring _press = FluidSpring(1, stiffness: 600, dampingRatio: 0.5);

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  bool _dragging = false;
  int _lastHapticIndex = 0;

  @override
  void initState() {
    super.initState();
    final start = widget.selectedIndex.toDouble();
    _head = FluidSpring(start,
        stiffness: _headStiffness, dampingRatio: _headDamping);
    _tail = FluidSpring(start,
        stiffness: _tailStiffness, dampingRatio: _tailDamping);
    _lastHapticIndex = widget.selectedIndex;
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(FluidBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final last = widget.items.length - 1;
    if (widget.selectedIndex != oldWidget.selectedIndex && !_dragging) {
      _moveTo(widget.selectedIndex);
    } else if (_head.target > last || _tail.target > last) {
      _moveTo(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _moveTo(int index) {
    _head
      ..stiffness = _headStiffness
      ..dampingRatio = _headDamping
      ..target = index.toDouble();
    _tail.target = index.toDouble();
    _start();
  }

  void _start() {
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    var dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    dt = dt.clamp(0.0, 1 / 30);

    // The tail chases the head, not the final target, which is what makes
    // the blob stretch while travelling.
    while (dt > 0) {
      final h = math.min(dt, _stepSeconds);
      _tail.target = _dragging ? _head.value : _head.target;
      _head.step(h);
      _tail.step(h);
      _press.step(h);
      dt -= h;
    }

    if (_dragging && widget.enableHaptics) {
      final nearest = _nearestIndex(_head.value);
      if (nearest != _lastHapticIndex) {
        _lastHapticIndex = nearest;
        HapticFeedback.selectionClick();
      }
    }

    if (!_dragging && _head.isAtRest && _tail.isAtRest && _press.isAtRest) {
      _head.snap();
      _tail.snap();
      _press.snap();
      _ticker.stop();
    }
    setState(() {});
  }

  int _nearestIndex(double position) =>
      position.round().clamp(0, widget.items.length - 1);

  double _tabWidth(double width) =>
      (width - 2 * widget.horizontalPadding) / widget.items.length;

  double _positionFor(double dx, double width) =>
      (dx - widget.horizontalPadding) / _tabWidth(width) - 0.5;

  /// Resists dragging past the first / last tab.
  double _rubberBand(double p) {
    const limit = 0.35;
    final last = (widget.items.length - 1).toDouble();
    if (p < 0) return -limit * (1 - math.exp(p / limit));
    if (p > last) return last + limit * (1 - math.exp(-(p - last) / limit));
    return p;
  }

  void _handleTap(TapUpDetails details, double width) {
    final raw = _positionFor(details.localPosition.dx, width);
    final index = _nearestIndex(raw);
    if (index != widget.selectedIndex) widget.onItemSelected(index);
  }

  void _handleDragStart(DragStartDetails details, double width) {
    _dragging = true;
    _lastHapticIndex = _nearestIndex(_head.value);
    _head
      ..stiffness = _dragStiffness
      ..dampingRatio = _dragDamping
      ..target = _rubberBand(_positionFor(details.localPosition.dx, width));
    _press.target = _pressedScale;
    _start();
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    _head.target = _rubberBand(_positionFor(details.localPosition.dx, width));
  }

  void _handleDragEnd(DragEndDetails details, double width) {
    _dragging = false;
    // Project the fling a little so a flick carries the blob onward.
    final velocity = details.velocity.pixelsPerSecond.dx / _tabWidth(width);
    final index = _nearestIndex(_head.value + velocity * 0.12);
    _head.velocity = velocity.clamp(-40.0, 40.0);
    _press.target = 1;
    _moveTo(index);
    if (index != widget.selectedIndex) widget.onItemSelected(index);
  }

  void _handleDragCancel() {
    _dragging = false;
    _press.target = 1;
    _moveTo(widget.selectedIndex);
  }

  FluidPalette _paletteAt(double position) {
    final items = widget.items;
    final p = position.clamp(0.0, items.length - 1.0);
    final i = p.floor();
    if (i >= items.length - 1) return items.last.palette;
    return FluidPalette.lerp(items[i].palette, items[i + 1].palette, p - i);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? FluidBottomBarColors.of(context);
    final radius = widget.borderRadius ?? widget.height / 2;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _handleTap(d, width),
          onHorizontalDragStart:
              widget.enableDrag ? (d) => _handleDragStart(d, width) : null,
          onHorizontalDragUpdate:
              widget.enableDrag ? (d) => _handleDragUpdate(d, width) : null,
          onHorizontalDragEnd:
              widget.enableDrag ? (d) => _handleDragEnd(d, width) : null,
          onHorizontalDragCancel: widget.enableDrag ? _handleDragCancel : null,
          child: CustomPaint(
            painter: FluidBarPainter(
              itemCount: widget.items.length,
              head: _head.value,
              tail: _tail.value,
              press: _press.value,
              palette: _paletteAt(_head.value),
              colors: colors,
              horizontalPadding: widget.horizontalPadding,
              verticalInset: widget.verticalInset,
              borderRadius: radius,
            ),
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
              child: Row(
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    Expanded(child: _buildItem(i, colors)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildItem(int index, FluidBottomBarColors colors) {
    final item = widget.items[index];
    final selected = index == widget.selectedIndex;
    // How much of the blob (anywhere between tail and head) sits under this
    // tab.
    final lo = math.min(_head.value, _tail.value);
    final hi = math.max(_head.value, _tail.value);
    final distance = index < lo ? lo - index : (index > hi ? index - hi : 0);
    final coverage = (1 - distance * 1.4).clamp(0.0, 1.0).toDouble();
    final t = Curves.easeOut.transform(coverage);

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: item.label,
      onTap: () {
        if (!selected) widget.onItemSelected(index);
      },
      child: ExcludeSemantics(
        child: Center(
          child: Transform.translate(
            offset: Offset(0, -1.5 * t),
            child: Transform.scale(
              scale: 1 + 0.1 * t,
              child: IconTheme.merge(
                data: IconThemeData(
                  size: widget.iconSize,
                  color:
                      Color.lerp(colors.unselectedIcon, colors.selectedIcon, t),
                ),
                child: selected ? (item.selectedIcon ?? item.icon) : item.icon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
