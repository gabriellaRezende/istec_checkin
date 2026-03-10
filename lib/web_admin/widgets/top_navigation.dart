import 'package:flutter/material.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';

enum AdminSection { dashboard, events, requests }

class TopNavigation extends StatelessWidget implements PreferredSizeWidget {
  final AdminSection currentSection;
  final VoidCallback onDashboard;
  final VoidCallback onEvents;
  final VoidCallback onRequests;
  final VoidCallback onSignOut;
  final String title;

  const TopNavigation({
    super.key,
    required this.currentSection,
    required this.onDashboard,
    required this.onEvents,
    required this.onRequests,
    required this.onSignOut,
    this.title = 'ISTEC Admin',
  });

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 88,
      title: Text(title),
      flexibleSpace: Container(decoration: BrandTheme.screenBackground()),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: BrandTheme.line),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Row(
            children: [
              _TopNavItem(
                label: 'Dashboard',
                selected: currentSection == AdminSection.dashboard,
                onPressed: onDashboard,
              ),
              _TopNavItem(
                label: 'Eventos',
                selected: currentSection == AdminSection.events,
                onPressed: onEvents,
              ),
              _TopNavItem(
                label: 'Solicitações',
                selected: currentSection == AdminSection.requests,
                onPressed: onRequests,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _TopNavItem({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: selected ? Colors.white : colorScheme.primary,
          backgroundColor: selected
              ? BrandTheme.navy
              : Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected ? BrandTheme.navy : BrandTheme.line,
            ),
          ),
          textStyle: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
