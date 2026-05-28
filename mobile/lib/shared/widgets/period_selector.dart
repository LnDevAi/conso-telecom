import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum PeriodOption {
  jour('Jour'),
  semaine('Semaine'),
  mois('Mois'),
  cycle('Cycle');

  const PeriodOption(this.label);
  final String label;
}

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final PeriodOption selected;
  final ValueChanged<PeriodOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PeriodOption>(
        segments: PeriodOption.values
            .map(
              (option) => ButtonSegment<PeriodOption>(
                value: option,
                label: Text(option.label),
              ),
            )
            .toList(),
        selected: {selected},
        onSelectionChanged: (newSelection) {
          if (newSelection.isNotEmpty) {
            onChanged(newSelection.first);
          }
        },
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primary;
            }
            return Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppTheme.textSecondary;
          }),
        ),
      ),
    );
  }
}
