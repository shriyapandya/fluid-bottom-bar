import 'package:flutter/material.dart';

/// Surface and icon colors of a FluidBottomBar.
@immutable
class FluidBottomBarColors {
  /// Creates a color set.
  const FluidBottomBarColors({
    required this.surface,
    required this.border,
    required this.shadow,
    required this.selectedIcon,
    required this.unselectedIcon,
  });

  /// The bar's background color.
  final Color surface;

  /// The hairline around the bar.
  final Color border;

  /// The drop shadow under the bar.
  final Color shadow;

  /// The icon color of the selected tab (drawn on top of the blob).
  final Color selectedIcon;

  /// The icon color of the other tabs.
  final Color unselectedIcon;

  /// Default colors for light themes.
  static const FluidBottomBarColors light = FluidBottomBarColors(
    surface: Color(0xFFFFFFFF),
    border: Color(0x14000000),
    shadow: Color(0x33101828),
    selectedIcon: Color(0xFFFFFFFF),
    unselectedIcon: Color(0xFF8A90A2),
  );

  /// Default colors for dark themes.
  static const FluidBottomBarColors dark = FluidBottomBarColors(
    surface: Color(0xFF16181F),
    border: Color(0x1FFFFFFF),
    shadow: Color(0x80000000),
    selectedIcon: Color(0xFFFFFFFF),
    unselectedIcon: Color(0xFF7C8294),
  );

  /// The default colors for the ambient [Theme]'s brightness.
  static FluidBottomBarColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// Returns a copy with the given fields replaced.
  FluidBottomBarColors copyWith({
    Color? surface,
    Color? border,
    Color? shadow,
    Color? selectedIcon,
    Color? unselectedIcon,
  }) {
    return FluidBottomBarColors(
      surface: surface ?? this.surface,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      unselectedIcon: unselectedIcon ?? this.unselectedIcon,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FluidBottomBarColors &&
      other.surface == surface &&
      other.border == border &&
      other.shadow == shadow &&
      other.selectedIcon == selectedIcon &&
      other.unselectedIcon == unselectedIcon;

  @override
  int get hashCode =>
      Object.hash(surface, border, shadow, selectedIcon, unselectedIcon);
}
