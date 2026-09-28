import 'package:flutter/widgets.dart';

import 'fluid_palette.dart';

/// A single destination in a FluidBottomBar.
@immutable
class FluidBarItem {
  /// Creates a bar item.
  const FluidBarItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.palette = FluidPalettes.aurora,
  });

  /// The icon shown for this tab. It is tinted through [IconTheme], so an
  /// [Icon] picks up the selected / unselected colors automatically.
  final Widget icon;

  /// An optional icon shown instead of [icon] while this tab is selected.
  final Widget? selectedIcon;

  /// The label announced by screen readers.
  final String label;

  /// The colors of the liquid indicator while this tab is selected.
  final FluidPalette palette;
}
