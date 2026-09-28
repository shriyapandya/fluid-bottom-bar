import 'package:flutter/material.dart';
import 'package:fluid_bottom_bar/fluid_bottom_bar.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluid Bottom Bar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const DemoHome(),
    );
  }
}

class _Tab {
  const _Tab(this.title, this.icon, this.selectedIcon, this.palette);

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final FluidPalette palette;
}

const _tabs = [
  _Tab('Home', Icons.home_outlined, Icons.home_rounded, FluidPalettes.aurora),
  _Tab('Explore', Icons.explore_outlined, Icons.explore_rounded,
      FluidPalettes.orchid),
  _Tab('Favorites', Icons.favorite_outline_rounded, Icons.favorite_rounded,
      FluidPalettes.sunset),
  _Tab('Profile', Icons.person_outline_rounded, Icons.person_rounded,
      FluidPalettes.ember),
];

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_selected];
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tab.palette.fillMiddle.withValues(alpha: dark ? 0.25 : 0.18),
              dark ? const Color(0xFF0B0C10) : const Color(0xFFF4F5F9),
            ],
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Column(
              key: ValueKey(_selected),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.selectedIcon, size: 72, color: tab.palette.fillOuter),
                const SizedBox(height: 12),
                Text(tab.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Tap a tab, or press and drag the blob.'),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: FluidBottomBar(
          selectedIndex: _selected,
          onItemSelected: (i) => setState(() => _selected = i),
          items: [
            for (final t in _tabs)
              FluidBarItem(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.title,
                palette: t.palette,
              ),
          ],
        ),
      ),
    );
  }
}
