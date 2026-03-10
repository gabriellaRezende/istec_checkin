import 'package:flutter/material.dart';

enum AdminSection {
  dashboard,
  events,
  requests,
}

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
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
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
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
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
          foregroundColor: selected
              ? colorScheme.onPrimaryContainer
              : colorScheme.primary,
          backgroundColor:
              selected ? colorScheme.primaryContainer : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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