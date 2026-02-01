import 'package:flutter/material.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/billing_records/billing_records_screen.dart';
import '../../features/import_excel/import_excel_screen.dart';
import '../../features/anomalies/anomaly_statistics_screen.dart';
import '../../features/cek_dlpd/cek_dlpd_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    BillingRecordsScreen(),
    ImportExcelScreen(),
    AnomalyStatisticsScreen(),
    CekDlpdScreen(),
    SettingsScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(
      label: 'Dashboard',
      shortLabel: 'Dash',
      icon: Icons.dashboard_rounded,
    ),
    _NavItem(
      label: 'Data Pelanggan',
      shortLabel: 'Data',
      icon: Icons.people_alt_rounded,
    ),
    _NavItem(
      label: 'Import',
      shortLabel: 'Import',
      icon: Icons.upload_file_rounded,
    ),
    _NavItem(
      label: 'Anomali',
      shortLabel: 'Anomali',
      icon: Icons.warning_amber_rounded,
    ),
    _NavItem(
      label: 'Cek DLPD',
      shortLabel: 'DLPD',
      icon: Icons.assessment_rounded,
    ),
    _NavItem(
      label: 'Pengaturan',
      shortLabel: 'Setting',
      icon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isExtended = constraints.maxWidth >= 1100;
        final railWidth = isExtended ? 260.0 : 72.0;

        return Scaffold(
          body: Row(
            children: [
              Container(
                width: railWidth,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _AppBranding(isExtended: isExtended),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isExtended ? 12 : 8,
                          ),
                          children: List.generate(_items.length, (index) {
                            return _NavTile(
                              item: _items[index],
                              isSelected: _selectedIndex == index,
                              isExtended: isExtended,
                              onTap: () {
                                setState(() => _selectedIndex = index);
                              },
                            );
                          }),
                        ),
                      ),
                      if (isExtended)
                        Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'PLN Billing AMR\nv1.0.0 Desktop',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: theme.colorScheme.surfaceContainerLowest,
                  child: IndexedStack(index: _selectedIndex, children: _pages),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppBranding extends StatelessWidget {
  final bool isExtended;

  const _AppBranding({required this.isExtended});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isExtended ? 16 : 16,
        20,
        isExtended ? 16 : 16,
        12,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: isExtended
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isExtended ? 40 : 36,
            height: isExtended ? 40 : 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          ),
          if (isExtended) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PLN Billing AMR',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Monitoring Pelanggan',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool isExtended;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isExtended ? 16 : 12,
                vertical: isExtended ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isExtended
                  ? Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      item.icon,
                      size: 24,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String shortLabel;
  final IconData icon;

  const _NavItem({
    required this.label,
    required this.shortLabel,
    required this.icon,
  });
}
