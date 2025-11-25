import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animations/animations.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const MainScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context),
            Expanded(
              child: PageTransitionSwitcher(
                transitionBuilder: (
                  Widget child,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) {
                  return FadeThroughTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  );
                },
                child: widget.body,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('StingCalc'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      drawer: Drawer(child: _buildSidebar(context, isDrawer: true)),
      body: PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: widget.body,
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: isDrawer ? null : 280,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDrawer)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.calculator,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'StingCalc',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16), // Drawer header spacing

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSectionHeader('CALCULATE'),
                _buildNavItem(
                  icon: FontAwesomeIcons.moneyBillWave,
                  label: 'Payment',
                  index: 0,
                  isDrawer: isDrawer,
                ),
                _buildNavItem(
                  icon: FontAwesomeIcons.coins,
                  label: 'Amount',
                  index: 1,
                  isDrawer: isDrawer,
                ),
                _buildNavItem(
                  icon: FontAwesomeIcons.percent,
                  label: 'Rate',
                  index: 2,
                  isDrawer: isDrawer,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('DEAL MODULES'),
                _buildNavItem(
                  icon: FontAwesomeIcons.wallet,
                  label: 'Income Calc',
                  index: 3,
                  isDrawer: isDrawer,
                ),
                _buildNavItem(
                  icon: FontAwesomeIcons.pencil,
                  label: 'Quick Pencil',
                  index: 4,
                  isDrawer: isDrawer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDrawer,
  }) {
    final isSelected = widget.selectedIndex == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            widget.onDestinationSelected(index);
            if (isDrawer) {
              Navigator.of(context).pop(); // Close drawer on mobile
            }
          },
          hoverColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Container(
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color:
                      isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        isSelected
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
