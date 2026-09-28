import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluid_bottom_bar/fluid_bottom_bar.dart';

const _items = [
  FluidBarItem(
      icon: Icon(Icons.home_rounded),
      label: 'Home',
      palette: FluidPalettes.aurora),
  FluidBarItem(
      icon: Icon(Icons.search_rounded),
      label: 'Search',
      palette: FluidPalettes.orchid),
  FluidBarItem(
      icon: Icon(Icons.favorite_rounded),
      label: 'Favorites',
      palette: FluidPalettes.sunset),
  FluidBarItem(
      icon: Icon(Icons.person_rounded),
      label: 'Profile',
      palette: FluidPalettes.ember),
];

Widget _harness(ValueNotifier<int> selected, {bool enableDrag = true}) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: selected,
        builder: (context, index, _) => FluidBottomBar(
          items: _items,
          selectedIndex: index,
          enableDrag: enableDrag,
          enableHaptics: false,
          onItemSelected: (i) => selected.value = i,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('tapping a tab selects it and the animation settles',
      (tester) async {
    final selected = ValueNotifier(0);
    await tester.pumpWidget(_harness(selected));

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pump(const Duration(milliseconds: 50));
    expect(selected.value, 2);

    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('dragging the blob selects the tab it is dropped on',
      (tester) async {
    final selected = ValueNotifier(0);
    await tester.pumpWidget(_harness(selected));

    final from = tester.getCenter(find.byIcon(Icons.home_rounded));
    final to = tester.getCenter(find.byIcon(Icons.person_rounded));
    final gesture = await tester.startGesture(from);
    for (var i = 1; i <= 20; i++) {
      await gesture.moveTo(Offset.lerp(from, to, i / 20)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Hold still before releasing so there is no fling.
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected.value, 3);
  });

  testWidgets('dragging is ignored when disabled', (tester) async {
    final selected = ValueNotifier(1);
    await tester.pumpWidget(_harness(selected, enableDrag: false));

    await tester.drag(find.byIcon(Icons.search_rounded), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(selected.value, 1);
  });

  testWidgets('exposes tabs to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    final selected = ValueNotifier(1);
    await tester.pumpWidget(_harness(selected));

    expect(
      tester.getSemantics(find.bySemanticsLabel('Search')),
      matchesSemantics(
        label: 'Search',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  test('palette lerp hits both ends', () {
    const a = FluidPalettes.aurora;
    const b = FluidPalettes.ember;
    expect(FluidPalette.lerp(a, b, 0), a);
    expect(FluidPalette.lerp(a, b, 1), b);
  });
}
