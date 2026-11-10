import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bottom_nav_bar.dart';

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final Widget navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
