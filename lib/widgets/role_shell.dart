import 'package:flutter/material.dart';

/// Lets dashboard cards jump to another tab in the same [RoleShell].
class ShellTabs extends InheritedWidget {
  const ShellTabs({
    super.key,
    required this.index,
    required this.onSelect,
    required super.child,
  });

  final int index;
  final ValueChanged<int> onSelect;

  static ShellTabs? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellTabs>();
  }

  @override
  bool updateShouldNotify(ShellTabs oldWidget) => index != oldWidget.index;
}

/// One tab inside a [RoleShell] bottom navigation bar.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// Phone-first navigation shell: a Material 3 [NavigationBar] with an
/// [IndexedStack] body so each tab keeps its own scroll position and state
/// when the user switches between them.
///
/// Both the parent and the child role use this shell with their own set of
/// [destinations].
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.destinations, this.accent});

  final List<ShellDestination> destinations;

  /// Optional role colour used to tint the selected-tab indicator.
  final Color? accent;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = widget.accent ?? theme.colorScheme.primary;

    // On Android the hardware back button should return to the first tab
    // instead of leaving the app straight away.
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: ShellTabs(
        index: _selectedIndex,
        onSelect: _onDestinationSelected,
        child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            for (final ShellDestination destination in widget.destinations)
              destination.builder(context),
          ],
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: theme.navigationBarTheme.copyWith(
            indicatorColor: accent.withValues(alpha: 0.16),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: <Widget>[
              for (final ShellDestination destination in widget.destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon, color: accent),
                  label: destination.label,
                  tooltip: destination.label,
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
