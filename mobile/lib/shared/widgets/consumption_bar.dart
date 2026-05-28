import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ConsumptionBar extends StatelessWidget {
  const ConsumptionBar({
    super.key,
    required this.title,
    required this.used,
    required this.total,
    required this.usedLabel,
    required this.remainingLabel,
    this.unit = 'Mo',
    this.subtitle,
  });

  final String title;
  final double used;
  final double total;
  final String usedLabel;
  final String remainingLabel;
  final String unit;
  final String? subtitle;

  double get _ratio => total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
  double get _remainingRatio => 1.0 - _ratio;

  Color get _barColor => AppTheme.progressColor(_remainingRatio);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  usedLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _barColor,
                  ),
                ),
                Text(
                  'Reste: $remainingLabel',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _ratio,
            minHeight: 8,
            backgroundColor: const Color(0xFFe5e7eb),
            valueColor: AlwaysStoppedAnimation<Color>(_barColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_ratio * 100).toStringAsFixed(0)}% utilisé',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${(_remainingRatio * 100).toStringAsFixed(0)}% restant',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _barColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
